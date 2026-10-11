# Public pages (landing, developer directory, jobs, companies). Guests and
# signed-in users both see them; what's shown depends on each record's
# visibility setting.
module Site
  class BaseController < ::ApplicationController
    include Plutonium::Auth::Rodauth(:user)
    include PortalPathsHelper

    helper PortalPathsHelper
    helper SiteHelper
    helper SeoHelper
    layout "site"

    PER_PAGE = 24

    rescue_from ActiveRecord::RecordNotFound do
      render "site/shared/not_found", status: :not_found
    end

    private

    def paginate(scope)
      @page = [params[:page].to_i, 1].max
      @total = scope.count
      @total = @total.size if @total.is_a?(Hash) # grouped/distinct counts
      @pages = [(@total / PER_PAGE.to_f).ceil, 1].max
      scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    end
  end
end
