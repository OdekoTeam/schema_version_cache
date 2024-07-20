require "schema_version_cache"
require "json"

class TestRegistry
  def initialize(data)
    @data = data
  end

  def subject_versions(subject)
    @data.fetch(subject).keys
  end

  def subject_version(subject, version)
    @data.fetch(subject).fetch(version)
  end
end

describe SchemaVersionCache do
  let(:foo_schema_v1) do
    JSON.generate(
      "type" => "record",
      "name" => "Foo",
      "doc" => "Foo1",
      "fields" => [
        {"name" => "fooInt", "type" => "int"}
      ]
    )
  end
  let(:foo_schema_v2) do
    JSON.generate(
      "type" => "record",
      "name" => "Foo",
      "doc" => "Foo2",
      "fields" => [
        {"name" => "fooInt", "type" => "int"},
        {"name" => "fooString", "type" => "string"}
      ]
    )
  end
  let(:foo_schema_v3) do
    JSON.generate(
      "type" => "record",
      "name" => "Foo",
      "doc" => "Foo3",
      "fields" => [
        {"name" => "fooInt", "type" => "int"},
        {"name" => "fooString", "type" => "string", "doc" => "A"}
      ]
    )
  end
  let(:foo_schema_v4) do
    JSON.generate(
      "type" => "record",
      "name" => "Foo",
      "doc" => "Foo4",
      "fields" => [
        {"name" => "fooInt", "type" => "int"},
        {"name" => "fooString", "type" => "string", "doc" => "B"},
        {"name" => "fooLong", "type" => "long"}
      ]
    )
  end

  let(:bar_schema_v1) do
    JSON.generate("type" => "string", "doc" => "Bar1")
  end
  let(:bar_schema_v2) do
    JSON.generate("type" => "string", "doc" => "Bar2")
  end

  let(:baz_schema_v1) do
    JSON.generate("type" => "string", "doc" => "Baz1")
  end
  let(:baz_schema_v2) do
    JSON.generate("type" => "string", "doc" => "Baz2")
  end

  let(:registry_data) do
    {
      "foo" => {
        1 => {"id" => 1000, "schema" => foo_schema_v1},
        2 => {"id" => 1001, "schema" => foo_schema_v2},
        3 => {"id" => 1002, "schema" => foo_schema_v3},
        4 => {"id" => 1003, "schema" => foo_schema_v4}
      },
      "bar" => {
        1 => {"id" => 2000, "schema" => bar_schema_v2},
        2 => {"id" => 2001, "schema" => bar_schema_v2}
      },
      "baz" => {
        1 => {"id" => 3000, "schema" => baz_schema_v2},
        2 => {"id" => 3001, "schema" => baz_schema_v2}
      }
    }
  end
  let(:instance) do
    described_class.new(TestRegistry.new(registry_data))
  end

  describe "#get_version_numbers" do
    let(:data_lists) do
      registry_data.map do |subject, data|
        version_numbers = data.keys.sort
        [subject, version_numbers]
      end
    end

    it "returns version numbers" do
      data_lists.each do |subject, version_numbers|
        expect(instance.get_version_numbers(subject:)).to eq(version_numbers)
      end
    end

    it "uses cache when possible" do
      data_lists.each do |subject, version_numbers|
        instance.get_version_numbers(subject:)
      end
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      data_lists.each do |subject, version_numbers|
        expect(instance.get_version_numbers(subject:)).to eq(version_numbers)
      end
    end

    it "raises an error if subject cannot be found" do
      expect { instance.get_version_numbers(subject: "fnord") }
        .to raise_error(described_class::SubjectLookupError)
    end
  end

  describe "#get_version_number" do
    let(:data_lists) do
      registry_data.flat_map do |subject, data|
        data.map do |version, val|
          [subject, val["id"], version]
        end
      end
    end

    it "returns version number" do
      data_lists.each do |subject, schema_id, version|
        expect(instance.get_version_number(subject:, schema_id:)).to eq(version)
      end
    end

    it "uses cache when possible" do
      data_lists.each do |subject, schema_id, version|
        instance.get_version_number(subject:, schema_id:)
      end
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      data_lists.each do |subject, schema_id, version|
        expect(instance.get_version_number(subject:, schema_id:)).to eq(version)
      end
    end

    it "raises an error if schema cannot be found" do
      expect { instance.get_version_number(subject: "foo", schema_id: 2000) }
        .to raise_error(described_class::SchemaNotFound)
    end
  end

  describe "#get_current_id" do
    let(:data_lists) do
      registry_data.map do |subject, data|
        max_id = data.map { |_version, val| val["id"] }.max
        [subject, max_id]
      end
    end

    it "returns highest ID for subject" do
      data_lists.each do |subject, max_id|
        expect(instance.get_current_id(subject:)).to eq(max_id)
      end
    end

    it "uses cache when possible" do
      data_lists.each do |subject, max_id|
        instance.get_current_id(subject:)
      end
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      data_lists.each do |subject, max_id|
        expect(instance.get_current_id(subject:)).to eq(max_id)
      end
    end

    it "raises an error if schema cannot be found" do
      expect { instance.get_current_id(subject: "quack") }
        .to raise_error(described_class::SubjectLookupError)
    end
  end

  describe "#get_schema_id" do
    let(:data_lists) do
      registry_data.flat_map do |subject, data|
        data.map do |version, val|
          [subject, version, val["id"]]
        end
      end
    end

    it "returns version number" do
      data_lists.each do |subject, version, id|
        expect(instance.get_schema_id(subject:, version:)).to eq(id)
      end
    end

    it "uses cache when possible" do
      data_lists.each do |subject, version, id|
        instance.get_schema_id(subject:, version:)
      end
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      data_lists.each do |subject, version, id|
        expect(instance.get_schema_id(subject:, version:)).to eq(id)
      end
    end

    it "raises an error if schema cannot be found" do
      expect { instance.get_schema_id(subject: "quack", version: 1) }
        .to raise_error(described_class::SubjectLookupError)

      expect { instance.get_schema_id(subject: "foo", version: 2000) }
        .to raise_error(described_class::SchemaNotFound)
    end
  end

  describe "#get_schema_json" do
    let(:data_lists) do
      registry_data.flat_map do |subject, data|
        data.map do |version, val|
          [subject, version, val["schema"]]
        end
      end
    end

    it "returns schema json" do
      data_lists.each do |subject, version, schema|
        expect(instance.get_schema_json(subject:, version:)).to eq(schema)
      end
    end

    it "uses cache when possible" do
      data_lists.each do |subject, version, schema|
        instance.get_schema_json(subject:, version:)
      end
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      data_lists.each do |subject, version, schema|
        expect(instance.get_schema_json(subject:, version:)).to eq(schema)
      end
    end

    it "raises an error if schema cannot be found" do
      expect { instance.get_schema_json(subject: "quack", version: 1) }
        .to raise_error(described_class::SubjectLookupError)

      expect { instance.get_schema_json(subject: "foo", version: 2000) }
        .to raise_error(described_class::SchemaNotFound)
    end
  end

  describe "#find_compatible_version" do
    it "finds the newest compatible version for the given data" do
      expect(
        instance.find_compatible_version(
          subject: "bar",
          data: "abc"
        )
      ).to eq(2)

      expect(
        instance.find_compatible_version(
          subject: "foo",
          data: {fooInt: 123}
        )
      ).to eq(1)

      expect(
        instance.find_compatible_version(
          subject: "foo",
          data: {fooInt: 123, fooString: "xyz"}
        )
      ).to eq(3)

      expect(
        instance.find_compatible_version(
          subject: "foo",
          data: {fooInt: 123, fooString: "xyz", fooLong: 99999}
        )
      ).to eq(4)
    end

    it "uses cache when possible" do
      instance.find_compatible_version(subject: "bar", data: "abc")

      registry_data.delete("bar")

      expect(
        instance.find_compatible_version(subject: "bar", data: "abc")
      ).to eq(2)
    end

    it "refetches from upstream when necessary" do
      instance.find_compatible_version(
        subject: "foo",
        data: {fooInt: 123, fooString: "xyz", fooLong: 99999}
      )

      foo_schema_v5 = JSON.generate(
        "type" => "record",
        "name" => "Foo",
        "doc" => "Foo5",
        "fields" => [
          {"name" => "fooInt", "type" => "int"},
          {"name" => "fooString", "type" => "string", "doc" => "B"},
          {"name" => "fooLong", "type" => "long"},
          {"name" => "fooBoolean", "type" => "boolean"}
        ]
      )
      registry_data["foo"][5] = {"id" => 10004, "schema" => foo_schema_v5}

      expect(
        instance.find_compatible_version(
          subject: "foo",
          data: {fooInt: 123, fooString: "xyz", fooLong: 99999, fooBoolean: true}
        )
      ).to eq(5)
    end

    it "raises an error if no compatible version can be found" do
      expect { instance.find_compatible_version(subject: "quack", data: "x") }
        .to raise_error(described_class::SubjectLookupError)

      expect { instance.find_compatible_version(subject: "foo", data: "y") }
        .to raise_error(described_class::SchemaNotFound)
    end

    it "accepts a custom schema_parser and validator" do
      expect(
        instance.find_compatible_version(
          subject: "foo",
          data: {findDoc: "Foo3"},
          schema_parser: ->(string) { JSON.parse(string) },
          validator: ->(schema, data) { schema["doc"] == data[:findDoc] }
        )
      ).to eq(3)
    end
  end

  describe "#preload" do
    let(:data_lists) do
      registry_data.map do |subject, data|
        max_id = data.map { |_version, val| val["id"] }.max
        [subject, max_id]
      end
    end

    it "adds specified subjects to cache" do
      instance.preload(["foo", "bar"])
      registry_data.keys.each { |subject| registry_data.delete(subject) }

      expect(instance.get_current_id(subject: "foo")).to eq(1003)
      expect(instance.get_current_id(subject: "bar")).to eq(2001)
      expect { instance.get_current_id(subject: "baz") }
        .to raise_error(described_class::SubjectLookupError)
    end
  end
end
