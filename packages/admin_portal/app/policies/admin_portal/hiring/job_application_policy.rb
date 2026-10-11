module AdminPortal
  module Hiring
    class JobApplicationPolicy < ::Hiring::JobApplicationPolicy
      include AdminPortal::ResourcePolicy

      def destroy? = true
    end
  end
end
