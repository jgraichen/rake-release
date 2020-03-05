# frozen_string_literal: true

require 'rake/release/spec'
require 'rake/release/task'

require 'bundler'
require 'pathname'

module Rake
  module Release
    class << self
      def autodetect!
        specs = Spec.scan Task.pwd.join '{*/*/,*/,}*.gemspec'
        specs.uniq!(&:name)

        if specs.size == 1
          Rake::Release::Task.new specs.first
        else
          specs.each do |spec|
            Rake::Release::Task.new spec, namespace: spec.name
          end
        end
      end
    end

    autodetect!
  end
end
