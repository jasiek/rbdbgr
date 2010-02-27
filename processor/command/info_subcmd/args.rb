# -*- coding: utf-8 -*-
require_relative %w(.. base subcmd)
require_relative %w(.. .. .. app frame)

class Debugger::Subcommand::InfoArgs < Debugger::Subcommand
  unless defined?(HELP)
    HELP         = 'Show argument variables of the current stack frame'
    MIN_ABBREV   = 'ar'.size 
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    PREFIX       = %w(info args)
  end

  include Debugger::Frame
  def run(args)
    argc = @proc.frame.argc
    if argc > 0 
      if 'CFUNC' == @proc.frame.type
      (1..argc).each do |i| 
          msg "#{i}: #{@proc.frame.sp(i+2).inspect}"
        end
      else
        param_names = all_param_names(@proc.frame.iseq, false)
        (0..argc-1).each do |i|
          var_name = param_names[i]
          var_value = @proc.safe_rep(@proc.debug_eval_no_errmsg(var_name).inspect)
          msg("#{var_name} = #{var_value}")
        end
      end
      unless %w(call c_call c_return).member?(@proc.core.event)
        msg("Values may have change from the initial call values.")
      end
    else
      msg("No parameters in call.")
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative %w(.. .. mock)
  require_relative %w(.. .. subcmd)
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Debugger::Subcommand::InfoArgs.new(cmd)
  testcmdMgr = Debugger::Subcmd.new(subcommand)

  name = File.basename(__FILE__, '.rb')
  subcommand.summary_help(name)
end
