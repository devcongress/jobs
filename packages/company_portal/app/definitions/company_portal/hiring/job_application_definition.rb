module CompanyPortal
  module Hiring
    # The hiring team's applicant tracker: a board by stage, filters, notes,
    # ratings and bulk moves. The application page itself is custom (see
    # ShowPage below and _application_review.html.erb).
    class JobApplicationDefinition < ::Hiring::JobApplicationDefinition
      index_page_title "Applicants"
      index_page_description "Everyone who applied to your jobs. Drag cards between stages; the applicant is emailed when they move forward, get hired or are turned down."

      # On the application page only; the table rows keep just "Move to stage".
      action :reject, interaction: ::Hiring::RejectApplicationInteraction, category: :danger, collection_record_action: false
      action :add_note, interaction: ::Hiring::AddApplicationNoteInteraction, category: :secondary, collection_record_action: false
      action :rate, interaction: ::Hiring::RateApplicationInteraction, category: :secondary, collection_record_action: false
      action :bulk_move, interaction: ::Hiring::MoveApplicationsInteraction

      column :profile, label: "Applicant"
      column :rating_stars, label: "Rating"
      column :status, label: "Stage", as: ::Hiring::StageBadge
      display :status, label: "Stage", as: ::Hiring::StageBadge

      search { |scope, query| scope.search(query) }

      filter :job_post, with: :association
      filter :status, with: :select, multiple: true,
        choices: ::Hiring::JobApplication::STAGE_LABELS.map { |status, label| [label, status] }
      filter :rating, with: ::Hiring::MinimumRatingFilter
      filter :created_at, with: :date_range

      scope :open
      scope(:needs_review) { |scope| scope.submitted }

      sort :created_at
      sort :rating

      export :profile, label: "Applicant", &->(application) { application.profile.name }
      export :email, label: "Email", &->(application) { application.applicant_email }
      export :job_post, label: "Job", &->(application) { application.job_post.title }
      export :status, label: "Stage", &->(application) { application.stage_label }
      export :created_at, label: "Applied", &->(application) { application.created_at.to_date.iso8601 }

      kanban do
        per_column 50
        card_fields header: :profile, subheader: :job_post, meta: [:rating_stars], footer: :created_at

        column :submitted, label: "New", color: :blue,
          scope: -> { where(status: :submitted) },
          on_enter: ->(application) { application.move_to!(:submitted) }
        column :reviewing, color: :pink,
          scope: -> { where(status: :reviewing) },
          on_enter: ->(application) { application.move_to!(:reviewing) }
        column :shortlisted, color: :amber,
          scope: -> { where(status: :shortlisted) },
          on_enter: ->(application) { application.move_to!(:shortlisted) }
        column :hired, role: :done, collapsed: false,
          scope: -> { where(status: :hired) },
          on_enter: ->(application) { application.move_to!(:hired) }
        column :rejected, role: :lost,
          scope: -> { where(status: :rejected) },
          enter_interaction: ::Hiring::RejectApplicationInteraction
        column :withdrawn, color: :gray, collapsed: true, locked: true,
          scope: -> { where(status: :withdrawn) }
      end
      default_index_view :kanban

      class ShowPage < ShowPage
        private

        def page_title = "Application from #{resource_record!.profile.name}"

        def page_description
          application = resource_record!
          "For #{application.job_post.title} · applied #{application.created_at.to_date.to_fs(:long)}"
        end

        def render_default_content
          render partial("application_review")
        end
      end
    end
  end
end
