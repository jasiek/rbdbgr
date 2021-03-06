# -*- coding: utf-8 -*-
require_relative '../../base/subsubcmd'

class Debugger::SubSubcommand::SetDebugExcept < Debugger::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP        = 'Set to show execution traceback on debugger command exception'
    MIN_ABBREV  = 'sk'.size
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %w(set debug except)
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, dbg_cmd  = MockDebugger::setup('set')
  debug_cmd      = Debugger::SubSubcommand::SetDebug.new(dbgr.core.processor, 
                                                        dbg_cmd)
  # FIXME: remove the 'join' below
  cmd_name       = Debugger::SubSubcommand::SetDebugExcept::PREFIX.join('')
  debugx_cmd     = Debugger::SubSubcommand::SetDebugExcept.new(dbg_cmd.proc, 
                                                               debug_cmd,
                                                               cmd_name)
  # require_relative '../../../../lib/rbdbgr'
  # dbgr = Debugger.new(:set_restart => true)
  # dbgr.debugger
  debugx_cmd.run([name, 'off'])
  debugx_cmd.run([name])
  debugx_cmd.run([name, 'on'])
end
