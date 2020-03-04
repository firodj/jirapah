.PHONY: all setup config database test

all: setup config database test

test:
	RAILS_ENV=test bundle exec rake db:migrate
	COVERAGE=true bundle exec rspec

database:
	RAILS_ENV=test bundle exec rake db:drop db:create

config: .env.local

.env.local:
	cp -v .env.template .env.local

setup:
	bundle install --path vendor/bundle

erd:
	RAILS_ENV=test bin/rails erd

