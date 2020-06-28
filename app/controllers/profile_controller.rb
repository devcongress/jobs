class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @companies = current_user.companies
    @jobs = @companies.map {|company| company.jobs }
  end
end
