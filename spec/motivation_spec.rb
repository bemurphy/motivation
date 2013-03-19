require 'motivation'
require "ostruct"

Project = Struct.new(:name, :subdomain, :users) do
  attr_accessor :users_count
end

class ProjectMotivation
  include Motivation

  attr_accessor :applies, :method_check
  # Privatize just the getter so we
  # cam make sure everything is callable
  private :method_check

  applies { !! applies }

  subject :project

  check(:name_setup) { ! project.name.to_s.empty? }

  step :subdomain_setup
  check { ! project.subdomain.to_s.empty? }

  check(:local_method_step) { method_check }

  step :users_signed_up
  check do
    project.users_count.to_i > 0 || project.users.length > 0
  end
  complete {
    project.users_count = project.users.length
  }
end

describe Motivation do
  let(:project) { Project.new("Spec Project", "spec-subdomain", [stub, stub]) }
  let(:motivation) { ProjectMotivation.new project }

  it "provides a subject class method for aliasing the subject" do
    expect(motivation.project).to_not be_nil
    expect(motivation.project).to eq motivation.subject
  end

  context "a simple check step" do
    it "creates a predicate method provided a name and block" do
      project.name = nil
      expect(motivation).to_not be_name_setup

      project.name = "Spec Project"
      expect(motivation).to be_name_setup
    end
  end

  context "a step definition followed by a check" do
    it "creates a predicate method provided a name and block" do
      project.subdomain = nil
      expect(motivation).to_not be_subdomain_setup

      project.subdomain = "spec-subdomain"
      expect(motivation).to be_subdomain_setup
    end
  end

  context "a step definition calling progression instance methods" do
    it "can call the instance method with expected scope" do
      expect(motivation).to_not be_local_method_step
      motivation.method_check = true
      expect(motivation).to be_local_method_step
    end
  end

  context "a step definition followed by a check and a completion" do
    it "creates the completion" do
      project.users = [stub, stub, stub]
      motivation.complete_users_signed_up
      expect(project.users_count).to eq 3
      expect(motivation).to be_users_signed_up
    end
  end

  describe "application checks" do
    it "are true by default" do
      klass = Class.new do
        include Motivation
      end

      expect(klass.new(stub).applies?).to be_true
    end

    it "are overridden with the apply dsl" do
      motivation.applies = nil
      expect(motivation.applies?).to be_false
    end
  end

  describe ".translation_key" do
    it "project for ProjectMotivation" do
      expect(ProjectMotivation.translation_key).to eq "project"
    end

    it "user_project for UserProjectMotivation" do
      UserProjectMotivation = Class.new do
        include Motivation
      end
      expect(UserProjectMotivation.translation_key).to eq "user_project"
    end

    it "is accessable via the instance" do
      expect(motivation.translation_key).to eq "project"
    end
  end

  describe "iterating checks" do
    it "steps through the checks in order" do
      names = []

      motivation.each_check do |c|
        names << c.name
      end

      expect(names).to eq [:name_setup, :subdomain_setup, :local_method_step, :users_signed_up]
    end

    it "wraps the checks to allow checking if it's completed" do
      project.name      = "name"
      project.subdomain = nil
      results           = []

      motivation.each_check do |c|
        results << c.completed?
      end

      expect(results[0]).to be_true
      expect(results[1]).to be_false
    end
  end

  describe "getting the next check" do
    it "returns the first wrapped check that is incomplete" do
      project.name = "name"
      project.subdomain = nil
      expect(motivation.next_check.name.to_s).to eq "subdomain_setup"
      project.subdomain = "subdomain"
      expect(motivation.next_check.name.to_s).to eq "local_method_step"
    end

    it "returns nil if all checks are complete" do
      motivation.method_check = true
      expect(motivation.next_check).to be_nil
    end
  end

  describe "checking if all checks are complete" do
    it "returns false if there's an incomplete check" do
      motivation.method_check = false
      expect(motivation).to_not be_complete
    end

    it "returns true if all checks are complete" do
      motivation.method_check = true
      expect(motivation).to be_complete
    end
  end

  describe "retrieving a check with #[]" do
    it "returns a check by name" do
      check = motivation[:name_setup]
      expect(check.name).to eq :name_setup

      check = motivation[:users_signed_up]
      expect(check.name).to eq :users_signed_up
    end
  end

end

describe Motivation::WrappedCheck, "#translation_key" do
  let(:check) { OpenStruct.new }
  let(:motivation) { stub(:motivation, :translation_key => "project") }
  let(:wrapped_check) { Motivation::WrappedCheck.new(check, motivation) }

  before do
    class << check
      attr_accessor :flag

      def run(*)
        !! flag
      end
    end

    check.name = "foo_bar"
  end

  context "for a incomplete step" do
    it "generates a key like motivations.project.step_name.default" do
      check.flag = false
      expect(wrapped_check.translation_key).to eq "motivations.project.foo_bar.default"
    end
  end

  context "for a completed step" do
    it "generates a key like motivations.project.step_name.complete" do
      check.flag = true
      expect(wrapped_check.translation_key).to eq "motivations.project.foo_bar.complete"
    end
  end

  context "when an end_key is passed" do
    it "uses the end_key as the terminal position" do
      expect(wrapped_check.translation_key(:foobar)).to eq "motivations.project.foo_bar.foobar"
    end
  end

  it "provides #default_translation_key as a convienience" do
    expect(wrapped_check.default_translation_key).to eq "motivations.project.foo_bar.default"
  end

end
