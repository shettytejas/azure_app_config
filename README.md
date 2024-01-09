# AzureAppConfig

An unofficial Ruby library for Azure App Configuration.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add azure_app_config

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install azure_app_config

## Usage

### Setup

You'll need to first set up some environment variables in order to use the gem.

```ENV
AZURE_APP_CONFIG_STORE_NAME = "somestore" // The name of the store to use. This would be used to build the url to the store (https://somestore.azconfig.io)
AZURE_APP_CONFIG_CREDENTIAL = "Id" // The credential (ID) to use. (Find this in App Configuration > Settings > Access Keys).
AZURE_APP_CONFIG_SECRET = "some_secret" // The secret to use. (Find this in App Configuration > Settings > Access Keys).
AZURE_APP_CONFIG_API_VERSION = "1.0" // The API version to use. Defaults to 1.0.
AZURE_APP_CONFIG_KEY_PREFIX = ".appconfig.featureflag/" // The key prefix to use. Defaults to ".appconfig.featureflag/"
```

### Examples

```ruby
require "azure_app_config"

# Fetch all keys

AzureAppConfig::Base.keys # => ["key1", "key2", "key3", "key4", "key12"]
AzureAppConfig::Base.keys(name: ["key1", "key2"]) # => ["key1", "key2"]
AzureAppConfig::Base.keys(name: "key1*") # => ["key1", "key12"]

# Fetch a single key-value pair

AzureAppConfig::Base.fetch("key1") # => { etag: "...", id: ".appconfig.featureflag/key1", label: nil, value: { enabled: true, ...}, ...}
AzureAppConfig::Base.fetch("key1", label: 'prod') # => { etag: "...", id: ".appconfig.featureflag/key1", label: "prod", value: { enabled: true, ...}, ...}
AzureAppConfig::Base.fetch("non_existent", label: 'prod') # => AzureAppConfig::NotFoundError

# Fetches all key-value pairs

AzureAppConfig::Base.all # => [{ etag: "...", id: ".appconfig.featureflag/key1", label: nil, value: { enabled: true, ...}, ...}, { etag: "...", id: ".appconfig.featureflag/key2", label: nil, value: { enabled: true, ...}, ...}, ...]
AzureAppConfig::Base.all(name: "key1*") # => [{ etag: "...", id: ".appconfig.featureflag/key1", label: nil, value: { enabled: true, ...}, ...}, ...]
AzureAppConfig::Base.all(name: "key1*", label: "prod") # => [{ etag: "...", id: ".appconfig.featureflag/key1", label: "prod", value: { enabled: true, ...}, ...}, { etag: "...", id: ".appconfig.featureflag/key12", label: "prod", value: { enabled: true, ...}, ...}, ...]
AzureAppConfig::Base.all(name: ["key1", "key2"], label: "prod") # => [{ etag: "...", id: ".appconfig.featureflag/key1", label: "prod", value: { enabled: true, ...}, ...}, { etag: "...", id: ".appconfig.featureflag/key2", label: "prod", value: { enabled: true, ...}, ...}, ...]

# Fetches all labels
AzureAppConfig::Base.labels # => [null, "prod", "test"] # null indicates the default (blank) label.
AzureAppConfig::Base.labels(name: "p*") # => ["prod"]
AzureAppConfig::Base.labels(name: ["prod", "test"]) # => ["prod", "test"]


# Check if a key is enabled

AzureAppConfig::Base.enabled?("key1") # => true
AzureAppConfig::Base.enabled?("key2", label: 'prod') # => false (even if the key is non-existent)

# Check if a key is disabled

AzureAppConfig::Base.disabled?("key1") # => false
AzureAppConfig::Base.disabled?("key2", label: 'prod') # => true (even if the key is non-existent)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shettytejas/azure_app_config. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/shettytejas/azure_app_config/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AzureAppConfig project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/shettytejas/azure_app_config/blob/master/CODE_OF_CONDUCT.md).
