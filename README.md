# SchemaVersionCache

[![concourse.odeko.com](https://concourse.odeko.com/api/v1/teams/main/pipelines/schema-version-cache-main/jobs/test/badge)](https://concourse.odeko.com/teams/main/pipelines/schema-version-cache-main)

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
version = AvroSchemaVersionCache.get_version_number(subject:, schema_id:)
schema_json = AvroSchemaVersionCache.get_schema_json(subject:, version:)
versions = AvroSchemaVersionCache.get_version_numbers(subject:)

# Find compatible version using Avro parsing and validator:
compatible_version = AvroSchemaVersionCache.find_compatible_version(
  subject:,
  data: {color: "red", bright: true}
)

# Find compatible version using custom parsing and validator:
custom_compatible_version = AvroSchemaVersionCache.find_compatible_version(
  subject:,
  data: {color: "red", bright: true},
  schema_parser: ->(string) { MySchemaParser.parse(string) },
  validator: ->(schema, data) { MyValidator.valid?(schema, data) }
)
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

Note that we have a development dependency on sorbet for static type-checking,
and we declare a public interface RBI file in the `rbi/` directory to aid with
type-checking in projects that use this gem. We avoid placing type annotations
directly in `lib/schema_version_cache.rb` or enabling runtime type-checking.
This allows applications to use our gem regardless of whether they use sorbet.
