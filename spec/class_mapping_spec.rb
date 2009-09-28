require File.dirname(__FILE__) + '/spec_helper.rb'

describe AMF::ClassMapping do
  before(:all) do
    class RubyClass
      attr_accessor :prop_a
      attr_accessor :prop_b
      attr_accessor :prop_c
    end
  end

  before :each do
    @mapper = AMF::ClassMapping.new
    @mapper.define do |m|
      m.map :as => 'ASClass', :ruby => 'RubyClass'
    end
  end

  it "should return AS class name for ruby objects" do
    @mapper.get_as_class_name(RubyClass.new).should == 'ASClass'
    @mapper.get_as_class_name('RubyClass').should == 'ASClass'
  end

  it "should allow config modification" do
    @mapper.define do |m|
      m.map :as => 'SecondClass', :ruby => 'RubyClass'
    end
    @mapper.get_as_class_name(RubyClass.new).should == 'SecondClass'
  end

  describe "ruby object generator" do
    it "should instantiate a ruby class" do
      @mapper.get_ruby_obj('ASClass').should be_a(RubyClass)
    end

    it "should properly instantiate namespaced classes" do
      module ANamespace; class TestRubyClass; end; end
      @mapper.define {|m| m.map :as => 'ASClass', :ruby => 'ANamespace::TestRubyClass'}
      @mapper.get_ruby_obj('ASClass').should be_a(ANamespace::TestRubyClass)
    end

    it "should return a hash with original type if not mapped" do
      obj = @mapper.get_ruby_obj('UnmappedClass')
      obj.should be_a(AMF::TypedHash)
      obj.original_type.should == 'UnmappedClass'
    end
  end

  describe "ruby object populator" do
    it "should populate a ruby class" do
      obj = @mapper.populate_ruby_obj RubyClass.new, {:prop_a => 'Data'}
      obj.prop_a.should == 'Data'
    end

    it "should populate a typed hash" do
      obj = @mapper.populate_ruby_obj AMF::TypedHash.new('UnmappedClass'), {:prop_a => 'Data'}
      obj['prop_a'].should == 'Data'
    end

    it "should allow custom populators" do
      class CustomPopulator
        def can_handle? obj
          true
        end
        def populate obj, props
          obj[:populated] = true
          obj.merge! props
        end
      end

      @mapper.object_populators << CustomPopulator.new
      obj = @mapper.populate_ruby_obj({}, {:prop_a => 'Data'})
      obj[:populated].should == true
      obj[:prop_a].should == 'Data'
    end
  end

  it "should extract props for serialization" do
    obj = RubyClass.new
    obj.prop_a = 'Test A'
    obj.prop_b = 'Test B'

    hash = @mapper.props_for_serialization obj
    hash.should == {'prop_a' => 'Test A', 'prop_b' => 'Test B', 'prop_c' => nil}
  end
end