module ApplicationHelper
  MARK_LABELS = { pass: "Pass", fail: "Fail", na: "N/A" }.freeze

  def mark_pill(result)
    return tag.span("No visit", class: "pill pill--none") unless result

    tag.span(MARK_LABELS.fetch(result.mark), class: "pill pill--#{result.mark}", data: { mark: result.mark })
  end

  # "82%", or an en dash when nothing was scored.
  def percent(score)
    score&.any? ? "#{score.percent}%" : "–"
  end

  # "4 of 6 passed" for a standard across earlier visits.
  def passed_of(score)
    return "Not scored" unless score.any?

    "#{score.passed} of #{score.scored} passed"
  end

  # "+12 pts" / "-8 pts" / "No change"; nil when there is nothing to compare.
  def change_label(change)
    return if change.nil?
    return "No change" if change.zero?

    format("%+d pts", change)
  end

  def change_tag(change)
    label = change_label(change)
    return tag.span("First comparison", class: "change change--none") unless label

    direction = change.positive? ? "up" : (change.negative? ? "down" : "flat")
    tag.span(label, class: "change change--#{direction}")
  end

  # Rating band for a score, so the number reads at a glance.
  def band(score)
    return "none" unless score&.any?

    case score.percent
    when 90.. then "high"
    when 75...90 then "mid"
    else "low"
    end
  end

  def visit_date(visit, format: "%b %-d, %Y")
    visit.visited_on.strftime(format)
  end

  def visit_title(visit)
    visit.draft? ? "Draft scorecard" : "Visit #{visit.number}"
  end

  def money(amount)
    amount ? number_to_currency(amount) : "–"
  end

  def yes_no(value)
    value.nil? ? "–" : (value ? "Yes" : "No")
  end

  def brand_mark
    tag.span("10&5", class: "brand__mark", aria: { hidden: true })
  end
end
