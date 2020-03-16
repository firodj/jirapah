namespace :custom do
  desc "TODO"
  task do_it: :environment do
    svc = JiraImporter.new
    issues = svc.search(project_keys: "GLB", labels: "TECHDEBT")
    binding.pry
  end
end
