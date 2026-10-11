module Site
  class JobsController < BaseController
    def index
      scope = Hiring::JobPost.visible_to(current_user)
      @countries = scope.where.not(country: [nil, ""]).distinct.order(:country).pluck(:country)

      @kind = params[:kind].presence_in(Hiring::JobPost::KINDS.keys)
      scope = scope.of_kind(@kind) if @kind
      scope = scope.search(params[:q]) if params[:q].present?
      scope = scope.where(employment_type: params[:type]) if Hiring::JobPost.employment_types.key?(params[:type])
      scope = scope.where(seniority: params[:seniority]) if Hiring::JobPost.seniorities.key?(params[:seniority])
      scope = scope.where(country: params[:country]) if params[:country].present?
      scope = scope.where(remote_ok: true) if params[:remote] == "1"

      @jobs = paginate(scope.includes(company: {personal_owner: :developer_profile}).newest)
    end

    def show
      @job = Hiring::JobPost.includes(company: {personal_owner: :developer_profile}).from_path_param(params[:id]).first!
      raise ActiveRecord::RecordNotFound unless @job.visible_to?(current_user)

      @profile = current_user&.developer_profile
      @application = @profile && @job.job_applications.find_by(profile: @profile)
      @more_jobs = Hiring::JobPost.visible_to(current_user).where(company: @job.company).where.not(id: @job.id).newest.limit(3)
    end
  end
end
