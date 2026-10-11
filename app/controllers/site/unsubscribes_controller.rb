# Unsubscribe links from categorised emails and Slack DMs. Opening the link only asks:
# link scanners follow GETs, so turning a category off takes a POST, which is also
# what mail clients send for one-click unsubscribe (with no CSRF token).
module Site
  class UnsubscribesController < BaseController
    skip_forgery_protection only: :create
    before_action :resolve_token

    def show
    end

    def create
      @user.opt_out!(@category, via: @channel)
      render :show
    end

    private

    def resolve_token
      @user, @channel, @category = NotificationOptOut.resolve(params[:token])
      raise ActiveRecord::RecordNotFound unless @user
    end
  end
end
