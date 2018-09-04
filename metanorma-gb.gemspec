lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "asciidoctor/gb/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-gb"
  spec.version       = Asciidoctor::Gb::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "metanorma-gb lets you write GB standards in AsciiDoc."
  spec.description   = <<~DESCRIPTION
    metanorma-gb lets you write GB standards (Chinese national standards)
    in AsciiDoc syntax.

    This gem is in active development.

    Formerly known as asciidoctor-gb.
  DESCRIPTION

  spec.homepage      = "https://github.com/riboseinc/metanorma-gb"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "metanorma-iso", "~> 1.0.1"
  spec.add_dependency "isodoc", "~> 0.9.0"
  spec.add_dependency "twitter_cldr"
  spec.add_dependency "gb-agencies", "~> 0.0.1"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "byebug", "~> 9.1"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rubocop", "~> 0.50"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "metanorma"
end
