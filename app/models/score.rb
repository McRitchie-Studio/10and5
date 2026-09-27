# Standards passed out of standards scored. N/A counts in neither, so a
# department nobody saw scores nothing rather than zero.
Score = Data.define(:passed, :scored) do
  def self.of(results)
    scored = results.reject(&:na?)
    new(passed: scored.count(&:pass?), scored: scored.size)
  end

  def self.sum(scores)
    new(passed: scores.sum(&:passed), scored: scores.sum(&:scored))
  end

  def any? = scored.positive?

  # Whole percent, or nil when nothing was scored.
  def percent
    (passed * 100.0 / scored).round if any?
  end
end
