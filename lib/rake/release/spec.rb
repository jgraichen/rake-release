require 'forwardable'
require 'uri'

require 'rake/release'

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

      def initialize(path, namespace: nil)
        path = Release.pwd.join(path.to_s).expand_path

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

        def scan(path = Release.pwd.join('*.gemspec'))
          Pathname
            .glob(path)
            .map {|path| Rake::Release::Spec.load path }
            .reject {|spec| spec.nil? }
        end
      end
    end
  end
end
