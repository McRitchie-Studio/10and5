require "test_helper"

# Unit tier: the labels the pages print for scores and changes.
class ApplicationHelperTest < ActionView::TestCase
  test "percent prints a dash when nothing was scored" do
    assert_equal "75%", percent(Score.new(passed: 3, scored: 4))
    assert_equal "–", percent(Score.new(passed: 0, scored: 0))
    assert_equal "–", percent(nil)
  end

  test "change labels carry a sign" do
    assert_equal "+12 pts", change_label(12)
    assert_equal "-8 pts", change_label(-8)
    assert_equal "No change", change_label(0)
    assert_nil change_label(nil)
    assert_includes change_tag(nil), "Nothing to compare"
    assert_includes change_tag(-5), "change--down"
  end

  test "bands split at 85 and 70" do
    assert_equal "high", band(Score.new(passed: 17, scored: 20))
    assert_equal "mid", band(Score.new(passed: 14, scored: 20))
    assert_equal "low", band(Score.new(passed: 13, scored: 20))
    assert_equal "none", band(Score.new(passed: 0, scored: 0))
  end

  test "passed_of reads a last-six score" do
    assert_equal "4 of 6 passed", passed_of(Score.new(passed: 4, scored: 6))
    assert_equal "Not scored", passed_of(Score.new(passed: 0, scored: 0))
  end

  test "mark pills name the mark, and a missing visit" do
    assert_includes mark_pill(Result.new(standard: Sample.standards.first, mark: :na, note: nil)), "N/A"
    assert_includes mark_pill(nil), "No visit"
  end
end
