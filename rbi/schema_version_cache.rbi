# typed: strong

class SchemaVersionCache
  SchemaNotFound = Class.new(StandardError)
  SubjectLookupError = Class.new(StandardError)

  sig { params(registry: T.untyped).void }
  def initialize(registry); end

  sig { params(subjects: T::Array[String]).void }
  def preload(subjects); end

  sig { params(subject: String, schema_id: Integer).returns(Integer) }
  def get_version_number(subject:, schema_id:); end

  sig { params(subject: String).returns(Integer) }
  def get_current_id(subject:); end

  sig { params(subject: String).void }
  def add_subject_to_cache(subject); end

  sig { params(attributes: T.untyped).returns(T.noreturn) }
  def schema_not_found(**attributes); end
end
