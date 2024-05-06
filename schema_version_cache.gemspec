Gem::Specification.new do |s|
  s.name = "schema_version_cache"
  s.version = "1.0.0"
  s.summary = "Schema version cache"
  s.description = "Schema version cache, e.g. for Avro schemas"
  s.authors = ["Odeko"]
  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|spec|ci)/|\.(?:git))})
    end
  end
  s.license = "Nonstandard"
  s.add_development_dependency("rake", "~> 13.0")
  s.add_development_dependency("rspec", "~> 3.0")
  s.add_development_dependency("standard", "~> 1.3")
end
