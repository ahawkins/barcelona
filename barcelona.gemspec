# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "barcelona"
  spec.version       = "0.1.0"
  spec.authors       = ["ahawkins"]
  spec.email         = ["adam@hawkins.io"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "http_router"
  spec.add_dependency "tnt"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rack-test"
end
