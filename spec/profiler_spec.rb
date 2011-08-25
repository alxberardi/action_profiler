require File.expand_path('../helpers/singleton_testing', __FILE__)
require 'action_profiler/profiler'


describe ActionProfiler::Profiler, "when initialized" do
  before do
    ActionProfiler::Profiler.reset_instance
    @profiler = ActionProfiler::Profiler.instance
  end
  
  it "should be disabled" do
    @profiler.enabled.should be_false
  end
end


describe ActionProfiler::Profiler, "when disabled" do
  before do
    ActionProfiler::Profiler.reset_instance
    @profiler = ActionProfiler::Profiler.instance
  end
  
  it "should not profile actions" do
    @profiler.should_not_receive(:profile_action_call)
    @profiler.profile_action { "test" }
    @profiler.action_calls.count.should eql 0
  end
  
  it "should allow enabling" do
    @profiler.enable!
    @profiler.enabled.should be_true
  end
end


describe ActionProfiler::Profiler, "when enabled" do
  before do
    ActionProfiler::Profiler.reset_instance
    @profiler = ActionProfiler::Profiler.instance
    @profiler.enable!
  end
  
  it "should allow profiling actions" do
    @profiler.profile_action(:test_action) { "test" }
    @profiler.action_calls.count.should eql 1
  end
  
  it "should return the correct value returned by the action" do
    @profiler.profile_action(:test_action) { "test" }
    @profiler.action_calls.count.should eql 1
  end
end


describe ActionProfiler::Profiler, "when profiling" do
  before do
    ActionProfiler::Profiler.reset_instance
    @profiler = ActionProfiler::Profiler.instance
    @profiler.enable!
  end
  
  it "should return the value returned by the action" do
    @profiler.profile_action(:test_action) { "test" }.should eql "test"
  end
  
  it "should save the execution time of each action" do
    @profiler.profile_action(:test_action_1) { sleep(0.1) }
    @profiler.profile_action(:test_action_2) { sleep(0.2) }
    @profiler.action_calls[0].duration.round(1).should eql 0.1
    @profiler.action_calls[1].duration.round(1).should eql 0.2
  end
  
  it "should return the total execution time" do
    @profiler.profile_action(:test_action_1) { sleep(0.1) }
    @profiler.profile_action(:test_action_2) { sleep(0.2) }
    @profiler.total_duration.round(1).should eql 0.3
  end
end


describe ActionProfiler::Profiler, "when profiling nested actions" do
  before do
    ActionProfiler::Profiler.reset_instance
    @profiler = ActionProfiler::Profiler.instance
    @profiler.enable!
  end
  
  it "should correctly build the calls structure" do
    @profiler.profile_action(:root_action_1) do
      @profiler.profile_action(:nested_action_1) do
        @profiler.profile_action(:nested_action_2) { "test" }
      end
    end
    @profiler.profile_action(:root_action_2) do
      @profiler.profile_action(:nested_action_3) { "test" }
    end
    @profiler.map_calls(&:action_id).should eql [[:root_action_1, :nested_action_1, :nested_action_2], [:root_action_2, :nested_action_3]]
  end
  
  it "should correctly return the return values of each call" do
    @profiler.profile_action(:root_action) do
      @profiler.profile_action(:test_action_1) { "test1" }
      "root"
    end
    @profiler.profile_action(:test_action_2) { "test2" }
    @profiler.map_calls(&:return_value).should eql [["root", "test1"], ["test2"]]
  end
  
  it "should allow finding action calls by action id" do
    @profiler.profile_action(:root_action_1) do
      @profiler.profile_action(:nested_action_1) do
        @profiler.profile_action(:test_action) { "test" }
      end
    end
    @profiler.profile_action(:root_action_2) do
      @profiler.profile_action(:test_action) { "test" }
    end
    @profiler.find_calls_by_action_id(:test_action).map(&:action_id).should eql [:test_action, :test_action]
  end
  
  it "should return the number of calls for each action" do
    @profiler.profile_action(:root_action_1) do
      @profiler.profile_action(:nested_action) do
        @profiler.profile_action(:test_action) { "test" }
      end
    end
    @profiler.profile_action(:root_action_2) do
      @profiler.profile_action(:nested_action) do
        @profiler.profile_action(:test_action) { "test" }
        @profiler.profile_action(:test_action) { "test" }
      end
    end
    @profiler.action_calls_count(:root_action_1).should eql 1
    @profiler.action_calls_count(:root_action_2).should eql 1
    @profiler.action_calls_count(:nested_action).should eql 2
    @profiler.action_calls_count(:test_action).should eql 3
  end
  
  it "should save the execution time of each action" do
    @profiler.profile_action(:root_action) do
      @profiler.profile_action(:nested_action_1) { sleep(0.1) }
      @profiler.profile_action(:nested_action_2) do
        @profiler.profile_action(:nested_action_2_nested_action_1) { sleep(0.1) }
        @profiler.profile_action(:nested_action_2_nested_action_2) { sleep(0.05) }
        @profiler.profile_action(:nested_action_2_nested_action_3) { sleep(0.05) }
      end
      @profiler.profile_action(:nested_action_3) { sleep(0.3) }
    end
    predicted_durations = {
      :root_action => 0.6, 
      :nested_action_1 => 0.1, 
      :nested_action_2 => 0.2, 
      :nested_action_2_nested_action_1 => 0.1, 
      :nested_action_2_nested_action_2 => 0.05, 
      :nested_action_2_nested_action_3 => 0.05, 
      :nested_action_3 => 0.3}
    @profiler.map_calls.flatten.inject({}) { |hash, action_call| 
      hash[action_call.action_id] = action_call.duration.round(2)
      hash }.should eql predicted_durations
  end
  
  it "should analyse and return execution time percentages for each action" do
    @profiler.profile_action(:root_action) do
      @profiler.profile_action(:nested_action_1) { sleep(0.25) }
      @profiler.profile_action(:nested_action_2) do
        @profiler.profile_action(:nested_action_2_nested_action_1) { sleep(0.20) }
        @profiler.profile_action(:nested_action_2_nested_action_2) { sleep(0.05) }
      end
      @profiler.profile_action(:nested_action_3) { sleep(0.5) }
    end
    predicted_duration_percentages = {
      :root_action => 1.0, 
      :nested_action_1 => 0.25, 
      :nested_action_2 => 0.25, 
      :nested_action_2_nested_action_1 => 0.8, 
      :nested_action_2_nested_action_2 => 0.2, 
      :nested_action_3 => 0.5}
    @profiler.map_calls.flatten.inject({}) { |hash, action_call| 
      hash[action_call.action_id] = action_call.parent_duration_fraction && action_call.parent_duration_fraction.round(2)
      hash }.should eql predicted_duration_percentages
  end
end
