# How one standard fared on one visit.
Result = Data.define(:standard, :mark, :note) do
  def pass? = mark == :pass
  def fail? = mark == :fail
  def na? = mark == :na
end
Result::MARKS = %i[pass fail na].freeze
