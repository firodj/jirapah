class Sprint < ApplicationRecord
    validates_presence_of :guid

    has_and_belongs_to_many :stories
end