class CalculatorsController < ApplicationController
  allow_unauthenticated_access

  def index
    @grouped = Calculator.grouped
  end

  def show
    @calculator = Calculator.find(params[:slug]) or raise ActiveRecord::RecordNotFound
  end
end
