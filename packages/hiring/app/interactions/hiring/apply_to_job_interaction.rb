module Hiring
  # A developer applying in the app. Runs in the developer portal, where the
  # scoped entity is the applicant's own profile.
  class ApplyToJobInteraction < Hiring::ResourceInteraction
    presents label: "Apply", icon: Phlex::TablerIcons::Send, description: "Send your profile to the company"

    attribute :resource
    attribute :cover_note, :string
    attribute :resume

    input :cover_note, as: :text, hint: "Optional. Why you're a good fit."
    input :resume, as: :file, label: "CV", accept: ::ResumeUploader::TYPES.values.join(","),
      hint: "Optional. PDF or Word, up to 5 MB. Only this company's hiring team can open it."

    private

    def execute
      application = resource.job_applications.build(profile: current_scoped_entity, cover_note:)
      application.resume = resume if resume.present?
      application.save!
      succeed(application).with_message("Application sent to #{resource.poster_name}. They'll see your profile and contact details.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
