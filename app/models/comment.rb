class Comment < ApplicationRecord
  validates_presence_of :guid
  belongs_to :author, class_name: Member.to_s, optional: true
  belongs_to :editor, class_name: Member.to_s, optional: true
  belongs_to :story
end