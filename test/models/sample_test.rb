require "test_helper"

# Unit tier: the checked-in sample data is complete, consistent and invented.
class SampleTest < ActiveSupport::TestCase
  RAW = YAML.safe_load_file(Sample::PATH)

  test "four departments, in the order the scorecard shows them" do
    assert_equal %w[host bartender server manager], Sample.departments.map(&:key)
    assert_equal %w[Host Bartender Server Manager], Sample.departments.map(&:name)
    Sample.departments.each { |d| assert_operator d.standards.size, :>=, 4, d.name }
  end

  test "standard ids are unique and belong to their department" do
    ids = Sample.standards.map(&:id)
    assert_equal ids.uniq, ids
    Sample.standards.each { |s| assert_equal s.department_key, s.department.key }
  end

  test "three restaurants, each with enough visits to fill the last-six comparison" do
    assert_equal 3, Sample.restaurants.size
    Sample.restaurants.each do |restaurant|
      assert_operator restaurant.visits.size, :>, ActionPlan::LOOKBACK, restaurant.name
      assert_equal (1..restaurant.visits.size).to_a, restaurant.visits.map(&:number), "#{restaurant.name}: numbered in date order"
      assert_equal restaurant.visits.map(&:visited_on).uniq.size, restaurant.visits.size, "#{restaurant.name}: one visit a day"
    end
  end

  test "every visit names only known standards, and every miss carries a note" do
    known = Sample.standards.map(&:id)
    RAW.fetch("restaurants").each do |restaurant|
      restaurant.fetch("visits").each do |visit|
        where = "#{restaurant['slug']} visit #{visit['number']}"
        listed = visit.fetch("missed").keys + visit.fetch("na") + visit.fetch("notes").keys
        assert_empty listed - known, "#{where}: unknown standard"
        assert_empty visit.fetch("missed").keys & visit.fetch("na"), "#{where}: a standard both missed and N/A"
        visit.fetch("missed").each { |id, note| assert note.present?, "#{where}: #{id} missed with no note" }
        assert_equal Sample.departments.map(&:key).sort, visit.fetch("observations").keys.sort, where
      end
    end
  end

  test "the sample carries no email address, phone number or link" do
    text = File.read(Sample::PATH)
    assert_no_match(/@/, text)
    assert_no_match(/\d{3}[-. ]\d{3}[-. ]\d{4}/, text)
    assert_no_match(%r{https?://}, text)
  end

  test "lookups return nil for unknown keys" do
    assert_nil Sample.restaurant("nope")
    assert_nil Sample.standard("zz")
    assert_nil Sample.department("kitchen")
    assert_equal "Harbor & Hearth", Sample.restaurant("harbor-and-hearth").name
  end
end
