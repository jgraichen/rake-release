require 'bundler/vendored_thor' unless defined?(Thor)

require 'open3'
require 'bundler'
require 'pathname'

require 'rake/release/spec'

module Rake
  module Release
    class Task
      include Rake::DSL

      def initialize(spec = nil, namespace: nil, **kwargs, &block)
        @spec = spec || Rake::Release::Spec.new(**kwargs, &block)

        if namespace
          send(:namespace, namespace) { setup }
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

        desc "Build and install #{@spec.pkg_file_name} into system gems without network access."
        task('install:local' => [:build]) { install local: true }

        str = ''
        str << "Create tag #{@spec.version_tag}, "
        str << "build and push #{@spec.name}-#{@spec.version}.gem to #{@spec.push_host_name}."
        desc str
        task(:release, [:remote] => [
             :build,
             'release:guard_clean',
             'release:source_control_push',
             'release:guard_tag']) do |remote|
          release remote: remote
        end

        task 'release:guard_clean' do
          clean? && committed? || raise('There are files that need to be committed first.')
        end

        task 'release:source_control_push', [:remote] do |_, args|
          tag_version { git_push(args[:remote]) } unless already_tagged?
        end

        task 'release:guard_tag', [:remote] do |_, args|
          out, ret = sh! 'git', 'tag', '--points-at', 'HEAD'

          if not out.split("\n").include? @spec.version_tag
            raise "Tag #{@spec.version_tag} does not point to current HEAD. Cannot release wrong code."
          end
        end
      end

      def build
        @spec.pkg_path.mkpath

        sh! 'gem', 'build', '-V', @spec.gemspec_path, chdir: @spec.pkg_path

        Release.ui.confirm "#{@spec.name} #{@spec.version} built to #{@spec.pkg_path}."
      end

      def install(local: false)
        cmd = %w(gem install) + [@spec.pkg_file_path]
        cmd << '--local' if local

        sh! *cmd

        Release.ui.confirm "#{@spec.name} (#{@spec.version}) installed."
      end

      def release(remote: nil)
        cmd = %w(gem push)
        cmd << @spec.pkg_file_path
        cmd << '--host'
        cmd << @spec.push_host

        sh! *cmd

        Release.ui.confirm "Pushed #{@spec.name} #{@spec.version} to #{@spec.push_host}"
      end

      def git_clean
        clean? && committed? || raise("There are files that need to be committed first.")
      end

      def clean?
        out, ret = sh 'git', 'diff', '--exit-code'

        ret == 0
      end

      def committed?
        out, ret = sh 'git', 'diff-index', '--quiet', '--cached', 'HEAD'

        ret == 0
      end

      def tag_version
        sh! 'git', 'tag', '-a', '-m', "Version #{@spec.version}", @spec.version_tag

        Release.ui.confirm "Tagged #{@spec.version_tag}."

        yield if block_given?
      rescue
        Release.ui.error "Untagging #{@spec.version_tag} due to error."

        sh! 'git', 'tag', '-d', @spec.version_tag

        raise
      end

      def already_tagged?
        out, ret = sh 'git', 'tag'

        unless out.split(/\n/).include? @spec.version_tag
          return false
        end

        Release.ui.confirm "Tag #{@spec.version_tag} has already been created."

        true
      end

      def git_push(remote)
        cmd = %w(git push --quiet)

        if not remote.to_s.empty?
          cmd << remote
        end

        sh! *cmd
        sh! *cmd, '--tags'

        Release.ui.confirm 'Pushed git commits and tags.'
      end

      def sh!(*cmd, **kwargs, &block)
        cmd = cmd.flatten.map(&:to_s)

        out, ret = sh(*cmd, **kwargs, &block)

        if ret != 0
          raise RuntimeError.new <<-EOS.gsub /^\s*\.?/, ''
            Running `#{cmd}` failed, exit code: #{ret}
            .#{out.gsub(/\n/, "\n  ")}
          EOS
        end

        [out, ret]
      end

      def sh(*cmd, chdir: @spec.base, raise_error: true, &block)
        cmd = cmd.flatten.map(&:to_s)

        Release.ui.debug cmd

        Open3.popen2(*cmd, chdir: chdir) do |stdin, out, t|
          stdin.close

          status = t.value

          [out.read, status.exitstatus]
        end
      end
    end
  end
end
