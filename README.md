# Jirapah

![Preview](docs/screen_20200327a.png?raw=true "Screen")

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

Install rbenv
```
$ brew install rbenv
```

* System dependencies

```
$ make setup
```

* Configuration

```
$ make config
```

Configure using `.env.local`.

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

To get `transitions` you may do:

```
curl -u $JIRA_USER:$JIRA_KEY -X GET $JIRA_HOST/rest/api/2/issue/$JIRA_ISSUE/transitions
```

OR add `expand` option:

```ruby
client.Issue.find(JIRA_ISSUE, {:expand => [:transitions]})
```
