# typed: strong

class SchemaVersionCache
  SchemaNotFound = Class.new(StandardError)
  SubjectLookupError = Class.new(StandardError)

  sig { params(registry: T.untyped).void }
  def initialize(registry); end

  sig { params(subjects: T::Array[String]).void }
  def preload(subjects); end

  sig { params(subject: String).returns(T::Array[Integer]) }
  def get_version_numbers(subject:); end

  sig { params(subject: String, schema_id: Integer).returns(Integer) }
  def get_version_number(subject:, schema_id:); end

  sig { params(subject: String).returns(Integer) }
  def get_current_id(subject:); end

  sig { params(subject: String, version: Integer).returns(Integer) }
  def get_schema_id(subject:, version:); end

  sig { params(subject: String, version: Integer).returns(String) }
  def get_schema_json(subject:, version:); end

  sig do
    params(
      subject: String,
      data: T.untyped,
      schema_parser: T.nilable(
        T.proc.params(json: String).returns(T.untyped)
      ),
      validator: T.nilable(
        T.proc.params(schema: T.untyped, data: T.untyped).returns(T::Boolean)
      )
    ).returns(
      Integer
    )
  end
  def find_compatible_version(subject:, data:, schema_parser: nil, validator: nil); end

  sig do
    params(
      subject: T.untyped,
      data: T.untyped,
      schema_parser: T.nilable(
        T.proc.params(json: String).returns(T.untyped)
      ),
      validator: T.nilable(
        T.proc.params(schema: T.untyped, data: T.untyped).returns(T::Boolean)
      )
    ).returns(
      T.nilable(Integer)
    )
  end
  def newest_compatible_version(subject:, data:, schema_parser:, validator:); end

  sig { params(json: String).returns(::Avro::Schema) }
  def avro_parse(json); end

  sig { params(schema: ::Avro::Schema, data: T.untyped).returns(T::Boolean) }
  def avro_valid?(schema, data); end

  sig { params(subject: String).void }
  def add_subject_to_cache(subject); end

  sig { params(attributes: T.untyped).returns(T.noreturn) }
  def schema_not_found(**attributes); end
end
