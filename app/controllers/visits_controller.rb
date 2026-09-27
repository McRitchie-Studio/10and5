class VisitsController < ApplicationController
  before_action :set_visit

  # The evaluator's scorecard.
  def show
  end

  # The restaurant's view: what was missed, against last visit and last six.
  def action_plan
    @plan = @visit.action_plan
  end

  private

  def set_visit
    @restaurant = Sample.restaurant(params[:restaurant_slug]) or not_found!
    @visit = @restaurant.visit(params[:number].to_i) or not_found!
  end
end
