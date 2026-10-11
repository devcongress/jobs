module Hiring
  # Company members managing their jobs (company portal). The developer and
  # admin portals subclass this.
  class JobPostPolicy < Hiring::ResourcePolicy
    def create? = true

    def read? = true

    def update? = record.archived_at.nil?

    # Only drafts can be deleted; published jobs are archived instead.
    def destroy? = record.published_at.nil?

    def publish? = record.publishable?

    def renew? = record.renewable?

    def mark_filled? = record.fillable?

    def reopen? = record.filled_at.present? && record.archived_at.nil?

    def archive? = record.archived_at.nil?

    def apply? = false

    # Reviewing first jobs is for admins only (see the admin portal policy).
    def approve? = false

    def decline? = false

    def permitted_attributes_for_create
      %i[
        title description employment_type seniority
        remote_ok city country
        paid pay_period salary_min salary_max salary_currency
        duration starts_on
        accepts_applications apply_url
        visibility
      ]
    end

    # The type (job, gig, internship) is fixed once the post exists.
    def permitted_attributes_for_update
      permitted_attributes_for_create - %i[employment_type]
    end

    def permitted_attributes_for_read
      %i[title status visibility type_label seniority location pay timing description accepts_applications apply_url published_at expires_at]
    end

    def permitted_attributes_for_index
      %i[title status type_label location expires_at]
    end

    def permitted_associations
      %i[job_applications]
    end
  end
end
