require 'rake/release/spec'
require 'rake/release/task'

require 'bundler'
require 'pathname'

module Rake
  module Release
    class << self
      def pwd
        @pwd ||= Pathname.new Bundler::SharedHelpers.pwd
      end

      def ui
        @ui ||= Bundler::UI::Shell.new
      end

      def autodetect!
        gemspecs = Pathname.glob pwd.join '{*/*/,*/,}*.gemspec'

        if gemspecs.size == 1
          Rake::Release::Task.new gemspec: gemspecs.first
        else
          gemspecs
          .map {|path| Rake::Release::Spec.load gemspec: path }
          .reject {|spec| spec.nil? }
          .uniq {|spec| spec.name }
          .each do |spec|
            Rake::Release::Task.new spec, namespace: spec.name
          end
        end
      end
    end

    autodetect!
  end
end
