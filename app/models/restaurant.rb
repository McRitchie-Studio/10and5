class Restaurant
  attr_reader :slug, :name, :cuisine, :neighborhood, :visits

  def self.from_h(raw)
    new(**raw.slice("slug", "name", "cuisine", "neighborhood").transform_keys(&:to_sym)).tap do |restaurant|
      restaurant.visits = raw.fetch("visits").map { |v| Visit.from_h(restaurant, v) }
    end
  end

  def initialize(slug:, name:, cuisine:, neighborhood:)
    @slug, @name, @cuisine, @neighborhood = slug, name, cuisine, neighborhood
    @visits = []
  end

  # Oldest first.
  def visits=(list)
    @visits = list.sort_by(&:visited_on).freeze
  end

  def to_param = slug

  def latest_visit = visits.last

  def visit(number) = visits.find { |v| v.number == number }

  # The visits completed before this one, oldest first. A draft scorecard
  # comes after every recorded visit.
  def visits_before(visit)
    return visits if visit.draft?

    visits.take_while { |v| v.visited_on < visit.visited_on }
  end
end
