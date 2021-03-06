require 'irb'
require_relative 'base/cmd'
require_relative '../../app/irb'
class Debugger::Command::IRBCommand < Debugger::Command

  unless defined?(HELP)
    HELP = 
"          irb [-d]\tstarts an Interactive Ruby (IRB) session.

If -d is added you can get access to debugger frame the global variables
$rbdbgr_frame and $rbdbgr_cmdproc. 

irb is extended with methods 'cont', 'dbgr', 'n', and, 'q', 'step' which 
run the corresponding debugger commands. 

To issue a debugger command, inside irb nested inside a debugger use
'dbgr'. For example:

  dbgr %%w(info program)
  dbgr('info', 'program') # Same as above
  dbgr 'info program'     # Single quoted string also works

But arguments have to be quoted because irb will evaluate them:

  dbgr info program     # wrong!
  dbgr info, program    # wrong!
  dbgr(info, program)   # What I say 3 times is wrong!
"

    CATEGORY     = 'support'
    MAX_ARGS     = 1  # Need at most this many
    NAME         = File.basename(__FILE__, '.rb')
    SHORT_HELP  = 'Run interactive Ruby session irb as a command subshell'
  end

  # This method runs the command
  def run(args) # :nodoc
    add_debugging = 
      if args.size > 1
        '-d' == args[1]
      else
        false
      end

    # unless @state.interface.kind_of?(LocalInterface)
    #   print "Command is available only in local mode.\n"
    #   throw :debug_error
    # end

    save_trap = trap('SIGINT') do
      throw :IRB_EXIT, :cont if $rbdbgr_in_irb
    end

    $rbdbgr = @proc.core.dbgr 
    if add_debugging
      $rbdbgr_cmdproc  = @proc
      $rbdbgr_frame    = @proc.frame
    end
    $rbdbgr_in_irb = true
    $rbdbgr_irb_statements = nil
    $rbdbgr_command = nil

    conf = {:BACK_TRACE_LIMIT => settings[:maxstack]}
    cont = IRB.start_session(@proc.frame.binding, @proc, conf)
    trap('SIGINT', save_trap) # Restore old trap

    back_trace_limit = IRB.CurrentContext.back_trace_limit
    if settings[:maxstack] !=  back_trace_limit
      msg("\nSetting debugger's BACK_TRACE_LIMIT (%d) to match irb's last setting (%d)" % 
          [settings[:maxstack], back_trace_limit])
      settings[:maxstack]= IRB.CurrentContext.back_trace_limit
    end

    case cont
    when :continue
      @proc.continue
    when :finish
      @proc.finish 
    when :next
      @proc.next # (1, {})
    when :quit
      @proc.quit
    when :step
      @proc.step # (1, {})
    else
      @proc.print_location
    end
  ensure
    $rbdbgr_in_irb = false
    # restore old trap if any
    trap('SIGINT', save_trap) if save_trap
   end
end

if __FILE__ == $0
  require 'thread_frame'
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
  # Get an IRB session -- the hard way :-)
  cmd.run([name]) if ARGV.size > 0
end
