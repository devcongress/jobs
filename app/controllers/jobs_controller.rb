class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy]
  before_action :require_permission, only: [:edit, :destroy]

  def index
    @jobs = Job.all
  end

  def show
  end

  def myjobs
    if user_signed_in?
      @jobs = current_user.jobs
    else
      redirect_to new_user_session_path, notice: 'Sign in see jobs you have posted'
    end
  end

  def new
    if user_signed_in?
      @job = current_user.jobs.build
    else
      redirect_to new_user_session_path, notice: 'Sign in to create a job post'
    end
  end

  def edit
  end

  def create
    if current_user
      @job = current_user.jobs.build(job_params)
    end

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render :show, status: :created, location: @job }
      else
        format.html { render :new }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /jobs/1
  # PATCH/PUT /jobs/1.json
  def update
    respond_to do |format|
      if @job.update(job_params)
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { render :show, status: :ok, location: @job }
      else
        format.html { render :edit }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy
    respond_to do |format|
      format.html { redirect_to jobs_url, notice: 'Job was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def require_permission
    if current_user != @job.user
      # redirect_to root_path
      respond_to do |format|
        format.html { redirect_to root_path, notice: 'You are not authorized to edit another users job post.' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params.require(:job).permit(:role, :duration, :salary, :requirements, :qualification, :perks, :company, :contact_email, :poster_name, :poster_email, :phone, :user_id, :archived)
    end
end
