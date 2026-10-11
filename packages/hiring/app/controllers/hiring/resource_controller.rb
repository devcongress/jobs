module Hiring
  class ResourceController < ::ResourceController
    # Lets models record who acted (e.g. who moved an applicant along).
    before_action { Current.user = current_user if current_user.is_a?(::User) }
    # add concerns above.
  end
end
