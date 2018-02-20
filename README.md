# Rake::Release

Customized fork for bundlers gem task helpers.

Automatically detects multiple gemspecs and protect from releasing code not matching git version tag.

## Installation

Add this line to your Gemfile:

```ruby
gem 'rake-release'
```

## Usage

Simply require in Rakefile:

```ruby
require 'rake/release'
```

Check with `rake -D`:

```
rake build
    Build rake-release-0.2.1.gem.gem into the pkg directory.

rake install
    Build and install rake-release-0.2.1.gem into system gems.

rake install:local
    Build and install rake-release-0.2.1.gem into system gems without network access.

rake release[remote]
    Create and push tag v0.2.1, build gem and publish to rubygems.org.
```

### With multiple gemspecs

```
> rake -T
rake lib-alpha:build            # Build lib-alpha-0.6.0.gem.gem into the pkg directory
rake lib-alpha:install          # Build and install lib-alpha-0.6.0.gem into system gems
rake lib-alpha:install:local    # Build and install lib-alpha-0.6.0.gem into system gems without network access
rake lib-alpha:release[remote]  # Create and push tag v0.6.0, build gem and publish to rubygems.org
rake lib-beta:build             # Build lib-beta-0.8.0.gem.gem into the pkg directory
rake lib-beta:install           # Build and install lib-beta-0.8.0.gem into system gems
rake lib-beta:install:local     # Build and install lib-beta-0.8.0.gem into system gems without network access
rake lib-beta:release[remote]   # Create and push tag v0.6.0, build gem and publish to rubygems.org
```

### With tag signing

Enable tag signing by manually loading the task:

```ruby
require 'rake/release/task'

Rake::Release::Task.new do |spec|
  spec.sign_tag = true
end
```

Or with multiple gems:

```ruby
require 'rake/release/task'

Rake::Release::Task.load_all do |spec|
  spec.sign_tag = true
end
```

### Manually set namespace

```ruby
require 'rake/release/task'

Rake::Release::Task.new do |spec|
  spec.namespace = 'client'
end
```

```
> rake -T
rake client:build            # Build rake-release-0.6.0.gem.gem into the pkg directory
rake client:install          # Build and install rake-release-0.6.0.gem into system gems
rake client:install:local    # Build and install rake-release-0.6.0.gem into system gems without network access
rake client:release[remote]  # Create and push tag v0.6.0, build gem and publish to rubygems.org
```

# License

MIT
