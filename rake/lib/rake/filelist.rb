#!/usr/bin/env ruby

module Rake
  class FileList < Array
    def initialize(pattern=nil)
      add_matching(pattern) if pattern
    end

    def add(*filenames)
      filenames.each do |fn|
	case fn
	when Array
	  fn.each { |f| self.add(f) }
	when %r{[*?]}
	  add_matching(fn)
	else
	  self << fn
	end
      end
    end

    def add_matching(*patterns)
      patterns.each do |pattern|
	Dir[pattern].each { |fn| self << fn } if pattern
      end
    end
    private :add_matching

    def to_s
      self.join(' ')
    end
  end
end
