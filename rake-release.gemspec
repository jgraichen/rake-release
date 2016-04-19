# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'rake-release'
  spec.version       = '0.1.4'
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']
  spec.licenses      = ['MIT']

  spec.summary       = %q{Configurable fork of bundlers release tasks.}
  spec.description   = %q{Configurable fork of bundlers release tasks.}
  spec.homepage      = 'https://github.com/jgraichen/rake-release'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_dependency 'bundler', '~> 1.11'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
end
