module OgCard
  class Job < Base
    def initialize(job)
      @job = job
      @company = job.company
    end

    def eyebrow = @job.type_label

    def title = @job.title

    def subtitle = @company.personal? ? "by #{@company.display_name}" : "at #{@company.display_name}"

    def footer = [@job.location.presence, @job.pay].compact.join(" · ").presence

    def avatar
      if @company.personal?
        avatar_for(@company.display_name, seed: @company.personal_profile&.handle || @company.slug)
      else
        avatar_for(@company.display_name, seed: @company.slug, shape: :square)
      end
    end

    def route = [:og_job_image, {id: @job.id}]

    def cache_key = ["job", @job.cache_key_with_version, @company.cache_key_with_version, @company.display_name]
  end
end
