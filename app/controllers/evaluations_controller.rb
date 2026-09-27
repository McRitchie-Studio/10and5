# The demo scorecard. An evaluator fills it in and sees the Action Plan it
# would produce; the form is a GET and nothing is stored.
class EvaluationsController < ApplicationController
  before_action :set_restaurant

  # Blank, or refilled from a draft when the evaluator comes back to edit it.
  def new
    @visit = Visit.draft(@restaurant, scorecard_params.to_h)
  end

  def preview
    @visit = Visit.draft(@restaurant, scorecard_params.to_h)
    @plan = @visit.action_plan
  end

  private

  def set_restaurant
    @restaurant = Sample.restaurant(params[:restaurant_slug]) or not_found!
  end

  def scorecard_params
    ids = Sample.standards.map { |s| s.id.to_sym }
    departments = Sample.departments.map { |d| d.key.to_sym }
    params.slice(:marks, :notes, :observations, :details).permit(marks: ids, notes: ids, observations: departments,
      details: %i[arrived departed check_number table check_amount party_size all_items_billed])
  end
end
