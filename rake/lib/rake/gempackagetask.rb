#!/usr/bin/env ruby

# Define a package task library to aid in the definition of GEM
# packages.

require 'rubygems'
require 'rake'
require 'rake/packagetask'

module Rake

  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.gem"</b>]
  #   Create a Ruby GEM package.
  #
  # Example using a Ruby GEM spec:
  #
  #   spec = Gem::Specification.new do |s|
  #     s.platform = Gem::Platform::RUBY
  #     s.summary = "Ruby based make-like utility."
  #     s.name = 'rake'
  #     s.version = PKG_VERSION
  #     s.requirements << 'none'
  #     s.require_path = 'lib'
  #     s.autorequire = 'rake'
  #     s.files = PKG_FILES
  #     s.description = <<EOF
  #   Rake is a Make-like program implemented in Ruby. Tasks
  #   and dependencies are specified in standard Ruby syntax. 
  #   EOF
  #   end
  #   
  #   Rake::PackageTask.new(spec) do |pkg|
  #     pkg.gem_spec = spec
  #     pkg.need_zip = true
  #     pkg.need_tar = true
  #   end
  #
  class GemPackageTask < PackageTask
    # Ruby GEM spec containing the metadata for this package.  If a
    # GEM spec is provided, then name, version and package_files are
    # automatically determined and don't need to be explicitly
    # provided.  A GEM file will be produced if and only if a GEM spec
    # is supplied.
    attr_accessor :gem_spec

    def initialize(gem)
      init(gem)
      yield self if block_given?
      define if block_given?
    end

    def init(gem)
      super(gem.name, gem.version)
      @gem_spec = gem
      @package_files += gem_spec.files if gem_spec.files
    end

    def define
      super
      task :package => [:gem]
      task :gem => ["#{package_dir}/#{gem_file}"]
      file "#{package_dir}/#{gem_file}" => [package_dir] + @gem_spec.files do
	when_writing("Creating GEM") {
	  Gem::Builder.new(gem_spec).build
	  verbose(false) {
	    mv gem_file, "#{package_dir}/#{gem_file}"
	  }
	}
      end
    end
    
    private
    
    def gem_file
      "#{package_name}.gem"
    end
    
  end
end

    
