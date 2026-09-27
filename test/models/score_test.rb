require "test_helper"

# Unit tier: how a set of results becomes a score.
class ScoreTest < ActiveSupport::TestCase
  def result(mark) = Result.new(standard: Sample.standards.first, mark:, note: nil)

  test "N/A counts on neither side" do
    score = Score.of([ result(:pass), result(:pass), result(:fail), result(:na) ])
    assert_equal 2, score.passed
    assert_equal 3, score.scored
    assert_equal 67, score.percent
  end

  test "nothing scored has no percent rather than zero" do
    score = Score.of([ result(:na), result(:na) ])
    assert_not score.any?
    assert_nil score.percent
    assert_equal 0, Score.of([ result(:fail) ]).percent
  end

  test "sum adds passed and scored across visits" do
    total = Score.sum([ Score.new(passed: 3, scored: 4), Score.new(passed: 0, scored: 0), Score.new(passed: 1, scored: 2) ])
    assert_equal Score.new(passed: 4, scored: 6), total
    assert_equal Score.new(passed: 0, scored: 0), Score.sum([])
  end
end
