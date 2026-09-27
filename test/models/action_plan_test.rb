require "test_helper"

# Unit tier: the Action Plan lists every miss and compares it with the visit
# before and the six before that, never with later visits.
class ActionPlanTest < ActiveSupport::TestCase
  # Eight visits a week apart. Standard s4 fails on the visits named in
  # `s4_fails`; h3 is N/A on visit 7.
  def restaurant(s4_fails: [ 1, 2, 7, 8 ])
    Restaurant.new(slug: "test-kitchen", name: "Test Kitchen", cuisine: "Test", neighborhood: "Nowhere").tap do |r|
      r.visits = (1..8).map do |n|
        missed = s4_fails.include?(n) ? { "s4" => "Not asked on visit #{n}." } : {}
        missed["h3"] = "No coat check." if n == 8
        Visit.from_h(r, "number" => n, "date" => (Date.new(2026, 1, 5) + (n - 1) * 7).iso8601,
          "observations" => {}, "missed" => missed, "na" => (n == 7 ? [ "h3" ] : []), "notes" => {})
      end
    end
  end

  test "lists each missed standard with its note" do
    plan = restaurant.visit(8).action_plan
    assert_equal %w[h3 s4], plan.items.map { |i| i.standard.id }
    assert_equal "Not asked on visit 8.", plan.items(Sample.department("server")).first.result.note
  end

  test "compares with the visit before and the six before it, not the oldest" do
    plan = restaurant.visit(8).action_plan
    assert_equal 7, plan.last_visit.number
    assert_equal (2..7).to_a, plan.last_six.map(&:number)

    s4 = plan.items.find { |i| i.standard.id == "s4" }
    assert s4.last_visit.fail?
    assert s4.repeat?
    # Visits 2..7: s4 failed on 2 and 7, passed on 3-6. Visit 1 is outside the window.
    assert_equal Score.new(passed: 4, scored: 6), s4.last_six
  end

  test "an N/A last time is not a repeat and does not count in the last six" do
    h3 = restaurant.visit(8).action_plan.items.find { |i| i.standard.id == "h3" }
    assert h3.last_visit.na?
    assert_not h3.repeat?
    assert_equal Score.new(passed: 5, scored: 5), h3.last_six
  end

  test "an earlier visit never looks at later ones" do
    plan = restaurant.visit(2).action_plan
    assert_equal [ 1 ], plan.last_six.map(&:number)
    assert_equal Score.new(passed: 0, scored: 1), plan.items.first.last_six
  end

  test "the first visit has nothing to compare with" do
    plan = restaurant.visit(1).action_plan
    assert_nil plan.last_visit
    assert_empty plan.last_six
    item = plan.items.first
    assert_nil item.last_visit
    assert_not item.repeat?
    assert_not item.last_six.any?
    assert(plan.summaries.all? { |s| s.change.nil? })
  end

  test "department summaries score this visit against the last" do
    plan = restaurant(s4_fails: [ 8 ]).visit(8).action_plan
    server = plan.summaries.find { |s| s.department.key == "server" }
    size = Sample.department("server").standards.size
    assert_equal Score.new(passed: size - 1, scored: size), server.score
    assert_equal 100, server.last_visit.percent
    assert_equal server.score.percent - 100, server.change
    assert_equal 1, server.missed
    assert_equal Score.new(passed: size * 6, scored: size * 6), server.last_six
  end

  test "a clean visit leaves an empty plan" do
    plan = restaurant.visit(4).action_plan
    assert plan.empty?
    assert_empty plan.items
  end

  test "a draft is compared with the latest visit and the six before it" do
    kitchen = restaurant
    plan = Visit.draft(kitchen, marks: { "s4" => "fail" }).action_plan
    assert_equal 8, plan.last_visit.number
    assert_equal (3..8).to_a, plan.last_six.map(&:number)
    assert plan.items.first.repeat?
  end

  test "every sample visit's plan lines up with its own misses" do
    Sample.restaurants.flat_map(&:visits).each do |visit|
      plan = visit.action_plan
      assert_equal visit.missed.size, plan.items.size
      assert_equal visit.missed.size, plan.summaries.sum(&:missed)
      assert_operator plan.last_six.size, :<=, ActionPlan::LOOKBACK
      assert(plan.previous.all? { |v| v.visited_on < visit.visited_on })
    end
  end
end
