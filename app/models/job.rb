class Job < ApplicationRecord
    belongs_to :user

    def is_archived?
        if self.archived == true
            return true
        else
            return false
        end        
    end
end
