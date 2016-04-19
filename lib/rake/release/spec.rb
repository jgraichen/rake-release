require 'forwardable'
require 'uri'

module Rake
  module Release
    class Spec
      extend Forwardable

      EMPTY_STR = ''.freeze

      delegate name: :@gemspec
      delegate version: :@gemspec

      attr_reader :base
      attr_reader :gemspec
      attr_reader :gemspec_path

      def initialize(base: nil, gemspec: nil)
        if gemspec
          @gemspec_path = Pathname.new gemspec

          if base
            @base = Pathname.new base
          else
            @base = @gemspec_path.parent
          end
        else
          @base = Rake::Release.pwd.join(base.to_s).expand_path

          gemspecs = Dir[File.join(@base, "{,*}.gemspec")]

          if gemspecs.size != 1
            raise 'Unable to determine gemspec file.'
          end

          @gemspec_path = Pathname.new gemspecs.first
        end

        @gemspec = Bundler.load_gemspec @gemspec_path

        raise RuntimeError.new 'Cannot load gemspec' unless @gemspec
      end

      def push_host
        @push_host ||= begin
          if @gemspec.metadata['allowed_push_host'].to_s.empty?
            @push_host = URI 'https://rubygems.org'
          else
            @push_host = URI @gemspec.metadata['allowed_push_host']
          end
        end
      end

      def push_host_name
        push_host.host.to_s
      end

      def pkg_path
        @pkg_path ||= base.join 'pkg'
      end

      def pkg_file_name
        @pkg_file_name ||= "#{name}-#{version}.gem"
      end

      def pkg_file_path
        @pkg_file_path ||= pkg_path.join pkg_file_name
      end

      def version_tag
        "v#{version}"
      end

      class << self
        def load(*args, &block)
          new(*args, &block)
        rescue
          nil
        end
      end
    end
  end
end
