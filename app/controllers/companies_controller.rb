class CompaniesController < ApplicationController
  before_action :set_company,          only: [:show, :edit, :update]
  before_action :authenticate_user!, except: [:show]
  before_action :require_ownership!,   only: [:edit, :update]

  def new
    @company = current_user.companies.build
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      current_user.companies << @company
      redirect_to @company
    else
      render :new
    end
  end

  def edit
  end

  def show
  end

  def update
    if @company.update_attributes(company_params)
      redirect_to @company
    else
      render :edit
    end
  end

  private

    def set_company
      @company = Company.find_by(id: params[:id])
      raise_not_found unless @company
    end

    def raise_not_found
      raise ActionController::RoutingError.new("not found")
    end

    def require_ownership!
      head(:forbidden) unless current_user.companies.include?(@company)
    end

    def company_params
      params.require(:company).permit(
        :name,
        :industry,
        :website,
        :description,
        :email,
        :phone,
        :city,
        :state_or_region,
        :post_code,
        :country,
        :logo
      )
    end
end
