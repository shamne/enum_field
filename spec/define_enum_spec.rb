require File.dirname(__FILE__) + '/spec_helper.rb'

describe EnumField::DefineEnum do
  class Colors
    define_enum do |builder|
      builder.member :red
      builder.member :green
    end
  end

  context "defining enums" do
    it "should add method :define_enum to class" do
      class TestClass
      end

      TestClass.should respond_to(:define_enum)
    end

    it "should yield in define_enum" do
      class Checkpoint
        @list = []
        class << self
          attr_accessor :list
        end
      end

      class Test
        define_enum {|builder| Checkpoint.list << :here}
      end

      Checkpoint.list.should == [:here]
    end

    it "should yield a builder in define_enum" do
      lambda {
        class Test
          define_enum do |builder|
            raise unless builder.respond_to?(:member)
          end
        end
      }.should_not raise_error
    end

    it "should reject invalid options" do
      lambda {
        class Test
          define_enum do |builder|
            builder.member :foo, :bar => 1
          end
        end
      }.should raise_error(EnumField::InvalidOptions)
    end

    class NotEnum
    end

    it "should not define enumerated methods in base Class" do
      NotEnum.should_not respond_to(:red)
      Class.should_not respond_to(:red)
    end

    it "should generate instances of class for the enums" do
      Colors.red.should be_instance_of(Colors)
      Colors.green.should be_instance_of(Colors)
    end

    it "should allow creation of simple constants" do
      Colors.red.should_not be_nil
      Colors.green.should_not be_nil
    end

    it "should define incremental ids for created constants" do
      Colors.red.id.should == 1
      Colors.green.id.should == 2
    end

    it "should allow custom objects" do
      class Colors
        define_enum do |b|
          b.member :blue, :object => 'blue'
        end
      end
      Colors.red.should be_instance_of(Colors)
      Colors.blue.should be_instance_of(String)
    end

    it "should allow custom ids" do
      class Colors
        define_enum do |b|
          b.member :yellow, :id => 98765
        end
      end
      Colors.yellow.id.should == 98765
    end

    it "should not accept repeated ids during deffinition" do
      lambda {
        class Colors
          define_enum do |b|
            b.member :brown, :id => 2
          end
        end
      }.should raise_error(EnumField::RepeatedId)
    end

    it "should not accept invalid ids" do
      lambda {
        class Colors
          define_enum do |b|
            b.member :cyan, :id => :hola
          end
        end
      }.should raise_error(EnumField::InvalidId)
    end

    it "should not generate repeated ids" do
      class Sizes
        define_enum do |b|
          b.member :small, :id => 1
          b.member :medium
        end
      end
      Sizes.small.id.should == 1
      Sizes.medium.id.should == 2
    end

    it "should accept both object and id options" do
      class Sizes
        define_enum do |b|
          b.member :large, :id => 10
        end
      end
      Sizes.large.id.should == 10
    end
  end

  context "providing interface" do

    class Positions
      define_enum do |b|
        b.member :top
        b.member :right
        b.member :bottom
        b.member :left, :id => 100
      end
    end

    it "should define all method" do
      Positions.should respond_to(:all)
    end

    it "should return ordered members in all" do
      Positions.all.should == [Positions.top, Positions.right, Positions.bottom, Positions.left]
    end

    it "should provide find_by_id and find working for autogenerated ids" do
      Positions.find_by_id(1).should == Positions.top
      Positions.find(1).should == Positions.top
    end

    it "should provide find_by_id and find working for custom ids" do
      Positions.find_by_id(100).should == Positions.left
    end

    it 'should return nil in find_by_id for nonnexistent ids' do
      Positions.find_by_id(200).should be_nil
    end

    it 'should return throw in find for nonnexistent ids' do
      lambda { Positions.find(200)}.should raise_error(EnumField::ObjectNotFound)
    end

    it "should return first defined element in .first" do
      Positions.first.should == Positions.first
    end

    it "should return last defined element in .first" do
      Positions.last.should == Positions.left
    end
  end

  context "with rich classes" do
    class PhoneType
      def initialize(name)
        @name = name
      end
      attr_reader :name

      define_enum do |b|
        b.member :home,       :object => PhoneType.new('home')
        b.member :commercial, :object => PhoneType.new('commercial')
        b.member :mobile,     :object => PhoneType.new('mobile')
      end
    end

    it "should allow behaviour to be called" do
      PhoneType.home.name.should == 'home'
    end
  end
end
