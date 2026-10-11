# The hiring team's activity on an application: private notes, plus an entry
# for every status change. Never shown to the applicant.
class Hiring::ApplicationNote < Hiring::ResourceRecord
  enum :kind, {note: 0, status_change: 1}

  belongs_to :job_application, class_name: "Hiring::JobApplication", inverse_of: :notes
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true, length: {maximum: 5_000}, if: :note?
end
