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
        specs = Spec.scan pwd.join '{*/*/,*/,}*.gemspec'
        specs.uniq! {|spec| spec.name }

        if specs.size == 1
          Task.new specs.first
        else
          specs.each do |spec|
            Task.new spec, namespace: spec.name
          end
        end
      end
    end

    autodetect!
  end
end
