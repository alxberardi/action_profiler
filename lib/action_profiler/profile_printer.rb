module ActionProfiler
  class ProfilePrinter
    
    DEFAULT_PRECISION = 3
    
    attr_accessor :precision
    
    
    def print_proc
      @print_proc ||= lambda { |string| puts string }
    end
    
    
    def print_proc=(&print_proc)
      @print_proc = print_proc.is_a?(Proc)? print_proc : lambda { |string| puts string }
    end
    
    
    def precision=(precision)
      @precision = precision.to_i < 0 ? 0 : precision.to_i
    end
    
    
    def precision
      @precision ||= DEFAULT_PRECISION
    end
    
    
    def print_call_begin(action_call)
      print_s "#{format_time(action_call.begin_time)} #{format_call(action_call)} - START"
    end
    
    
    def print_call_end(action_call)
      print_s "#{format_time(action_call.end_time)} #{format_call(action_call)} - END (#{format_duration(action_call.duration)}s)"
    end
    
    
    def print_call_tree_analysis(action_call)
      print_s '-' * 80
      action_call.each_node do |c|
        print_call_analysis(c)
      end
      print_s '-' * 80
    end
    
    
    def print_call_analysis(action_call)
      print_s "#{format_call(action_call)} : #{format_duration(action_call.duration)}s (#{(action_call.parent_duration_fraction * 100).round(1)}%)"
    end
    
    
    def print_s(string)
      print_proc.call(string)
    end
    
    
    private
    
    def format_time(time)
      fraction = if precision > 0
        ".%i" % time.usec.to_s[0, precision]
      end

      "#{time.strftime("%Y-%m-%dT%H:%M:%S")}#{fraction}#{time.strftime("%Z")}"
    end
    
    
    def format_call(action_call)
      "#{'  ' * action_call.level} #{action_call.action_id}"
    end
    
    
    def format_duration(duration)
      "%0.#{precision}f" % duration.round(precision)
    end
    
  end
end
