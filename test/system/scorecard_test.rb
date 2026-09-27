require "application_system_test_case"

# E2E tier: a real browser walks from the restaurants to an Action Plan, fills
# in a scorecard, and every page fits a phone.
class ScorecardTest < ApplicationSystemTestCase
  test "from the restaurant list to an Action Plan and its scorecard" do
    visit root_path
    assert_selector "[data-demo-notice]", text: "Demo data"

    within "[data-restaurant='harbor-and-hearth']" do
      click_on "Action Plan"
    end
    assert_selector ".eyebrow", text: "ACTION PLAN"
    assert_selector "h1", text: "Harbor & Hearth"
    assert_selector ".plan-item", count: Sample.restaurant("harbor-and-hearth").latest_visit.missed.size

    click_on "Evaluator's scorecard"
    assert_selector ".eyebrow", text: "EVALUATOR SCORECARD"
    assert_selector ".result", count: Sample.standards.size
  end

  test "an evaluator scores a visit and sees the plan it would produce" do
    visit restaurant_new_evaluation_path("juniper-social")
    fill_in "details[check_number]", with: "7788"

    within "[data-standard='s4']" do
      find("label.mark--fail").click
      fill_in "notes[s4]", with: "Nobody asked about allergies."
    end
    within("[data-standard='b3']") { find("label.mark--na").click }
    click_on "See the Action Plan"

    assert_selector "[data-draft-notice]", text: "Nothing was saved"
    assert_selector ".plan-item", count: 1
    within(".plan-item[data-standard='s4']") { assert_text "Nobody asked about allergies." }
    assert_selector ".details dd", text: "7788"

    click_on "Edit this scorecard"
    assert find("#mark-s4-fail", visible: :all).checked?
    assert find("#mark-b3-na", visible: :all).checked?
  end

  test "a phone gets every page without sideways scroll" do
    # Headless Chrome will not shrink a window below 500 px, so emulate the
    # phone screen instead, and check the emulation took.
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 375, height: 800, deviceScaleFactor: 2, mobile: true)
    restaurant = Sample.restaurant("harbor-and-hearth")
    visit_ = restaurant.latest_visit
    [
      root_path, standards_path, restaurant_path(restaurant),
      restaurant_visit_path(restaurant, visit_), action_plan_restaurant_visit_path(restaurant, visit_),
      restaurant_new_evaluation_path(restaurant),
      restaurant_evaluation_preview_path(restaurant, marks: { s4: "fail" }, notes: { s4: "A long note " * 30 })
    ].each do |path|
      visit path
      assert_equal 375, page.evaluate_script("window.innerWidth")
      overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
      assert_equal 0, overflow, "#{path} scrolls sideways at 375 px"
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end
end
