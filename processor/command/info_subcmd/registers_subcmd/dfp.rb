# -*- coding: utf-8 -*-
require_relative '../../base/subsubcmd'
require_relative 'helper'

class Debugger::Subcommand::InfoRegistersDfp < Debugger::SubSubcommand
  unless defined?(HELP)
    HELP         = 'Show the value of the VM dynamic frame pointer (DFP)'
    MIN_ABBREV   = 'lf'.size
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    PREFIX       = %w(info registers dfp)
  end

  include Registers
  def run(args)
    register_array_index(PREFIX[-1], args)
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, info_cmd = MockDebugger::setup('info')
  testcmdMgr = Debugger::Subcmd.new(info_cmd)
  cmd_name   = Debugger::SubSubcommand::InfoRegistersDfp::PREFIX.join('')
  infox_cmd  = Debugger::SubSubcommand::InfoRegistersDfp.new(info_cmd.proc,
                                                             info_cmd,
                                                             cmd_name)
  infox_cmd.run([])

  # name = File.basename(__FILE__, '.rb')
  # subcommand.summary_help(name)
end
