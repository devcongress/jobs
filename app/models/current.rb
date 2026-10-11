# Per-request context, so models can record who did something (e.g. who moved
# an applicant) without every caller passing the user along.
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
