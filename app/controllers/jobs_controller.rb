# require "twitter"

class JobsController < ApplicationController
  before_action :set_job,            except: [:new, :index, :myjobs]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :require_ownership,  only: [:edit, :destroy]

  def index
    @jobs = Job.all_active
  end

  def new
    @companies = current_user.companies
    if @companies.empty?
      redirect_to new_company_path, notice: "Register company first"
      return
    end
    @job = Job.new
  end

  def create
    company = current_user.companies.find_by(id: job_params[:company_id])
    raise_not_found unless company

    @job = company.jobs.build(job_params)
    if @job.save
      JobsMailer.with(job: @job).published.deliver_later
      redirect_to @job, status: :created
      # job_post_successful
      $tweetBot.update("...")
    else
      render :new, status: :bad_request
    end
  end

  def show
    raise_not_found if @job.archived?
  end

  def edit
  end

  def update
    if @job.update(edit_job_params)
      redirect_to @job, notice: "Job has been updated."
    else
      render :edit
    end
  end

  def myjobs
    @jobs = current_user.jobs.order("created_at DESC")
  end

  def filled
    @job.update_attribute(:filled_at, DateTime.now)
    redirect_to @job
  end

  def vacant
    @job.update_attribute(:filled_at, nil)
    redirect_to @job
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy
    respond_to do |format|
      format.html { redirect_to jobs_url, notice: "Job was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def require_ownership
      unless current_user.companies.includes(@job.company)
        redirect_to root_path, notice: "You are not authorized to edit this job post."
      end
    end

    def set_company
      @company = current_user.companies.find_by(id: params[:job][:company_id])
      raise_not_found unless @company
    end

    def set_job
      @job = Job.find_by(id: params[:id])
    end

    def job_params
      params.require(:job).permit(
        :role,
        :duration,
        :salary,
        :requirements,
        :qualification,
        :perks,
        :company_id,
        :remote_ok,
        :city,
        :country,
        :apply_link)
    end

    def edit_job_params
      params.require(:job).permit(
        :role,
        :duration,
        :salary,
        :requirements,
        :qualification,
        :perks,
        :remote_ok,
        :city,
        :country,
        :apply_link)
    end

    def raise_not_found
      raise ActionController::RoutingError.new("not found")
    end

    def job_post_successful
      # place mailer code here
      # place twitter code here
      $tweetBot.update("...")
    end
    
end
