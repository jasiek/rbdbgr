require_relative 'base_cmd'
require_relative File.join(%w(.. .. lib frame))

class Debugger::UpCommand < Debugger::Command

  include Debugger::Frame

  unless defined?(HELP)
    HELP = 
"u(p) [count]

Move the current frame up in the stack trace (to a newer frame). 0 is
the most recent frame. If no count is given, move up 1.

See also 'down' and 'frame'.
"

    CATEGORY     = 'stack'
    MIN_ARGS     = 0  # Need at least this many
    MAX_ARGS     = 1  # Need at most this many
    
    # First entry is the name of the command. Any aliases for the
    # command follow.
    NAME_ALIASES = %w(up u)
    NEED_STACK   = true
    
    SHORT_HELP  = 'Move frame in the direction of the caller of the last-selected frame'
  end
  
  # Run 'down' command. 
  def run(args)

    if not @proc.top_frame
      errmsg("Program has no stack frame set.")
      return false
    end

    if args.size == 1
      # Form is: "down" which means "down 1"
      count = 1
    else
      stack_size = @proc.top_frame.stack_size
      count_str = args[1]
      name_or_id = args[1]
      opts = {
        :msg_on_error => 
        "The 'up' command argument must eval to an integer. Got: %s" % count_str,
        :min_value => -stack_size,
        :max_value => stack_size-1
      }
      count = @proc.get_an_int(count_str, opts)
      return false unless count
    end
    @proc.adjust_frame(-count, false)
    return false
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative File.join(%w(.. .. lib core))
  require 'thread_frame'
  core = Debugger::Core.new()
  proc = Debugger::CmdProcessor.new(core)
  cmd = Debugger::UpCommand.new
  cmd.core = core
  cmd.proc = proc

  cmd.proc.frame_setup(RubyVM::ThreadFrame::current,
                       Thread::current)
  cmd.run %w(up)
  cmd.run %w(up 0)
  puts '=' * 40
  cmd.run %w(up 1)
  puts '=' * 40
  def foo(proc, core, cmd)
    core.frame = RubyVM::ThreadFrame::current
    proc.frame = proc.top_frame = core.frame
    cmd.run(%w(up -1))
  end
  foo(proc, core, cmd)
end
