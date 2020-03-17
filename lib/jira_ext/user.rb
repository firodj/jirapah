JIRA::Resource::User.class_eval {
  def self.singular_path(client, key, prefix = '/')
   collection_path(client, prefix) + '?accountId=' + key
  end
}