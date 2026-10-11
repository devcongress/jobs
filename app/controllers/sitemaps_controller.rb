# /sitemap.xml: every page a guest can see. Companies are listed only while
# they have a public job, to keep empty pages out of search indexes.
class SitemapsController < ActionController::Base
  def show
    @profiles = Developers::Profile.visible_to(nil).order(:id)
    @jobs = Hiring::JobPost.visible_to(nil).order(:id)
    @companies = Company.organizations.where(id: @jobs.select(:company_id)).order(:id)
    @projects = Showcase::Project.visible_to(nil).order(:id)
    expires_in 1.hour, public: true
  end
end
