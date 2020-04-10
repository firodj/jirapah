Gitlab.configure do |config|
  config.endpoint       = ENV['GITLAB_API_ENDPOINT']
  config.private_token  = ENV['GITLAB_API_PRIVATE_TOKEN']
  # Optional
  # config.user_agent     = 'Custom User Agent'
end
