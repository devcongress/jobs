class CompaniesController < ApplicationController
  before_action :set_company,        only: [:show, :edit]
  before_action :authenticate_user!, only: [:new, :create, :edit]
  before_action :require_ownership!, only: [:edit, :update]

  def new
    @company = current_user.companies.build
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      current_user.companies << @company
      redirect_to @company
    else
      puts @company.errors.full_messages.inspect
      render :new
    end
  end

  def edit
  end

  def show
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
      unless current_user.companies.include?(@company)
        redirect_to @company, notice: "You're not authorized to edit this company"
      end
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
        :country
      )
    end
end
