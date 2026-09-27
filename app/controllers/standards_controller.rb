class StandardsController < ApplicationController
  def index
    @departments = Sample.departments
  end
end
