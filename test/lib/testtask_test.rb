require 'test/test_helper'
require 'rake/testtask'

class TestTaskTest < Test::Unit::TestCase
  def test_create
    test_task = Rake::TestTask.new(:tx)
  end

  def test_direct_run_has_quoted_paths
    test_task = Rake::TestTask.new(:tx) do |t|
      t.loader = :direct
    end
    assert_match(/-e '.*'/, test_task.run_code)
  end

  def test_testrb_run_has_quoted_paths_on_ruby_182
    test_task = Rake::TestTask.new(:tx) do |t|
      t.loader = :testrb
    end
    flexmock(test_task).should_receive(:ruby_version).and_return('1.8.2')
    assert_match(/^-S testrb +'.*'$/, test_task.run_code)
  end

  def test_testrb_run_has_quoted_paths_on_ruby_186
    test_task = Rake::TestTask.new(:tx) do |t|
      t.loader = :testrb
    end
    flexmock(test_task).should_receive(:ruby_version).and_return('1.8.6')
    assert_match(/^-S testrb +$/, test_task.run_code)
  end

  def test_rake_run_has_quoted_paths
    test_task = Rake::TestTask.new(:tx) do |t|
      t.loader = :rake
    end
    assert_match(/'.*'/, test_task.run_code)
  end
end
