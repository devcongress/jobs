# frozen_string_literal: true

# Gates the management engines mounted in config/routes.rb (jobs, errors,
# litestream, pulse). Only signed-in admins get through; everyone else is sent
# to the admin login.
class ManagementConstraint
  AUTHENTICATE = Rodauth::Rails.authenticate(:admin)

  def self.matches?(request)
    AUTHENTICATE.call(request)
  end
end
