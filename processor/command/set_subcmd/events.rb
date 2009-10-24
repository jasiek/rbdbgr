# -*- coding: utf-8 -*-
require 'trace'
require_relative %w(.. base subcmd)

class Debugger::Subcommand::SetEvents < Debugger::Subcommand
  unless defined?(HELP)
    HELP         = 'Set trace events we may stop on'
    MIN_ABBREV   = 'ev'.size
    NAME         = File.basename(__FILE__, '.rb')
  end

  def run(events)
    unless events.empty?
      events.each {|event| event.chomp!(',')}
      bitmask, bad_events = Trace.events2bitmask(events)
      unless bad_events.empty?
        errmsg("Event names unrecognized/ignored: %s" % bad_events.join(', '))
      end
      @proc.core.step_events = bitmask
    end
    @proc.commands['show'].subcmds.subcmds[:events].run('events')
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative %w(.. .. mock)
  require_relative %w(.. .. subcmd)
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, cmd = MockDebugger::setup('set')
  subcommand = Debugger::Subcommand::SetEvents.new(cmd)
  testcmdMgr = Debugger::Subcmd.new(subcommand)

  name = File.basename(__FILE__, '.rb')
  subcommand.summary_help(name)
  puts
  subcommand.run([])
  [%w(call line foo), %w(insn, c_call, c_return,)].each do |events|
    subcommand.run(events)
    puts 'bitmask: %09b, events: %s ' % [dbgr.core.step_events, events.inspect]
  end
end
