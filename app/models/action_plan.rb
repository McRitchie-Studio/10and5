# What a restaurant should work on after a visit: every standard it missed,
# by department, each set against the visit before and the six before that
# (the same comparison the original 10&5 Action Plan made).
class ActionPlan
  LOOKBACK = 6

  # A missed standard and how it fared before. `last_visit` is the Result on
  # the visit before (nil on a first visit); `last_six` scores the standard
  # across up to six earlier visits.
  Item = Data.define(:result, :last_visit, :last_six) do
    def standard = result.standard
    def repeat? = last_visit&.fail? || false
  end

  # One department's score this visit, last visit and across the last six.
  Summary = Data.define(:department, :score, :last_visit, :last_six, :missed) do
    # Percentage points gained (positive) or lost since the last visit; nil
    # when either side scored nothing.
    def change
      score.percent - last_visit.percent if score.any? && last_visit&.any?
    end
  end

  attr_reader :visit, :previous

  def initialize(visit)
    @visit = visit
    @previous = visit.restaurant.visits_before(visit)
  end

  def last_visit = previous.last
  def last_six = previous.last(LOOKBACK)

  def items(department = nil)
    visit.missed(department).map do |result|
      Item.new(result:, last_visit: last_visit&.result_for(result.standard),
        last_six: Score.of(last_six.map { |v| v.result_for(result.standard) }))
    end
  end

  def summaries
    Sample.departments.map do |department|
      Summary.new(department:, score: visit.score(department), last_visit: last_visit&.score(department),
        last_six: Score.sum(last_six.map { |v| v.score(department) }), missed: visit.missed(department).size)
    end
  end

  def overall = visit.score
  def overall_last_six = Score.sum(last_six.map(&:score))

  def empty? = visit.missed.empty?
end
