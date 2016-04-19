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

# License

MIT
