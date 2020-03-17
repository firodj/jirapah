class Story < ApplicationRecord
  validates_presence_of :guid
  belongs_to :creator, class_name: Member.to_s, optional: true
  belongs_to :assignee, class_name: Member.to_s, optional: true
  belongs_to :reporter, class_name: Member.to_s, optional: true
  belongs_to :qa_tester, class_name: Member.to_s, optional: true
  belongs_to :pair_assignee, class_name: Member.to_s, optional: true
  has_many :change_logs
end