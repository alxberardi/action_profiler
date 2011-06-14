require File.expand_path('../helpers/singleton_testing', __FILE__)
require 'action_profiler/action_profiler'

class Tester
  
  def self.profiled_class_method(arg = 'test')
    sleep(0.1)
    "profiled_class_method - #{arg}"
  end
    
  def self.unprofiled_class_method(arg = 'test')
    "unprofiled_class_method - #{arg}"
  end
  
  def profiled_instance_method(arg = 'test')
    3.times { |i| test_method(arg, i) }
  end
    
  def unprofiled_instance_method(arg = 'test')
    "unprofiled_instance_method - #{arg}"
  end
    
   
  private
    
  def test_method_1(arg)
    sleep(0.1)
    "test_method_1 - #{arg}"
  end
    
  def test_method_2(arg)
    sleep(0.5)
    "test_method_2 - #{arg}"
  end
    
  def test_method_3(arg)
    sleep(0.4)
    "test_method_3 - #{arg}"
  end
  
  def test_method(arg, method_index)
    self.send("test_method_#{method_index + 1}".to_sym, arg)
  end
  
  include ActionProfiler::InstanceMethods
  profile_instance_methods  :profiled_instance_method, :test_method_1, :test_method_2, :test_method_3
  profile_class_methods     :profiled_class_method
  
end


describe ActionProfiler, "when included in a class" do

  it "should allow enabling the profiler" do
    lambda { Tester.enable_action_profiler! }.should_not raise_exception
    Tester.action_profiler.enabled.should be_true
    Tester.profiled_class_method
    Tester.action_profiler.action_calls.should_not be_empty
  end
  
  it "should allow disabling the profiler" do
    lambda { Tester.disable_action_profiler! }.should_not raise_exception
    Tester.action_profiler.enabled.should be_false
    Tester.profiled_class_method
    Tester.action_profiler.action_calls.should be_empty
  end
  
  it "should allow resetting the profiler" do
    Tester.enable_action_profiler!
    Tester.profiled_class_method
    Tester.action_profiler.action_calls.should_not be_empty
    lambda { Tester.reset_action_profiler! }.should_not raise_exception
    Tester.action_profiler.action_calls.should be_empty
  end
  
  after do
   Tester.reset_action_profiler!
   Tester.disable_action_profiler!
  end
end


describe ActionProfiler, "when profiling class methods" do
  before(:all) do
    Tester.enable_action_profiler!
  end
  
  it "should profile class methods which have been included in profiling" do
    Tester.profiled_class_method
    Tester.action_profiler.action_calls.count.should eql 1
    Tester.action_profiler.total_duration.round(1).should eql 0.1
  end
  
  it "should not profile class methods which have not been included in profiling" do
    Tester.unprofiled_class_method
    Tester.action_profiler.action_calls.count.should eql 0
  end
  
  after do
    Tester.reset_action_profiler!
  end
end


describe ActionProfiler, "when profiling instance methods" do
  before(:all) do
    Tester.enable_action_profiler!
  end
  
  before(:each) do
    @tester = Tester.new
  end
  
  it "should profile instance methods which have been included in profiling" do
    @tester.profiled_instance_method
    @tester.action_profiler.map_calls(&:action_id).should eql [
      [ "Tester_instance.profiled_instance_method", 
        "Tester_instance.test_method_1", 
        "Tester_instance.test_method_2", 
        "Tester_instance.test_method_3"]]
  end
  
  it "should not profile instance methods which have not been included in profiling" do
    @tester.unprofiled_instance_method
    @tester.action_profiler.action_calls.count.should eql 0
  end
  
  after do
    Tester.reset_action_profiler!
  end
end
  
