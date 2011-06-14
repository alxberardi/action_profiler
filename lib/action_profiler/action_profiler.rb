require 'action_profiler/profiler'

module ActionProfiler
  module InstanceMethods

    # Include class methods
    def self.included(base)
      base.extend(ActionProfiler::ClassMethods)
      super
    end
    
    
    def profile_action(action_id = nil, &action)
      self.class.action_profiler.profile_action(action_id, &action)
    end
    
    
    def action_profiler
      self.class.action_profiler
    end

  end
  
  
  module ClassMethods
    
    def enable_action_profiler!
      action_profiler.enabled = action_profiler.print_on_profile = action_profiler.print_analysis = true
    end
    
    
    def disable_action_profiler!
      action_profiler.enabled = false
    end
    
    
    def reset_action_profiler!
      action_profiler.reset!
    end


    def action_profiler
      ActionProfiler::Profiler.instance
    end
    
    
    def profile_instance_methods(*methods)
      methods.each { |m| profile_instance_method(m) }
    end
    
    
    def profile_class_methods(*methods)
      methods.each { |m| profile_class_method(m) }
    end
    
    
    def profile_class_method(method)
      if self.respond_to?(method.to_s, true)
        self.class_eval %Q{
          class << self
            alias_method :_unprofiled_#{method}, :#{method}
            def #{method}(*args)
              self.action_profiler.profile_action("#{self.name}_class.#{method}") do
                self._unprofiled_#{method}(*args)
              end
            end
          end
        }
      end
    end
    
    
    def profile_instance_method(method)
      if method_defined?(method.to_s.to_sym) || private_method_defined?(method.to_s.to_sym)
        alias_method "_unprofiled_#{method}".to_sym, method.to_s.to_sym
        send(:define_method, method.to_s.to_sym, 
          lambda do |*args|
            self.class.action_profiler.profile_action("#{self.class}_instance.#{method}") do
              if args.empty?
                send("_unprofiled_#{method}".to_sym) 
              else
                send("_unprofiled_#{method}".to_sym, *args)
              end
            end
          end)
      end
    end
  
  end 
end
