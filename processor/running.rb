require_relative %w(.. app core)
class Debugger
  class CmdProcessor

    attr_accessor :stop_condition  # String or nil. When not nil
                                   # this has to eval non-nil
                                   # in order to stop.
    attr_accessor :stop_events     # Set or nil. If not nil, only
                                   # events in this set will be
                                   # considered for stopping. This is
                                   # like core.step_events (which
                                   # could be used instead), but it is
                                   # a set of event names rather than
                                   # a bitmask and it is intended to
                                   # be more temporarily changed via
                                   # "step>" or "step!" commands.
    attr_accessor :to_method
                                  
    # Does whatever needs to be done to set to continue program
    # execution.
    # FIXME: turn line_number into a condition.
    def continue
      @next_level      = 32000 # I'm guessing the stack size can't
                               # ever reach this
      @next_thread     = nil
      @core.step_count = -1    # No more event stepping
      @leave_cmd_loop  = true  # Break out of the processor command loop.
    end

    # Does whatever needs to be done to set to "next" program
    # execution.
    def finish(level_count=0, opts={})
      step(0, opts)
      @next_level      = @frame.stack_size - level_count
      @next_thread     = Thread.current
      @stop_events     = Set.new(%w(return))
    end
    # Does whatever needs to be done to set to "next" program
    # execution.
    def next(step_count=1, opts={})
      step(step_count, opts)
      @next_level      = @top_frame.stack_size
      @next_thread     = Thread.current
    end

    # Does whatever needs to be done to set to step program
    # execution.
    def step(step_count=1, opts={}, condition=nil)
      continue
      @core.step_count = step_count
      @different_pos   = opts[:different_pos] if 
        opts.keys.member?(:different_pos)
      @stop_condition  = condition
      @stop_events     = opts[:stop_events]   if 
        opts.keys.member?(:stop_events)
      @to_method       = opts[:to_method]
    end

    def quit(cmd='quit')
      @next_level      = 32000 # I'm guessing the stack size can't
                               # ever reach this
      @next_thread     = nil
      @core.step_count = -1    # No more event stepping
      @leave_cmd_loop  = true  # Break out of the processor command loop.
      @settings[:autoirb] = false
      @cmdloop_prehooks.delete_by_name('autoirb')
      @commands['quit'].run([cmd])
    end

    def parse_next_step_suffix(step_cmd)
      opts = {}
      case step_cmd[-1..-1]
      when '-'
        opts[:different_pos] = false
      when '+'
        opts[:different_pos] = 'nostack'
      when '='
        opts[:different_pos] = true
      when '!'
        opts[:stop_events] = Set.new(%w(raise))
      when '<'
        opts[:stop_events] = Set.new(%w(c-return return))
      when '>'
        opts[:stop_events] = Set.new(%w(c-call call))
        if step_cmd.size > 1 && step_cmd[-2..-2] == '<'
          opts[:stop_events] = Set.new(%w(c-call c-return call return))
        else
          opts[:stop_events] = Set.new(%w(c-call call))
        end
      end
      return opts
    end

    def running_initialize
      @stop_condition  = nil
      @stop_events     = nil
      @to_method       = nil
    end

    def stepping_skip?
      
      return true if @core.step_count < 0

      if @settings[:'debugskip']
        puts "diff: #{@different_pos}, event : #{@core.event}, #{@stop_events.inspect}" 
        puts "nl  : #{@next_level},    ssize : #{@stack_size}" 
        puts "nt  : #{@next_thread},   thread: #{Thread.current}" 
      end

      # I think these events are important enough event that we always want
      # to stop on them.
      # return false if UNMASKABLE_EVENTS.member?(@core.event)

      return true if 
        !frame || (@next_level < @frame.stack_size &&
                   Thread.current == @next_thread)

      new_pos = [@frame.source_container, frame_line,
                 @stack_size, @current_thread]

      skip_val = @stop_events && !@stop_events.member?(@core.event)

      if @settings[:'debugskip']
        puts "skip: #{skip_val.inspect}, last: #{@last_pos}, new: #{new_pos}" 
      end

      @last_pos[2] = new_pos[2] if 'nostack' == @different_pos
      unless skip_val
        condition_met = 
          if @stop_condition
            puts 'stop_cond' if @settings[:'debugskip']
            debug_eval_no_errmsg(@stop_condition)
          elsif @to_method
            puts "method #{@frame.method} #{@to_method}" if 
              @settings[:'debugskip']
            @frame.method == @to_method
          else
            puts 'uncond' if @settings[:'debugskip']
            true
          end
          
        puts("condition_met: #{condition_met}, last: #{@last_pos}, " +
             "new: #{new_pos}, different #{@different_pos.inspect}") if 
          @settings[:'debugskip']
        skip_val = (@last_pos == new_pos) && @different_pos || !condition_met
      end

      @last_pos = new_pos if !@stop_events || @stop_events.member?(@core.event)

      unless skip_val
        # Set up the default values for the
        # next time we consider skipping.
        @different_pos = @settings[:different]
        @stop_events   = nil
      end

      return skip_val
    end

  end
end
