# -*- coding: utf-8 -*-
require_relative 'base/submgr'

class Debugger::Command::ReloadCommand < Debugger::SubcommandMgr
  ALIASES       = %w(rel)
  HELP = 'Reload information'
  CATEGORY      = 'data'
  NAME          = File.basename(__FILE__, '.rb')
  NEED_STACK    = false
  SHORT_HELP    = 'Reload information'
  def initialize(proc)
    super
  end

end

if __FILE__ == $0
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)

  # require 'rbdbgr'
  # Debugger.debug(:set_restart => true)
  xx = Debugger::Command::ReloadCommand.new(cmd)
  cmd.run([name])
  cmd.run([name, 'command'])
end
