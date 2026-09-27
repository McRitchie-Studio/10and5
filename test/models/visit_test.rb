require "test_helper"

# Unit tier: a visit's results, from the data file and from the demo form.
class VisitTest < ActiveSupport::TestCase
  setup { @restaurant = Sample.restaurant("copper-fig") }

  def raw(overrides = {})
    { "number" => 1, "date" => "2026-03-01", "observations" => {}, "missed" => {}, "na" => [], "notes" => {} }.merge(overrides)
  end

  test "every standard gets a result; unlisted ones passed" do
    visit = Visit.from_h(@restaurant, raw("missed" => { "s4" => "Not asked." }, "na" => [ "m5" ], "notes" => { "h1" => "Quick." }))
    assert_equal Sample.standards.size, visit.results.size
    assert visit.result_for(Sample.standard("s4")).fail?
    assert_equal "Not asked.", visit.result_for(Sample.standard("s4")).note
    assert visit.result_for(Sample.standard("m5")).na?
    assert visit.result_for(Sample.standard("h1")).pass?
    assert_equal "Quick.", visit.result_for(Sample.standard("h1")).note
    assert_equal [ "s4" ], visit.missed.map { |r| r.standard.id }
  end

  test "results, misses and scores narrow to one department" do
    visit = Visit.from_h(@restaurant, raw("missed" => { "s4" => "x", "h2" => "y" }))
    server = Sample.department("server")
    assert_equal server.standards.size, visit.results(server).size
    assert_equal [ "s4" ], visit.missed(server).map { |r| r.standard.id }
    assert_equal Score.new(passed: server.standards.size - 1, scored: server.standards.size), visit.score(server)
  end

  test "a draft keeps valid marks, passes the rest and ignores unknown standards" do
    visit = Visit.draft(@restaurant, marks: { "h1" => "fail", "b1" => "na", "s1" => "bogus", "zz" => "fail" },
      notes: { "h1" => "  Two minutes at the stand.  ", "zz" => "ignored" })
    assert visit.draft?
    assert visit.result_for(Sample.standard("h1")).fail?
    assert_equal "Two minutes at the stand.", visit.result_for(Sample.standard("h1")).note
    assert visit.result_for(Sample.standard("b1")).na?
    assert visit.result_for(Sample.standard("s1")).pass?
    assert_equal Sample.standards.size, visit.results.size
  end

  test "a draft clips long notes and reads the visit details" do
    visit = Visit.draft(@restaurant, notes: { "h1" => "x" * 900 },
      details: { "arrived" => "6:45 PM", "party_size" => "3", "check_amount" => "84.5", "all_items_billed" => "no" },
      observations: { "host" => "Host in a green scarf." })
    assert_equal Visit::NOTE_LIMIT, visit.result_for(Sample.standard("h1")).note.size
    assert_equal "6:45 PM", visit.arrived
    assert_equal 3, visit.party_size
    assert_in_delta 84.5, visit.check_amount
    assert_equal false, visit.all_items_billed
    assert_equal "Host in a green scarf.", visit.observation(Sample.department("host"))
    assert_nil Visit.draft(@restaurant, {}).all_items_billed
    assert_equal true, Visit.draft(@restaurant, details: { "all_items_billed" => "yes" }).all_items_billed
  end

  test "blank notes are nil, not empty strings" do
    visit = Visit.draft(@restaurant, notes: { "h1" => "   " })
    assert_nil visit.result_for(Sample.standard("h1")).note
  end
end
