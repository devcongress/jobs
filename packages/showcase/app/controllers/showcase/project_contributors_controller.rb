class Showcase::ProjectContributorsController < Showcase::ResourceController
  private

  # Declining deletes the credit, so there's no record page to go back to.
  def redirect_url_after_action_on(record)
    (record.is_a?(ActiveRecord::Base) && record.destroyed?) ? resource_url_for(resource_class) : super
  end
end
