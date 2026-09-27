class RestaurantsController < ApplicationController
  def index
    @restaurants = Sample.restaurants
  end

  def show
    @restaurant = Sample.restaurant(params[:slug]) or not_found!
  end
end
