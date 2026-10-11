module Site
  class ProjectsController < BaseController
    def index
      scope = Showcase::Project.visible_to(current_user)
      @skills = Skill.joins(:project_skills).where(showcase_project_skills: {project_id: scope.select(:id)}).distinct.order(:name)

      scope = scope.search(params[:q]) if params[:q].present?
      scope = scope.where(id: Showcase::ProjectSkill.joins(:skill).where(skills: {slug: params[:skill]}).select(:project_id)) if params[:skill].present?

      @projects = paginate(scope.includes(:owner, :skills, confirmed_contributors: :profile).newest)
    end

    def show
      @project = Showcase::Project.includes(:skills, :owner).find_by!(slug: params[:slug])
      raise ActiveRecord::RecordNotFound unless @project.visible_to?(current_user)

      @own = @project.owned_by?(current_user)
      # Confirmed contributors whose profiles the viewer may see.
      @contributors = @project.confirmed_contributors.includes(:profile).select { |c| c.profile.visible_to?(current_user) }
      @pending_count = @own ? @project.contributors.pending.count : 0
    end
  end
end
