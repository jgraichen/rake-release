# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'rake-release'
  spec.version       = '1.1.0'
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']
  spec.licenses      = ['MIT']

  spec.summary       = 'Configurable fork of bundlers release tasks.'
  spec.description   = 'Configurable fork of bundlers release tasks.'
  spec.homepage      = 'https://github.com/jgraichen/rake-release'

  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.add_dependency 'bundler', '>= 1.11', '< 3'

  spec.add_development_dependency 'bundler', '>= 1.11', '< 3'
end
