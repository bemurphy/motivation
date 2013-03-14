require "motivation/version"
require "delegate"

module Motivation

  def self.included(base)
    base.send(:attr_accessor, :subject)
    base.extend ClassMethods
  end

  def initialize(subject)
    @subject = subject
  end

  def applies?
    true
  end

  def unwrapped_checks
    self.class.checks
  end

  def checks
    unwrapped_checks.collect { |c| WrappedCheck.new(c, self) }
  end

  def each_check(&block)
    checks.each &block
  end

  def next_check
    checks.detect { |c| ! c.completed? }
  end

  def [](check_name)
    checks.detect { |c| c.name == check_name }
  end

  def completions
    self.class.completions
  end

  def translation_key
    self.class.translation_key
  end

  module ClassMethods
    def checks
      @checks ||= []
    end

    def completions
      @completions ||= []
    end

    ##
    # Returns the underscored name used in the full i18n translation key
    #
    # Example:
    #
    #  UserProjectMotivation.translation_key # => "user_project"
    #
    def translation_key
      key = name.gsub(/Motivation\z/, '')
      key.gsub!(/^.*::/, '')
      key.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      key.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      key.tr!("-", "_")
      key.downcase!
    end

    def subject(attr_name)
      alias_method attr_name.to_sym, :subject
    end

    ##
    # Grant the ability to define if a progression applies.  This
    # enables creation a progression that might only apply if a project
    # is less than 30 days old
    def applies(&block)
      define_method("applies?") do
        !! instance_exec(&block)
      end
    end

    ##
    # Define the current step name, used by subsequent
    # DSL calls
    def step(name)
      @current_step_name = name
    end

    ##
    # Create a predicate method for the current step name
    # to test if it's complete
    def check(name = @current_step_name, &block)
      raise "No step name" unless name
      @current_step_name ||= name
      checks << CheckBlock.new("progression_name", name, &block)

      define_method("#{name}?") do
        check = checks.find { |s| s.name == name }
        !! check.run(self)
      end
    end

    # Check a method like `complete_current_step_name` to mark
    # a step complete.  This is not always needed but useful
    # if you want to persist a completion for performance purposes.
    def complete(&block)
      name = @current_step_name or raise "No step name"
      completions << CompletionBlock.new("progression_name", name, &block)

      define_method("complete_#{name}") do
        completion = completions.find { |c| c.name == name }
        completion.run(self)
      end
    end

  end

  class StepBlock
    attr_reader :name

    def initialize(progression_name, name, &block)
      @progression_name = progression_name
      @name             = name
      @block            = block
    end

    def run(context)
      context.instance_exec &@block
    end
  end

  class CheckBlock < StepBlock; end
  class CompletionBlock < StepBlock; end

  ##
  # WrappedCheck is used to wrap a Check with the context
  # of a motivation instance, so that you can check if
  # it is completed without passing in the subject instance
  #
  class WrappedCheck < DelegateClass(CheckBlock)
    def initialize(check, motivation)
      super(check)
      @check      = check
      @motivation = motivation
    end

    def completed?
      !! @check.run(@motivation)
    end

    ##
    # Returns a key for i18n like:
    #
    #   'motivations.project.incomplete.step_name'
    #
    # or for a completed step
    #   'motivations.project.complete.signed_up'
    #
    def translation_key(end_key = status_key)
       [
        "motivations",
        @motivation.translation_key,
        @check.name,
        end_key
      ].join('.')
    end

    def default_translation_key
      translation_key(:default)
    end

    private

    def status_key
      completed? ? "complete" : "default"
    end
  end

end
