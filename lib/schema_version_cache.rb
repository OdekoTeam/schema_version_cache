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
    @by_version = {}
    @by_id = {}
  end

  def preload(subjects)
    subjects.each { |subject| add_subject_to_cache(subject) }
  end

  def get_version_number(subject:, schema_id:)
    if @by_id.key?(subject) && @by_id.fetch(subject).key?(schema_id)
      return @by_id.fetch(subject).fetch(schema_id).version
    end

    add_subject_to_cache(subject)
    @by_id.dig(subject, schema_id)&.version || schema_not_found(subject:, schema_id:)
  end

  def get_current_id(subject:)
    if @by_id.key?(subject) && @by_id.fetch(subject).keys.any?
      return @by_id.fetch(subject).keys.max
    end

    add_subject_to_cache(subject)
    @by_id.fetch(subject, {}).keys.max || schema_not_found(subject:)
  end

  private

  Entry = Struct.new(:subject, :version, :id, keyword_init: true)

  def add_subject_to_cache(subject)
    entries = @registry.subject_versions(subject).sort.map do |version|
      data = @registry.subject_version(subject, version)
      id = data.fetch("id")
      Entry.new(subject:, version:, id:)
    end

    @by_version[subject] = entries.reduce({}) do |hash, entry|
      hash.merge!(entry.version => entry)
    end
    @by_id[subject] = entries.reduce({}) do |hash, entry|
      hash.merge!(entry.id => entry)
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
