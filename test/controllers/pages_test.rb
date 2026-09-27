require "test_helper"

# Component tier: every page renders from the sample data, with the demo notice.
class PagesTest < ActionDispatch::IntegrationTest
  setup do
    @restaurant = Sample.restaurant("copper-fig")
    @visit = @restaurant.latest_visit
  end

  def assert_demo_page
    assert_response :success
    assert_select "[data-demo-notice]", text: /Demo data/
    assert_nil response.headers["set-cookie"], "pages set no cookie"
    assert_select "a[href='https://github.com/amcritchie/garret-app']"
  end

  test "home lists every restaurant with its latest score and links" do
    get root_path
    assert_demo_page
    Sample.restaurants.each do |restaurant|
      assert_select "[data-restaurant='#{restaurant.slug}']" do
        assert_select ".card__title", text: restaurant.name
        assert_select ".trend__bar", count: restaurant.visits.size
        assert_select "a[href=?]", action_plan_restaurant_visit_path(restaurant, restaurant.latest_visit), text: "Action Plan"
      end
    end
  end

  test "a restaurant lists its visits newest first" do
    get restaurant_path(@restaurant)
    assert_demo_page
    numbers = css_select("[data-visit]").map { |li| li["data-visit"].to_i }
    assert_equal @restaurant.visits.map(&:number).reverse, numbers
    assert_select "a[href=?]", restaurant_new_evaluation_path(@restaurant), text: "Score a visit"
  end

  test "the scorecard shows the visit details and every standard's mark" do
    get restaurant_visit_path(@restaurant, @visit)
    assert_demo_page
    assert_select ".details dd", text: @visit.check_number
    assert_select ".details dd", text: @visit.arrived
    assert_select "[data-department]", count: Sample.departments.size
    assert_select ".result", count: Sample.standards.size
    assert_select ".pill--fail", count: @visit.missed.size
    @visit.missed.each { |r| assert_select ".result__note", text: r.note }
  end

  test "the Action Plan lists each miss with its last-visit and last-six history" do
    plan = @visit.action_plan
    get action_plan_restaurant_visit_path(@restaurant, @visit)
    assert_demo_page
    assert_select "[data-missed-count]", text: @visit.missed.size.to_s
    assert_select "[data-summary]", count: Sample.departments.size
    assert_select ".plan-item", count: plan.items.size
    plan.items.each do |item|
      assert_select ".plan-item[data-standard='#{item.standard.id}']" do
        assert_select ".plan-item__standard", text: /#{Regexp.escape(item.standard.text)}/
        assert_select ".plan-item__history dd", text: ApplicationHelper::MARK_LABELS.fetch(item.last_visit.mark)
      end
    end
    assert_select "p.meta", text: /compared with visit #{@visit.number - 1} and the 6 visits/
  end

  test "a first visit's Action Plan says there is nothing to compare" do
    get action_plan_restaurant_visit_path(@restaurant, @restaurant.visit(1))
    assert_demo_page
    assert_select "p.meta", text: /this was the first visit/
    assert_select ".plan-item__history dd", text: "No visit"
    assert_select ".plan-item__history dt", text: "Earlier visits"
    assert_not_includes response.body, "Last 0"
  end

  test "the standards page lists all of them by department" do
    get standards_path
    assert_demo_page
    assert_select ".standard-list li", count: Sample.standards.size
  end

  test "the demo scorecard has a Pass/Fail/N/A choice for every standard, Pass by default" do
    get restaurant_new_evaluation_path(@restaurant)
    assert_demo_page
    assert_select "form[method=get][action=?]", restaurant_evaluation_preview_path(@restaurant)
    assert_select "input[type=radio]", count: Sample.standards.size * 3
    assert_select "input[type=radio][value=pass][checked]", count: Sample.standards.size
    assert_select "input[name=authenticity_token]", count: 0
  end

  test "submitting a scorecard shows its Action Plan against the real history, and saves nothing" do
    get restaurant_evaluation_preview_path(@restaurant), params: {
      marks: { "s4" => "fail", "h1" => "na" }, notes: { "s4" => "Allergies never came up." },
      details: { "check_number" => "5150" }
    }
    assert_demo_page
    assert_select "[data-draft-notice]", text: /Nothing was saved/
    assert_select ".plan-item", count: 1
    assert_select ".plan-item[data-standard='s4'] .plan-item__note", text: "Allergies never came up."
    assert_select ".details dd", text: "5150"
    assert_equal 8, Sample.restaurant("copper-fig").visits.size

    edit = css_select("a").find { |a| a.text == "Edit this scorecard" }["href"]
    get edit
    assert_select "input[name='marks[s4]'][value=fail][checked]"
    assert_select "input[name='marks[h1]'][value=na][checked]"
    assert_select "input[name='notes[s4]'][value=?]", "Allergies never came up."
  end

  test "unknown restaurants and visits are 404s" do
    get restaurant_path("nowhere")
    assert_response :not_found
    get restaurant_visit_path(@restaurant, 99)
    assert_response :not_found
    get action_plan_restaurant_visit_path("nowhere", 1)
    assert_response :not_found
    get restaurant_new_evaluation_path("nowhere")
    assert_response :not_found
  end

  test "health check answers" do
    get rails_health_check_path
    assert_response :success
  end
end
