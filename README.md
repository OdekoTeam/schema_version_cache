# SchemaVersionCache

Make Avro schema version queries fast and easy.

## Installation

Add to the application's Gemfile:
```ruby
gem "schema_version_cache", source: "https://gem.odeko.com/"
```

## Usage

Initialize a schema registry client and a cache:
```ruby
# config/initializers/kafka.rb

require "avro_turf/messaging"

registry = AvroTurf::ConfluentSchemaRegistry.new(
  ENV["CONFLUENT_SCHEMA_REGISTRY_URL"],
  user: ENV["CONFLUENT_SCHEMA_REGISTRY_USER"],
  password: ENV["CONFLUENT_SCHEMA_REGISTRY_PASSWORD"]
)
AvroSchemaVersionCache = SchemaVersionCache.new(registry)
```

Optionally, preload the cache on startup:
```ruby
# config/racecar.rb

Racecar.configure do |config|
  # ...
  AvroSchemaVersionCache.preload(
    [
      "com.odeko.foo_service.Foo_value",
      "com.odeko.bar_service.Bar_value"
    ]
  )
end
```

Run schema queries as needed:
```ruby
subject = "com.odeko.foo_service.Foo_value"
schema_id = AvroSchemaVersionCache.get_current_id(subject:)
version_number = AvroSchemaVersionCache.get_version_number(subject:, schema_id:)
```

## Development

Prerequisites: Ruby and bundler.

Install project dependencies:
```console
$ bin/setup
```

Run the test-suite:
```console
$ bin/ci-test
```

Run the linter:
```console
$ bin/lint
```
