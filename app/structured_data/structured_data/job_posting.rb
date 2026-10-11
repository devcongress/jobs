module StructuredData
  # Google for Jobs. Only live, public posts: Google penalises listings that
  # stay up after the job is gone.
  class JobPosting < Base
    EMPLOYMENT_TYPES = {
      "full_time" => "FULL_TIME", "part_time" => "PART_TIME", "contract" => "CONTRACTOR",
      "freelance" => "CONTRACTOR", "internship" => "INTERN"
    }.freeze
    PAY_UNITS = {"year" => "YEAR", "month" => "MONTH", "day" => "DAY", "hour" => "HOUR"}.freeze

    def to_h
      job = @record
      return unless job.visible_to?(nil)

      {
        "@context" => CONTEXT,
        "@type" => "JobPosting",
        "title" => job.title,
        "description" => description,
        "url" => view.public_job_url(job),
        "datePosted" => job.published_at.iso8601,
        "validThrough" => job.expires_at.iso8601,
        "employmentType" => EMPLOYMENT_TYPES.fetch(job.employment_type),
        "hiringOrganization" => hiring_organization,
        "jobLocation" => job_location,
        "jobLocationType" => ("TELECOMMUTE" if job.remote_ok?),
        "applicantLocationRequirements" => applicant_location,
        "baseSalary" => base_salary,
        "directApply" => (true if job.accepts_applications?)
      }.compact
    end

    private

    def description
      view.render_markdown(@record.description).to_s
    end

    def hiring_organization
      company = @record.company
      url = company.personal? ? nil : view.public_company_url(company.slug)
      {"@type" => "Organization", "name" => company.display_name, "sameAs" => url}.compact
    end

    def job_location
      place = address(city: @record.city, country: @record.country)
      {"@type" => "Place", "address" => place} if place
    end

    def applicant_location
      return unless @record.remote_ok? && @record.country.present?

      {"@type" => "Country", "name" => @record.country}
    end

    def base_salary
      job = @record
      unit = PAY_UNITS[job.pay_period]
      amounts = [job.salary_min, job.salary_max].compact.uniq
      return if !job.paid? || unit.nil? || amounts.empty?

      value = {"@type" => "QuantitativeValue", "unitText" => unit}
      value.update((amounts.size == 2) ? {"minValue" => amounts.first, "maxValue" => amounts.last} : {"value" => amounts.first})
      {"@type" => "MonetaryAmount", "currency" => job.salary_currency, "value" => value}
    end
  end
end
