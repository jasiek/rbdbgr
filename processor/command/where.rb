# -*- coding: utf-8 -*-
require_relative 'base/cmd'
class Debugger::Command::WhereCommand < Debugger::Command

  unless defined?(HELP)
    HELP = 
"where [count]

Print a stack trace, with the most recent frame at the top.  With a
positive number, print at most many entries.  With a negative number
print the top entries minus that number.

An arrow indicates the 'current frame'. The current frame determines
the context used for many debugger commands such as expression
evaluation or source-line listing.

Examples:
   where    # Print a full stack trace
   where 2  # Print only the top two entries
   where -1 # Print a stack trace except the initial (least recent) call."

    ALIASES       = %w(bt backtrace)
    CATEGORY      = 'stack'
    MAX_ARGS      = 1  # Need at most this many
    NAME          = File.basename(__FILE__, '.rb')
    NEED_STACK    = true
    SHORT_HELP    = 'Print backtrace of stack frames'
  end

  require_relative '../../app/frame'
  include Debugger::Frame

  # This method runs the command
  def run(args) # :nodoc
    unless @proc.frame
      errmsg 'No frame.'
      return false
    end
    hide_level  = 
      if !settings[:debugstack] && @proc.hidelevels[Thread.current] 
        @proc.hidelevels[Thread.current] 
      else 0 
      end
    stack_size = @proc.top_frame.stack_size - hide_level
    opts = {
      :basename    => @proc.settings[:basename],
      :current_pos => @proc.frame_index,
      :maxstack    => @proc.settings[:maxstack],
      :maxwidth    => @proc.settings[:maxwidth],
      :show_pc     => @proc.settings[:show_pc]
    }
    opts[:count] = 
      if args.size > 1
        opts[:maxstack] = @proc.get_int(args[1], 
                                       :cmdname   => 'where',
                                       :max_value => stack_size)
      else
        stack_size
      end
    return false unless opts[:count]
    # FIXME: Fix Ruby so we don't need this workaround? 
    # See also location.rb
    opts[:class] = @proc.core.hook_arg  if 
      'CFUNC' == @proc.frame.type && 
      @proc.core.hook_arg && @proc.core.event != 'raise'
    print_stack_trace(@proc.top_frame, opts)
  end
end

if __FILE__ == $0
  # Demo it.
  require 'thread_frame'
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)

  def run_cmd(cmd, args)
    cmd.run(args)
    puts '=' * 40
  end

  run_cmd(cmd, [name])

  %w(1 100).each {|count| run_cmd(cmd, [name, count])}
  cmd.settings[:basename] = true
  def foo(cmd, name)
    cmd.proc.frame_setup(RubyVM::ThreadFrame::current)
    run_cmd(cmd, [name])
  end
  foo(cmd, name)
  cmd.settings[:show_pc] = true
  1.times {run_cmd(cmd, [name])}
end
