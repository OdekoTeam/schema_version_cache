Gem::Specification.new do |s|
  s.name = "schema_version_cache"
  s.version = "1.2.1"
  s.summary = "Schema version cache"
  s.description = "Schema version cache, e.g. for Avro schemas"
  s.homepage = "https://github.com/OdekoTeam/schema_version_cache"
  s.authors = ["Odeko Developers"]
  s.files = Dir.chdir(__dir__) do
    Dir["LICENSE", "README.md", "lib/**/*.rb", "rbi/**/*.rbi"]
  end
  s.license = "Apache-2.0"
  s.required_ruby_version = ">= 3.1.0"
  s.add_dependency("avro", "~> 1.11")
  s.add_development_dependency("rake", "~> 13.0")
  s.add_development_dependency("rspec", "~> 3.0")
  s.add_development_dependency("standard", "~> 1.3")
  s.add_development_dependency("sorbet", "~> 0.5")
  s.add_development_dependency("tapioca", "~> 0.13")
end
