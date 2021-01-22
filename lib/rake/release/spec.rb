# frozen_string_literal: true

require 'forwardable'
require 'uri'

module Rake
  module Release
    class Spec
      extend Forwardable

      EMPTY_STR = ''

      delegate name: :@gemspec
      delegate version: :@gemspec

      attr_reader :base, :gemspec, :gemspec_path, :push_host

      attr_accessor :sign_tag, :namespace, :version_tag

      def initialize(path = nil, namespace: nil, sign_tag: false)
        path = Task.pwd.join(path.to_s).expand_path

        if path.directory?
          @base = path

          gemspecs = Dir[@base.join('*.gemspec')]

          raise 'Unable to determine gemspec file.' if gemspecs.size != 1

          @gemspec_path = Pathname.new gemspecs.first
        else
          @base = path.parent
          @gemspec_path = path
        end

        @gemspec = Bundler.load_gemspec @gemspec_path

        raise 'Cannot load gemspec' unless @gemspec

        @push_host = URI 'https://rubygems.org'

        unless @gemspec.metadata['allowed_push_host'].to_s.empty?
          @push_host = URI @gemspec.metadata['allowed_push_host']
        end

        @sign_tag = sign_tag
        @namespace = namespace
        @version_tag = "v#{version}"

        yield self if block_given?
      end

      def push_host=(value)
        @push_host = URI value
      end

      alias host push_host
      alias host= push_host=

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

      class << self
        def load(*args, &block)
          new(*args, &block)
        rescue RuntimeError
          nil
        end

        def scan(path = Task.pwd.join('*.gemspec'))
          Pathname
            .glob(path)
            .map {|m| Rake::Release::Spec.load(m) }
            .reject(&:nil?)
        end
      end
    end
  end
end
