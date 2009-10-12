# -*- coding: utf-8 -*-
# A base class for debugger subcommands of subcommands.
#
# Note: don't end classname with Command (capital C) since main
# will think this a command name like QuitCommand 
#                                         ^

# Base Class for Debugger subcommands. We pull in some helper
# functions for command from module cmdfns.

require_relative 'base_cmd'
require_relative 'base_subcmd'

class Debugger

  class SubSubcommand  < Subcommand
    def initialize(cmd, parent)
      @cmd    = cmd

      # By default the name of the subcommand will be the name of the
      # last part of module (e.g. "args" in "info.args" or "basename"
      # in "shows.basename"). However it *is* possible for one to change
      # that -- perhaps one may want to put several subcommands into 
      # a single file. So in those cases, one will have to set @name
      # accordingly by other means.
      @name  = (parent.name.to_s +  my_const(:NAME)).to_sym

      @parent = parent
      @proc   = parent.proc
    end

    def settings
      @parent.settings
    end

    def string_in_show
      my_const(:SHORT_HELP)['Show '.size .. -1].capitalize
    end

    def run_show_bool(what=nil)
      # require_relative %w(.. .. rbdbgr)
      # dbgr = Debugger.new(:set_restart => true)
      # dbgr.debugger(:immediate => true)
      showsize = 'show'.size
      setting = if @name[0..showsize-1] == 'show'
                  @name[showsize..-1]
                else
                  @name
                end
      val = show_onoff(settings[setting])
      what = @name unless what
      msg("%s is %s." % [what, val])
    end

  end

  class ShowBoolSubSubcommand < SubSubcommand
    def run(args)
      run_show_bool(string_in_show)
    end
  end
end
