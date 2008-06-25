require File.dirname(__FILE__) + '/spec_helper'

shared_examples_for "deprecation" do
  before(:all) do
    # ensure deprecation is turned on
    Thrift.send :remove_const, :DEPRECATION
    Thrift.const_set :DEPRECATION, true
  end

  after(:all) do
    # now turn it off again
    # no other specs should want it
    Thrift.send :remove_const, :DEPRECATION
    Thrift.const_set :DEPRECATION, false
  end

  before(:each) do
    Thrift::DeprecationProxy.reset_deprecation_warnings
  end

  def ensure_const_removed(name, &block)
    begin
      block.call
    ensure
      Object.send :remove_const, name if Object.const_defined? name
    end
  end
end

describe 'deprecate!' do
  it_should_behave_like "deprecation"

  def stub_stderr(callstr, offset=1)
    STDERR.should_receive(:puts).with("Warning: calling deprecated method #{callstr}")
    line = caller.first[/\d+$/].to_i + offset
    STDERR.should_receive(:puts).with("  from #{__FILE__}:#{line}")
  end

  it "should work for Module methods" do
    mod = Module.new do
      class << self
        def new
          "new"
        end
        deprecate! :old => :new
      end
    end
    stub_stderr "#{mod.inspect}.old"
    mod.old.should == "new"
  end

  it "should work with Modules that extend themselves" do
    mod = Module.new do
      extend self
      def new
        "new"
      end
      deprecate! :old => :new
    end
    stub_stderr "#{mod.inspect}.old"
    mod.old.should == "new"
  end

  it "should work wtih Class methods" do
    klass = Class.new do
      class << self
        def new
          "new"
        end
        deprecate! :old => :new
      end
    end
    stub_stderr "#{klass.inspect}.old"
    klass.old.should == "new"
  end

  it "should work with Classes that include Modules" do
    mod = Module.new do
      def new
        "new"
      end
      deprecate! :old => :new
    end
    klass = Class.new do
      include mod
    end
    stub_stderr "#{klass.inspect}#old"
    klass.new.old.should == "new"
  end

  it "should work with instance methods" do
    klass = Class.new do
      def new
        "new"
      end
      deprecate! :old => :new
    end
    stub_stderr "#{klass.inspect}#old"
    klass.new.old.should == "new"
  end

  it "should work with multiple method names" do
    klass = Class.new do
      def new1
        "new 1"
      end
      def new2
        "new 2"
      end
      deprecate! :old1 => :new1, :old2 => :new2
    end
    stub_stderr("#{klass.inspect}#old1", 3).ordered
    stub_stderr("#{klass.inspect}#old2", 3).ordered
    inst = klass.new
    inst.old1.should == "new 1"
    inst.old2.should == "new 2"
  end

  it "should only log a message once, even across multiple instances" do
    klass = Class.new do
      def new
        "new"
      end
      deprecate! :old => :new
    end
    stub_stderr("#{klass.inspect}#old").once
    klass.new.old.should == "new"
    klass.new.old.should == "new"
  end

  it "should pass arguments" do
    klass = Class.new do
      def new(a, b)
        "new: #{a + b}"
      end
      deprecate! :old => :new
    end
    stub_stderr("#{klass.inspect}#old")
    klass.new.old(3, 5).should == "new: 8"
  end

  it "should pass blocks" do
    klass = Class.new do
      def new
        "new #{yield}"
      end
      deprecate! :old => :new
    end
    stub_stderr("#{klass.inspect}#old")
    klass.new.old { "block" }.should == "new block"
  end

  it "should not freeze the definition of the new method" do
    klass = Class.new do
      def new
        "new"
      end
      deprecate! :old => :new
    end
    klass.send :define_method, :new do
      "new 2"
    end
    stub_stderr("#{klass.inspect}#old")
    klass.new.old.should == "new 2"
  end

  it "should call the forwarded method in the same context as the original" do
    klass = Class.new do
      def myself
        self
      end
      deprecate! :me => :myself
    end
    inst = klass.new
    stub_stderr("#{klass.inspect}#me")
    inst.me.should eql(inst.myself)
  end
