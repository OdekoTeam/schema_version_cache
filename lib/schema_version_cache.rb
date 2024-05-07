# typed: true

class SchemaVersionCache
  SchemaNotFound = Class.new(StandardError)
  SubjectLookupError = Class.new(StandardError)

  # Registry is expected to provide the following methods:
  # - subject_versions: Given a subject, return an array of version numbers.
  # - subject_version: Given a subject and version number, return a hash of
  #   schema data including schema ID under key "id".
  #
  # In practice, we use AvroTurf::ConfluentSchemaRegistry, but for flexibility
  # and ease of testing, any object providing the necessary methods will work.
  def initialize(registry)
    @registry = registry
    @cache = {} # Hash[Subject, Hash[SchemaId, VersionNumber]]
  end

  def preload(subjects)
    subjects.each { |subject| add_subject_versions_to_cache(subject) }
  end

  def get_version_number(subject:, schema_id:)
    if @cache.key?(subject) && @cache.fetch(subject).key?(schema_id)
      return @cache.fetch(subject).fetch(schema_id)
    end

    add_subject_versions_to_cache(subject)
    @cache.dig(subject, schema_id) || schema_not_found(subject:, schema_id:)
  end

  def get_current_id(subject:)
    if @cache.key?(subject) && @cache.fetch(subject).keys.any?
      return @cache.fetch(subject).keys.max
    end

    add_subject_versions_to_cache(subject)
    @cache.fetch(subject, {}).keys.max || schema_not_found(subject:)
  end

  private

  def add_subject_versions_to_cache(subject)
    version_numbers = @registry.subject_versions(subject)
    @cache[subject] = version_numbers.reduce({}) do |hash, version_number|
      schema_data = @registry.subject_version(subject, version_number)
      schema_id = schema_data.fetch("id")
      hash.merge!(schema_id => version_number)
    end
  rescue => e
    raise SubjectLookupError, <<~ERR.chomp
      Could not lookup versions for subject "#{subject}": #{e}
    ERR
  end

  def schema_not_found(**attributes)
    raise SchemaNotFound, <<~ERR.chomp
      Could not find schema with attributes: #{
        attributes.map { |key, val| "#{key}=#{val}" }.join(", ")
      }
    ERR
  end
end
