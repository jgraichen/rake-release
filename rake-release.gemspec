# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'rake-release'
  spec.version       = '0.3.0'
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']
  spec.licenses      = ['MIT']

  spec.summary       = %q{Configurable fork of bundlers release tasks.}
  spec.description   = %q{Configurable fork of bundlers release tasks.}
  spec.homepage      = 'https://github.com/jgraichen/rake-release'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_dependency 'bundler', '~> 1.11'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
end
