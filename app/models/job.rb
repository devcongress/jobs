class Job < ApplicationRecord
    belongs_to :user
    include Archivable::Model
end
