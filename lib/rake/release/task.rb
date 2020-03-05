# frozen_string_literal: true

require 'bundler/vendored_thor' unless defined?(Thor)

require 'open3'
require 'bundler'
require 'pathname'
require 'fileutils'

require 'rake/release/spec'

module Rake
  module Release
    class Task
      include Rake::DSL

      def initialize(spec = nil, **kwargs, &block)
        @spec = spec || Rake::Release::Spec.new(spec, **kwargs, &block)

        if @spec.namespace
          send(:namespace, @spec.namespace) { setup }
        else
          setup
        end
      end

      protected

      def setup
        desc "Build #{@spec.pkg_file_name}.gem into the pkg directory."
        task(:build) { build }

        desc "Build and install #{@spec.pkg_file_name} into system gems."
        task(install: [:build]) { install }

        desc "Build and install #{@spec.pkg_file_name} into " \
             'system gems without network access.'
        task('install:local' => [:build]) { install local: true }

        if @spec.sign_tag
          desc "Create, sign and push tag #{@spec.version_tag}, " \
               "build gem and publish to #{@spec.push_host_name}."
        else
          desc "Create and push tag #{@spec.version_tag}, " \
               "build gem and publish to #{@spec.push_host_name}."
        end
        task :release, [:remote] => %w[build release:push release:publish]

        task 'release:guard:clean' do
          guard_clean
        end

        task 'release:guard:tag' do
          guard_tag
        end

        task 'release:push', [:remote] => %w[release:guard:clean] do |_, args|
          tag_version { git_push(args[:remote]) } unless already_tagged?
        end

        task 'release:publish' => %w[release:guard:tag] do
          publish if publish?
        end
      end

      def guard_clean
        return if clean? && committed?

        raise 'There are files that need to be committed first.'
      end

      def guard_tag
        out, = sh! 'git', 'tag', '--points-at', 'HEAD'

        return if out.split("\n").include? @spec.version_tag

        raise "Tag #{@spec.version_tag} does not point to current HEAD. " \
              'Will no release wrong code.'
      end

      def build
        @spec.pkg_path.mkpath

        sh! 'gem', 'build', '-V', @spec.gemspec_path

        @spec.pkg_path.mkpath
        FileUtils.mv @spec.pkg_file_name,
          @spec.pkg_path.join(@spec.pkg_file_name)

        Task.ui.confirm \
          "#{@spec.name} #{@spec.version} built to #{@spec.pkg_path}."
      end

      def install(local: false)
        cmd = %w[gem install] + [@spec.pkg_file_path]
        cmd << '--local' if local

        sh!(*cmd)

        Task.ui.confirm "#{@spec.name} (#{@spec.version}) installed."
      end

      def publish
        cmd = %w[gem push]
        cmd << @spec.pkg_file_path << '--host' << @spec.push_host

        pid = ::Kernel.spawn(*cmd.flatten.map(&:to_s))
        _, status = ::Process.wait2(pid)

        ::Kernel.exit(1) unless status.success?

        Task.ui.confirm "Pushed #{@spec.pkg_file_name} to #{@spec.push_host}"
      end

      def git_clean
        clean? && committed? ||
          raise('There are files that need to be committed first.')
      end

      def clean?
        _, ret = sh 'git', 'diff', '--exit-code'

        ret.zero?
      end

      def committed?
        _, ret = sh 'git', 'diff-index', '--quiet', '--cached', 'HEAD'

        ret.zero?
      end

      def tag_version
        cmd = %w[git tag --annotate]
        cmd << '--sign' if @spec.sign_tag
        cmd << '--message' << "Version #{@spec.version}"
        cmd << @spec.version_tag

        sh!(*cmd)

        Task.ui.confirm "Tagged #{@spec.version_tag}."

        yield if block_given?
      rescue StandardError
        Task.ui.error "Untagging #{@spec.version_tag} due to error."

        sh! 'git', 'tag', '-d', @spec.version_tag

        raise
      end

      def already_tagged?
        out, = sh 'git', 'tag'

        return false unless out.split(/\n/).include? @spec.version_tag

        Task.ui.confirm "Tag #{@spec.version_tag} has already been created."

        true
      end

      def git_push(remote)
        cmd = %w[git push --quiet]

        cmd << remote unless remote.to_s.empty?

        sh!(*cmd)
        sh!(*cmd, '--tags')

        Task.ui.confirm 'Pushed git commits and tags.'
      end

      def publish?
        !%w[n no nil false off 0].include?(ENV['gem_push'].to_s.downcase)
      end

      def sh!(*cmd, **kwargs, &block)
        cmd = cmd.flatten.map(&:to_s)

        out, ret = sh(*cmd, **kwargs, &block)

        if ret != 0
          raise <<~ERROR
            Running `#{cmd}` failed, exit code: #{ret}
              #{out.strip.gsub(/\n/, "\n  ")}
          ERROR
        end

        [out, ret]
      end

      def sh(*cmd, chdir: @spec.base)
        cmd = cmd.flatten.map(&:to_s)

        Task.ui.debug cmd

        Open3.popen2(*cmd, chdir: chdir) do |stdin, out, t|
          stdin.close

          status = t.value

          [out.read, status.exitstatus]
        end
      end

      class << self
        def load_all(dir = pwd)
          specs = Spec.scan dir.join('**/*.gemspec')

          specs.each {|spec| spec.namespace = spec.name } if specs.size > 1

          specs.each(&Proc.new) if block_given?

          if specs.uniq {|s| s.namespace.to_s.strip }.size != specs.size
            raise 'Non distinct release task namespaces'
          end

          specs.each {|spec| Task.new spec }
        end

        def pwd
          @pwd ||= Pathname.new Bundler::SharedHelpers.pwd
        end

        def ui
          @ui ||= Bundler::UI::Shell.new
        end
      end
    end
  end
end
