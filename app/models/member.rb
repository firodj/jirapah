class Member < ApplicationRecord
  validates_presence_of :guid
  scope :preferred, -> { where(guid: (ENV['PREF_MEMBER_GUIDS'] || '').split(',')) }
end
