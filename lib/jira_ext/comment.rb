JIRA::Resource::Comment.class_eval {
  has_one :author, class: JIRA::Resource::User
  has_one :editor, class: JIRA::Resource::User,
                   attribute_key: 'updateAuthor'
}