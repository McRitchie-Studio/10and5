class ApplicationController < ActionController::Base
  private

  def not_found!
    raise ActionController::RoutingError, "Not Found"
  end
end
