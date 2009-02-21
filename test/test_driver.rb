
$LOAD_PATH.unshift(File.expand_path("#{File.dirname(__FILE__)}/../lib"))

require 'test/unit'
require 'benchmark'
require 'comp_tree'

trace = lambda { |*args|
  STDERR.puts "#{Process.pid}: #{args.inspect}"
}

#set_trace_func(trace)

srand(22)

module CompTree
  module TestCommon
    include Diagnostic

    if ARGV.include?("--bench")
      def separator
        trace ""
        trace "-"*60
      end
    else
      def separator ; end
    end
  end

  module TestBase
    include TestCommon

    def test_1_syntax
      CompTree::Driver.new { |driver|
        driver.define(:area, :width, :height, :offset) { |width, height, offset|
          width*height - offset
        }
        
        driver.define(:width, :border) { |border|
          2 + border
        }
        
        driver.define(:height, :border) { |border|
          3 + border
        }
        
        driver.define(:border) {
          5
        }
        
        driver.define(:offset) {
          7
        }
        
        assert_equal((2 + 5)*(3 + 5) - 7, driver.compute(:area, 6))
      }
    end

    def test_2_syntax
      CompTree::Driver.new { |driver|
        driver.define_area(:width, :height, :offset) { |width, height, offset|
          width*height - offset
        }
        
        driver.define_width(:border) { |border|
          2 + border
        }
        
        driver.define_height(:border) { |border|
          3 + border
        }
        
        driver.define_border {
          5
        }
        
        driver.define_offset {
          7
        }
        
        assert_equal((2 + 5)*(3 + 5) - 7, driver.compute(:area, 6))
      }
    end

    def test_3_syntax
      CompTree::Driver.new { |driver|
        driver.define_area :width, :height, :offset, %{
          width*height - offset
        }
        
        driver.define_width :border, %{
          2 + border
        }
        
        driver.define_height :border, %{
          3 + border
        }
        
        driver.define_border %{
          5
        }
        
        driver.define_offset %{
          7
        }

        assert_equal((2 + 5)*(3 + 5) - 7, driver.compute(:area, 6))
      }
    end

    def test_thread_flood
      (1..200).each { |num_threads|
        CompTree::Driver.new { |driver|
          drain = lambda { |*args|
            1.times { }
          }
          driver.define_a(:b, &drain)
          driver.define_b(&drain)
          driver.compute(:a, num_threads)
        }
      }
    end

    def test_malformed
      CompTree::Driver.new { |driver|
        assert_raise(CompTree::Error::ArgumentError) {
          driver.define {
          }
        }
        assert_raise(CompTree::Error::RedefinitionError) {
          driver.define(:a) {
          }
          driver.define(:a) {
          }
        }
        assert_raise(CompTree::Error::ArgumentError) {
          driver.define(:b) {
          }
          driver.compute(:b, 0)
        }
        assert_raise(CompTree::Error::ArgumentError) {
          driver.define(:c) {
          }
          driver.compute(:c, -1)
        }
      }
    end

    def generate_comp_tree(num_levels, num_children, drain_iterations)
      CompTree::Driver.new { |driver|
        root = :aaa
        last_name = root
        pick_names = lambda { |*args|
          (0..rand(num_children)).map {
            last_name = last_name.to_s.succ.to_sym
          }
        }
        drain = lambda { |*args|
          drain_iterations.times {
          }
        }
        build_tree = lambda { |parent, children, level|
          trace "building #{parent} --> #{children.join(' ')}"
          
          driver.define(parent, *children, &drain)

          if level < num_levels
            children.each { |child|
              build_tree.call(child, pick_names.call, level + 1)
            }
          else
            children.each { |child|
              driver.define(child, &drain)
            }
          end
        }
        build_tree.call(root, pick_names.call, drain_iterations)
      }
    end

    def run_generated_tree(args)
      args[:level_range].each { |num_levels|
        args[:children_range].each { |num_children|
          separator
          trace {%{num_levels}}
          trace {%{num_children}}
          driver = generate_comp_tree(
            num_levels,
            num_children,
            args[:drain_iterations])
          args[:thread_range].each { |threads|
            trace {%{threads}}
            2.times {
              driver.reset(:aaa)
              result = nil
              trace Benchmark.measure {
                result = driver.compute(:aaa, threads)
              }
              assert_equal(result, args[:drain_iterations])
            }
          }
        }
      }
    end

    def test_generated_tree
      run_generated_tree(
        :level_range => 4..4,
        :children_range => 4..4,
        :thread_range => 8..8,
        :drain_iterations => 0
      )
    end
  end

  class Test_Core < Test::Unit::TestCase
    include TestBase
  end
  
  class Test_Drainer < Test::Unit::TestCase
    include TestCommon

    def drain
      5000.times { }
    end
    
    def run_drain(threads)
      CompTree::Driver.new { |driver|
        func = lambda { |*args|
          drain
        }
        driver.define_area(:width, :height, :offset, &func)
        driver.define_width(:border, &func)
        driver.define_height(:border, &func)
        driver.define_border(&func)
        driver.define_offset(&func)
        trace "number of threads: #{threads}"
        trace Benchmark.measure {
          driver.compute(:area, threads)
        }
      }
    end

    def each_drain
      (1..10).each { |threads|
        yield threads
      }
    end

    def test_drain
      separator
      trace "Subrocess test."
      each_drain { |threads|
        run_drain(threads)
      }
    end
  end
end
