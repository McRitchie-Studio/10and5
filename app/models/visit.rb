# One anonymous evaluation of a restaurant: when the evaluator came and went,
# the check, what they noticed about each department's staff, and a result for
# every standard.
class Visit
  NOTE_LIMIT = 500

  attr_reader :restaurant, :number, :visited_on, :evaluator, :party_size, :arrived, :departed,
    :check_number, :table, :check_amount, :all_items_billed, :observations

  def self.from_h(restaurant, raw)
    marks = raw.fetch("missed", {}).keys.index_with(:fail)
      .merge(Array(raw["na"]).index_with(:na))
    notes = raw.fetch("notes", {}).merge(raw.fetch("missed", {}))
    new(restaurant:, marks:, notes:, number: raw.fetch("number"), visited_on: Date.iso8601(raw.fetch("date")),
      evaluator: raw["evaluator"], party_size: raw["party_size"], arrived: raw["arrived"], departed: raw["departed"],
      check_number: raw["check_number"], table: raw["table"], check_amount: raw["check_amount"],
      all_items_billed: raw["all_items_billed"], observations: raw.fetch("observations", {}))
  end

  # A scorecard an evaluator filled in on the demo form. It is scored and
  # compared like any visit, and never saved.
  def self.draft(restaurant, params)
    marks = params.fetch(:marks, {}).to_h.to_h do |id, mark|
      [ id.to_s, Result::MARKS.map(&:to_s).include?(mark.to_s) ? mark.to_sym : :pass ]
    end
    notes = params.fetch(:notes, {}).to_h.transform_keys(&:to_s)
    details = params.fetch(:details, {})
    new(restaurant:, marks:, notes:, number: nil, visited_on: Date.current, evaluator: "Draft scorecard",
      party_size: details[:party_size].presence&.to_i, arrived: details[:arrived].presence,
      departed: details[:departed].presence, check_number: details[:check_number].presence,
      table: details[:table].presence, check_amount: details[:check_amount].presence&.to_f,
      all_items_billed: details[:all_items_billed].presence && details[:all_items_billed] == "yes",
      observations: params.fetch(:observations, {}).to_h.transform_keys(&:to_s))
  end

  def initialize(restaurant:, marks:, notes:, number:, visited_on:, evaluator:, party_size:, arrived:, departed:,
                 check_number:, table:, check_amount:, all_items_billed:, observations:)
    @restaurant, @number, @visited_on, @evaluator = restaurant, number, visited_on, evaluator
    @party_size, @arrived, @departed = party_size, arrived, departed
    @check_number, @table, @check_amount, @all_items_billed = check_number, table, check_amount, all_items_billed
    @observations = observations.transform_values { |v| clip(v) }
    @results = Sample.standards.to_h do |standard|
      [ standard.id, Result.new(standard:, mark: marks.fetch(standard.id, :pass), note: clip(notes[standard.id])) ]
    end
  end

  def draft? = number.nil?

  def to_param = number.to_s

  def result_for(standard) = @results.fetch(standard.id)

  def results(department = nil)
    list = @results.values
    department ? list.select { |r| r.standard.department_key == department.key } : list
  end

  def missed(department = nil) = results(department).select(&:fail?)

  def score(department = nil) = Score.of(results(department))

  def observation(department) = observations[department.key]

  def action_plan = ActionPlan.new(self)

  private

  def clip(text)
    text.to_s.strip.first(NOTE_LIMIT).presence
  end
end
