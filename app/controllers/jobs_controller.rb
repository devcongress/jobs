class JobsController < ApplicationController
  before_action :set_job,            except: [:new, :index]
  before_action :authenticate_user!, except: [:index, :show, :search, :renew]
  before_action :require_ownership,    only: [:edit, :update, :destroy, :renew]

  def index
    @jobs = Job.all_active
  end

  def new
    @current_user = current_user
    @countries = []
    File.open("db/countries.csv" , "r") do |f|
     f.each_line do |line|
       @countries << [line.split(',')[0], line.split(',')[0]]
     end
    end
    if @current_user.companies.empty?
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
      @job.renewals.create(job: @job, renewed_on: @job.created_at)
      redirect_to @job
      job_post_successful
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

  def filled
    @job.update_attribute(:filled_at, DateTime.now)
    redirect_to @job
  end

  def vacant
    @job.update_attribute(:filled_at, nil)
    redirect_to @job
  end

  def renew
    # only expired jobs can be renewed. if a job hasn't
    # expired, any attempt to renew should be ignored.
    unless @job.active?
      @job.renewals.create(renewed_on: DateTime.now)
      JobsMailer.with(job: @job).renewed.deliver_later
    end

    redirect_to @job
  end

  def search
    @matches = Job.search(params[:q])
    respond_to do |format|
      format.html
      format.json
    end
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
      unless current_user && current_user.companies.include?(@job.company)
        redirect_to @job, notice: "You are not authorized to edit this job post."
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
        :salary_lower,
        :salary_upper,
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
        :requirements,
        :qualification,
        :salary_lower,
        :salary_upper,
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
      JobsMailer.with(job: @job).published.deliver_later
      $tweetJob.update("New Job Vacancy: #{@job.title}. Read more at #{url_for(@job)}")
    end
    
end
