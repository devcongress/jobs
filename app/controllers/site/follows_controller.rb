module Site
  # Follow and unfollow buttons on profiles, directory cards and the network
  # page. Following someone who already follows you connects you.
  class FollowsController < BaseController
    include NetworkActions

    rate_limit to: 30, within: 1.minute, only: :create, with: -> { redirect_back_to_profile alert: "You're following people too quickly. Try again in a minute." }

    def create
      follow = viewer_profile.outgoing_follows.find_or_create_by!(followee: target_profile)
      notice = follow.mutual? ? "You're now connected with #{target_profile.name}." : "You're following #{target_profile.name}."
      redirect_back_to_profile notice:
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_to_profile alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      viewer_profile.outgoing_follows.where(followee: target_profile).destroy_all
      redirect_back_to_profile notice: "You've unfollowed #{target_profile.name}."
    end
  end
end
