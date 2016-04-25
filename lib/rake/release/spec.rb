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

      attr_accessor :namespace
      attr_accessor :push_host

      def initialize(path, namespace: nil)
        path = Task.pwd.join(path.to_s).expand_path

        if path.directory?
          @base = path

          gemspecs = Dir[@base.join('*.gemspec')]

          if gemspecs.size != 1
            raise 'Unable to determine gemspec file.'
          end

          @gemspec_path = Pathname.new gemspecs.first
        else
          @base = path.parent
          @gemspec_path = path
        end

        @gemspec = Bundler.load_gemspec @gemspec_path

        raise RuntimeError.new 'Cannot load gemspec' unless @gemspec

        @push_host = URI 'https://rubygems.org'

        unless @gemspec.metadata['allowed_push_host'].to_s.empty?
          @push_host = URI @gemspec.metadata['allowed_push_host']
        end
      end

      def push_host=(value)
        @push_host = URI value
      end

      alias_method :host, :push_host
      alias_method :host=, :push_host=

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
        rescue RuntimeError
          nil
        end

        def scan(path = Task.pwd.join('*.gemspec'))
          Pathname
            .glob(path)
            .map {|path| Rake::Release::Spec.load path }
            .reject {|spec| spec.nil? }
        end
      end
    end
  end
end
