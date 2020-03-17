JIRA::Base.class_eval {
  def self.search(client, options = {})
    response = client.get(collection_path(client) + '/search')
    json = parse_json(response.body)
    json = json[endpoint_name.pluralize] if collection_attributes_are_nested
    json.map do |attrs|
      new(client, { attrs: attrs }.merge(options))
    end
  end
}