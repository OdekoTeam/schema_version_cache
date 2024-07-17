require "schema_version_cache"

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
  let(:registry_data) do
    {
      "foo" => {
        1 => {"id" => 1000},
        2 => {"id" => 1001},
        3 => {"id" => 1002}
      },
      "bar" => {
        1 => {"id" => 2000},
        2 => {"id" => 2001}
      },
      "baz" => {
        1 => {"id" => 3000},
        2 => {"id" => 3001}
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

      expect(instance.get_current_id(subject: "foo")).to eq(1002)
      expect(instance.get_current_id(subject: "bar")).to eq(2001)
      expect { instance.get_current_id(subject: "baz") }
        .to raise_error(described_class::SubjectLookupError)
    end
  end
end
