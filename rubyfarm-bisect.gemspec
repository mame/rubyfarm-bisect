Gem::Specification.new do |spec|
  spec.name          = "rubyfarm-bisect"
  spec.version       = "1.0.1"
  spec.authors       = ["Yusuke Endoh"]
  spec.email         = ["mame@ruby-lang.org"]

  spec.summary       = %q{"git bisect" ruby without compilation trouble}
  spec.description   = %q{rubyfarm-bisect allows you to do "git bisect" MRI revisions without compilation.}
  spec.homepage      = "https://github.com/mame/rubyfarm-bisect"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