end

describe "deprecate_class!" do
  it_should_behave_like "deprecation"

  def stub_stderr_jruby(klass)
    return unless defined? JRUBY_VERSION
    stub_stderr(klass, nil, caller.first)
  end

  def stub_stderr_mri(klass, offset=1)
    return if defined? JRUBY_VERSION
    stub_stderr(klass, offset, caller.first)
  end

  def stub_stderr(klass, offset=1, called=nil)
    STDERR.should_receive(:puts).with("Warning: class #{klass} is deprecated")
    if offset
      line = (called || caller.first)[/\d+$/].to_i + offset
      STDERR.should_receive(:puts).with("  from #{__FILE__}:#{line}")
    else
      STDERR.should_receive(:puts).with(/^  from #{Regexp.escape(__FILE__)}:/)
    end
  end

  it "should create a new global constant that points to the old one" do
    ensure_const_removed :DeprecationSpecOldClass do
      klass = Class.new do
        def foo
          "foo"
        end
      end
      deprecate_class! :DeprecationSpecOldClass => klass
      stub_stderr(:DeprecationSpecOldClass)
      ::DeprecationSpecOldClass.should eql(klass)
      ::DeprecationSpecOldClass.new.foo.should == "foo"
    end
  end

  it "should create a global constant even from inside a module" do
    ensure_const_removed :DeprecationSpecOldClass do
      klass = nil #define scoping
      Module.new do
        klass = Class.new do
          def foo
            "foo"
          end
        end
        deprecate_class! :DeprecationSpecOldClass => klass
      end
      stub_stderr(:DeprecationSpecOldClass)
      ::DeprecationSpecOldClass.should eql(klass)
      ::DeprecationSpecOldClass.new.foo.should == "foo"
    end
  end

  it "should not prevent the deprecated class from being a superclass" do
    ensure_const_removed :DeprecationSpecOldClass do
      klass = Class.new do
        def foo
          "foo"
        end
      end
      deprecate_class! :DeprecationSpecOldClass => klass
      stub_stderr_jruby(:DeprecationSpecOldClass)
      subklass = Class.new(::DeprecationSpecOldClass) do
        def foo
          "subclass #{super}"
        end
      end
      stub_stderr_mri(:DeprecationSpecOldClass)
      subklass.superclass.should eql(klass)
      subklass.new.foo.should == "subclass foo"
    end
  end

  it "should not bleed info between deprecations" do
    ensure_const_removed :DeprecationSpecOldClass do
      ensure_const_removed :DeprecationSpecOldClass2 do
        klass = Class.new do
          def foo
            "foo"
          end
        end
        deprecate_class! :DeprecationSpecOldClass => klass
        klass2 = Class.new do
          def bar
            "bar"
          end
        end
        deprecate_class! :DeprecationSpecOldClass2 => klass2
        stub_stderr(:DeprecationSpecOldClass)
        ::DeprecationSpecOldClass.new.foo.should == "foo"
        stub_stderr(:DeprecationSpecOldClass2)
        ::DeprecationSpecOldClass2.new.bar.should == "bar"
      end
    end
  end

  it "should work when Object.inherited calls a method on self" do
    ensure_const_removed :DeprecationSpecOldClass do
      old_inherited = Object.method(:inherited)
      begin
        (class << Object;self;end).class_eval do
          define_method :inherited do |cls|
            cls.inspect
            old_inherited.call(cls)
          end
        end
        klass = Class.new do
          def foo
            "foo"
          end
        end
        STDERR.should_receive(:puts).exactly(0).times
        lambda { deprecate_class! :DeprecationSpecOldClass => klass }.should_not raise_error
      ensure
        (class << Object;self;end).class_eval do
          define_method :inherited, old_inherited
        end
      end
    end
  end
end

describe "deprecate_module!" do
  it_should_behave_like "deprecation"

  def stub_stderr_jruby(mod)
    return unless defined? JRUBY_VERSION
    stub_stderr(mod, nil, caller.first)
  end

  def stub_stderr_mri(mod, offset=1)
    return if defined? JRUBY_VERSION
    stub_stderr(mod, offset, caller.first)
  end

  def stub_stderr(mod, offset=1, called=nil)
    STDERR.should_receive(:puts).with("Warning: module #{mod} is deprecated")
    source = Regexp.escape(__FILE__) + ":"
    if offset
      line = (called || caller.first)[/\d+$/].to_i + offset
      source += Regexp.escape(line.to_s)
    else
      source += "\d+"
    end
    STDERR.should_receive(:puts).with(/^  from #{source}(?::in `[^']+')?$/)
  end

  it "should create a new global constant that points to the old one" do
    ensure_const_removed :DeprecationSpecOldModule do
      mod = Module.new do
        def self.foo
          "foo"
        end
      end
      deprecate_module! :DeprecationSpecOldModule => mod
      stub_stderr(:DeprecationSpecOldModule)
      ::DeprecationSpecOldModule.should eql(mod)
      ::DeprecationSpecOldModule.foo.should == "foo"
    end
  end

  it "should create a global constant even from inside a module" do
    ensure_const_removed :DeprecationSpecOldModule do
      mod = nil # scoping
      Module.new do
        mod = Module.new do
          def self.foo
            "foo"
          end
        end
        deprecate_module! :DeprecationSpecOldModule => mod
      end
      stub_stderr(:DeprecationSpecOldModule)
      ::DeprecationSpecOldModule.should eql(mod)
      ::DeprecationSpecOldModule.foo.should == "foo"
    end
  end

  it "should work for modules that extend themselves" do
    ensure_const_removed :DeprecationSpecOldModule do
      mod = Module.new do
        extend self
        def foo
          "foo"
        end
      end
      deprecate_module! :DeprecationSpecOldModule => mod
      stub_stderr(:DeprecationSpecOldModule)
      ::DeprecationSpecOldModule.should eql(mod)
      ::DeprecationSpecOldModule.foo.should == "foo"
    end
  end

  it "should work for modules included in other modules" do
    ensure_const_removed :DeprecationSpecOldModule do
      mod = Module.new do
        def foo
          "foo"
        end
      end
      deprecate_module! :DeprecationSpecOldModule => mod
      stub_stderr_jruby(:DeprecationSpecOldModule)
      mod2 = Module.new do
        class << self
          include ::DeprecationSpecOldModule
        end
      end
      stub_stderr_mri(:DeprecationSpecOldModule)
      mod2.foo.should == "foo"
    end
  end

  it "should work for modules included in classes" do
    ensure_const_removed :DeprecationSpecOldModule do
      mod = Module.new do
        def foo
          "foo"
        end
      end
      deprecate_module! :DeprecationSpecOldModule => mod
      stub_stderr_jruby(:DeprecationSpecOldModule)
      klass = Class.new do
        include ::DeprecationSpecOldModule
      end
      stub_stderr_mri(:DeprecationSpecOldModule)
      klass.new.foo.should == "foo"
    end
  end

  it "should not bleed info between deprecations" do
    ensure_const_removed :DeprecationSpecOldModule do
      ensure_const_removed :DeprecationSpecOldModule2 do
        mod = Module.new do
          def self.foo
            "foo"
          end
        end
        deprecate_module! :DeprecationSpecOldModule => mod
        mod2 = Module.new do
          def self.bar
            "bar"
          end
        end
        deprecate_module! :DeprecationSpecOldModule2 => mod2
        stub_stderr(:DeprecationSpecOldModule)
        ::DeprecationSpecOldModule.foo.should == "foo"
        stub_stderr(:DeprecationSpecOldModule2)
        ::DeprecationSpecOldModule2.bar.should == "bar"
      end
    end
  end

  it "should skip thrift library code when printing caller" do
    klass = Class.new do
      include ThriftStruct
      FIELDS = {
        1 => {:name => "foo", :type => Thrift::Types::STRING}
      }
    end
    stub_stderr('ThriftStruct')
    klass.new(:foo => "foo")
  end
end
