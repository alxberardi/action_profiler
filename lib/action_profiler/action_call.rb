require 'rtree'

module ActionProfiler
  class ActionCall
    
    include RTree::TreeNode
    
    attr_reader :action_id, :action, :action_source, :begin_time, :end_time, :return_value
    
    def initialize(options = nil, &action)
      options ||= {}
      
      @action_id = options[:action_id]
      
      if action
        @action = action
        @action_source = action.source_location
        @action_id ||= self.class.generate_action_id(action)
      end
      
      @children = options[:children] || []
      
      if options[:parent]
        @parent = options[:parent]
        @parent.children << self
      end
      
      @before_call = options[:before_call]
      @after_call = options[:after_call]
    end
    
    
    def self.generate_action_id(action)
      action.source_location.join(':')
    end
    
    
    def duration
      @end_time - @begin_time if executed?
    end
    
    
    def parent_duration_fraction
      if executed?
        if root?
          1
        else
          duration / parent.duration
        end
      end
    end
    
    
    def execute
      @begin_time = Time.now
      @before_call.call(self) if @before_call.is_a?(Proc)
      @return_value = @action && @action.call
      @end_time = Time.now
      @after_call.call(self) if @after_call.is_a?(Proc)
      @return_value
    end
    
    
    def executed?
      @begin_time && @end_time
    end
    
    
    def to_s
      @action_id
    end
    
  end
end