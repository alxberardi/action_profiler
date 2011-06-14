require 'action_profiler/action_call'
require 'action_profiler/profile_printer'

module ActionProfiler
  class Profiler
    
    include Singleton

    attr_accessor :enabled, :print_on_profile, :print_analysis
    attr_reader :action_calls, :current_action

    
    def initialize
      reset!
      @printer = ActionProfiler::ProfilePrinter.new
    end
    
    
    def print_proc
      @printer.print_proc
    end
    
    
    def print_proc=(&print_proc)
      @printer.print_proc(&print_proc)
    end
    

    def profile_action(action_id = nil, &action)
      return unless action
      if enabled
        profile_action_call(action_id, &action)
      else
        action.call
      end
    end
    
    
    def each_call(&block)
      @action_calls.each do |action_call|
        action_call.each_node(&block)
      end
    end
    
    
    def map_calls(&block)
      @action_calls.map do |action_call|
        action_call.map(&block)
      end
    end
    
    
    def find_call(&condition)
      @action_calls.each do |root_action_call|
        found = root_action_call.find_node(&condition)
        return found if found
      end
      nil
    end
    
    
    def find_calls(&condition)
      @action_calls.map do |root_action_call|
        root_action_call.find_all_nodes(&condition)
      end.flatten.compact
    end
    
    
    def find_calls_by_action_id(action_id)
      find_calls { |action_call| action_call.action_id == action_id }
    end
    
    
    def total_duration
      @action_calls.inject(0) { |sum, call| sum + call.duration }
    end
    
    
    def action_total_duration(action_id)
      find_calls_by_action_id(action_id).inject(0) { |sum, call| sum + call.duration }
    end
    
    
    def action_calls_count(action_id)
      find_calls_by_action_id(action_id).count
    end
    
    
    def analyse
      @action_calls.each do |action_call|
        @printer.print_call_tree_analysis(action_call)
      end
    end
    
    
    def enable!
      @enabled = true
    end
    
    
    def disable!
      @enabled = false
    end


    def reset!
      @action_calls = []
    end
    
    
    def precision=(precision)
      @printer.precision = precision
    end
    
    
    def precision
      @printer.precision
    end
    
    
    
    protected
    
    
    def profile_action_call(action_id = nil, &action)
      @current_action = ActionProfiler::ActionCall.new(
        :action_id => action_id,
        :parent => @current_action,
        :before_call  => lambda { |action_call| before_call(action_call) },
        :after_call   => lambda { |action_call| after_call(action_call) },
        &action
      )
      @action_calls << @current_action if @current_action.root?
      return_value = @current_action.execute
      @current_action = @current_action.parent
      return_value
    end
    
    
    def before_call(action_call)
      @printer.print_call_begin(action_call) if print_on_profile
    end
    
    
    def after_call(action_call)
      @printer.print_call_end(action_call) if print_on_profile
      @printer.print_call_tree_analysis(action_call) if action_call.root? && print_analysis
    end

  end
end
