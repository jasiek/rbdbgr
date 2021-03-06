# -*- coding: utf-8 -*-
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Debugger::SubSubcommand::InfoRegisters < Debugger::SubSubcommandMgr
  unless defined?(HELP)
    HELP         = 
'List of contents for the registers of the current stack frame.
If a register name given, only only that register is show.

Examples:
  info registers     # show all registers
  info register pc   # show only the pc register
  info reg sp        # show stack pointer register: sp(0)
  info reg sp 1      # show sp(1)
  info reg lfp       # show lfp(0)
'

    MIN_ABBREV   = 'reg'.size  # Note we have "info return"
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    PREFIX       = %w(info registers)
  end

  def run(args)

    args = @parent.last_args
    unavailable_regs = 
      if 'CFUNC' == @proc.frame.type
        %w(inforegisterslfp inforegisterspc) 
      else
        []
      end
    all_regs = @subcmds.subcmds.keys.sort - unavailable_regs
      
    if args.size == 2
      # Form is: "info registers"
      all_regs.sort.each do |subcmd_name|
        @subcmds.subcmds[subcmd_name].run([])
      end
    else
      subcmd_name = args[2]
      key_name    = PREFIX.join('') + subcmd_name
      remain_args = args[3..-1]
      if all_regs.member?(key_name)
        @subcmds.subcmds[key_name].run(remain_args) 
      elsif unavailable_regs.member?(key_name)
        msg("info registers: %s can not be displayed for frame type %s." % 
            [subcmd_name, @proc.frame.type])
      else
        errmsg("info registers: %s is not a valid register name" % subcmd_name)
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  dbgr = MockDebugger::MockDebugger.new
  cmds = dbgr.core.processor.commands
  info_cmd = cmds['info']
  command = Debugger::SubSubcommand::InfoRegisters.new(dbgr.core.processor,
                                                       info_cmd)
  name = File.basename(__FILE__, '.rb')
  cmd_args = ['info', name]
  info_cmd.instance_variable_set('@last_args', cmd_args)
  command.proc.frame_setup(RubyVM::ThreadFrame::current)
  command.run(cmd_args)
end
