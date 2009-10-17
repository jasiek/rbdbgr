#!/usr/bin/env ruby
require 'test/unit'
require_relative %w(.. .. lib brkpt)
require 'thread_frame'

class TestLibBrkpt < Test::Unit::TestCase

  def test_basic
    tf = RubyVM::ThreadFrame.current
    iseq = tf.iseq
    b1 = Breakpoint.new(false, 0, iseq)
    assert_equal(false, b1.temp?)
    assert_equal(b1.source_container, tf.source_container)
    assert_raises TypeError do 
      Breakpoint.new(true, iseq.iseq_size, iseq)
    end
    assert_raises TypeError do 
      Breakpoint.new(false, 0, 5)
    end
  end
end
