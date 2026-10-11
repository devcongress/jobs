module Site
  # Endorse or un-endorse one of a connection's skills from their profile page.
  class EndorsementsController < BaseController
    include NetworkActions

    def create
      endorsement = profile_skill.endorsements.new(endorser: viewer_profile)
      if endorsement.save
        redirect_back_to_profile notice: "You endorsed #{target_profile.name} for #{profile_skill.skill.name}."
      else
        redirect_back_to_profile alert: endorsement.errors.full_messages.to_sentence
      end
    end

    def destroy
      profile_skill.endorsements.where(endorser: viewer_profile).destroy_all
      redirect_back_to_profile notice: "Endorsement removed."
    end

    private

    def profile_skill
      @profile_skill ||= target_profile.profile_skills.joins(:skill).find_by!(skills: {slug: params[:skill]})
    end
  end
end
