# -*- coding: utf-8 -*-
require 'tempfile'
require 'linecache'
require_relative '../../base/subsubcmd'
require_relative '../substitute'

class Debugger::SubSubcommand::SetSubstituteString < Debugger::SubSubcommand
  unless defined?(HELP)
    HELP         = 
'set substitute FROM-FILE STRING-VAR

Use the contents of string variable STRING-VAR as the source text for
FROM-FILE.  If a substitution rule was previously set for FROM-FILE,
the old rule is replaced by the new one.

If "." is given for FROM_FILE, the current instruction sequence name is used.'
    MIN_ABBREV   = 'st'.size  
    MAX_ARGS     = 2
    NAME         = File.basename(__FILE__, '.rb')
    SHORT_HELP   = 'Use STRING in place of an filename'
    PREFIX       = %w(set substitute string)
  end

  def run(args)
    if args.size != 3
      errmsg "This command needs 2 arguments, got #{args.size-1}."
      return
    end
    from_path = 
      if '.' == args[1]
        @proc.frame.iseq.source_container[1]
      else
        from_path = args[1]
      end
    
    to_str = args[2]
    val = @proc.debug_eval_no_errmsg(to_str)

    if val
      tempfile = Tempfile.new(["#{from_path}-#{to_str}-", '.rb'])
      tempfile.open.puts(val)
      @proc.remap_container[['string', from_path]] = ['file', tempfile.path]
      tempfile.close
      LineCache::cache(tempfile.path)
    else
      errmsg "Can't get value for #{to_str}"
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '/../../../mock'
  require_relative '../../../subcmd'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, set_cmd = MockDebugger::setup('set')
  testcmdMgr = Debugger::Subcmd.new(set_cmd)
  cmd_name   = Debugger::SubSubcommand::SetSubstituteString::PREFIX.join('')
  setx_cmd   = Debugger::SubSubcommand::SetSubstituteString.new(set_cmd.proc, 
                                                                set_cmd,
                                                                cmd_name)
  # require_relative '../../../../lib/rbdbgr'
  # dbgr = Debugger.new(:set_restart => true)
  # dbgr.debugger
  setx_cmd.run([])

  # name = File.basename(__FILE__, '.rb')
  # subcommand.summary_help(name)
end
