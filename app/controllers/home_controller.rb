# Public landing page. Shows only profiles and jobs the viewer may see, and
# never contact details.
class HomeController < Site::BaseController
  def index
    listed = Developers::Profile.visible_to(current_user)
    @stats = {
      developers: listed.count,
      companies: Company.count,
      open_jobs: Hiring::JobPost.visible_to(current_user).count
    }
    # The live panel shows everyone who joined recently. Profiles the viewer
    # can't see appear as anonymous placeholders.
    @newest = Developers::Profile.includes(profile_skills: :skill).order(created_at: :desc).limit(3)
    @more_developers = listed.where.not(id: @newest.map(&:id)).includes(profile_skills: :skill).order(created_at: :desc).limit(3)
    @jobs = Hiring::JobPost.visible_to(current_user).includes(:company).newest.limit(5)
    @projects = Showcase::Project.visible_to(current_user).includes(:owner, :skills, confirmed_contributors: :profile).newest.limit(3)
    @top_skills = Skill.joins(profile_skills: :profile).merge(listed)
      .group(:name, :slug).order(Arel.sql("COUNT(*) DESC"), :name).limit(16).count
  end
end
