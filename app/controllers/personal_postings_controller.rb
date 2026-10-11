# "Post as yourself": opens (creating on first use) the user's personal posting
# space, then their new-post form. Individuals need a developer profile, which
# is who the post is shown as.
class PersonalPostingsController < ::PlutoniumController
  include UserAuthenticated
  include RequiresOnboarding

  def create
    unless current_user.developer_profile
      return redirect_to new_developer_profile_path, alert: "Create your developer profile first. Posts you make yourself are shown under it."
    end

    company = Company.personal_for!(current_user)
    redirect_to PortalPathsHelper.routes.company_portal.new_company_scoped_hiring_job_post_path(company_scoped: company)
  end
end
