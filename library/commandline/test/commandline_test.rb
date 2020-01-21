#! /usr/bin/env rspec

require_relative "test_helper"

Yast.import "CommandLine"

# If these test fail (or succeed) in mysterious ways then it may be
# wfm.rb eagerly rescuing a RSpec::Mocks::MockExpectationError
# (fixed meanwhile in ruby-bindings). In such cases see the y2log.

describe Yast::CommandLine do
  # restore the original modes to not accidentally influence the other tests
  # (these tests change the UI mode to "commandline")
  around(:example) do |example|
    orig_mode = Yast::Mode.mode
    orig_ui = Yast::Mode.ui
    example.run
    Yast::Mode.SetMode(orig_mode)
    Yast::Mode.SetUI(orig_ui)
  end

  subject { Yast::CommandLine }

  before do
    subject.main # reset
    allow(Yast::Debugger).to receive(:installed?).and_return(false)
  end

  # NOTE: when using the byebug debugger here temporarily comment out
  # all "expect($stdout)" lines otherwise the byebug output will be
  # lost in the rspec mocks and you won't see anything.

  it "invokes initialize, handler and finish" do
    expect($stdout).to receive(:puts).with("Initialize called").ordered
    expect($stdout).to receive(:puts).with("something").ordered
    expect($stdout).to receive(:puts).with("Finish called").ordered

    Yast::WFM.CallFunction("dummy_cmdline", ["echo", "text=something"])
  end

  it "displays errors and aborts" do
    expect($stdout).to receive(:puts).with("Initialize called").ordered
    expect(subject).to receive(:Print).with(/I crashed/).ordered
    expect($stdout).to_not receive(:puts).with("Finish called")

    Yast::WFM.CallFunction("dummy_cmdline", ["crash"])
  end

  it "complains about unknown commands and returns false" do
    expect(subject).to receive(:Print).with(/Unknown Command:/)
    expect(subject).to receive(:Print).with(/Use.*help.*available commands/)

    expect(Yast::WFM.CallFunction("dummy_cmdline", ["unknowncommand"])).to eq false
  end

  describe ".PrintHead" do
    it "prints header with underscore" do
      expect(subject).to receive(:Print).with( <<-OUTPUT

YaST Configuration Module YaST
------------------------------
OUTPUT
      )

      subject.PrintHead
    end
  end

  describe ".UniqueOption" do
    context "in options is only one of the options mentioned in unique_options" do
      it "returns string" do
        expect(subject.UniqueOption(["a", "b", "c"], ["c", "d", "e"])).to eq "c"
      end
    end

    context "in options is none of the options mentioned in unique_options" do
      it "returns nil" do
        expect(subject.UniqueOption(["a", "b"], ["c", "d", "e"])).to eq nil
      end

      it "reports error mentioning to specify one of the option if there are more in unique options" do
        # FIXME: it looks bad that chaining
        # FIXME: do not print command that is not used in options
        expect(Yast::Report).to receive(:Error).with("Specify one of the commands: 'c', 'd', or 'e'.")

        subject.UniqueOption(["a", "b"], ["c", "d", "e"])
      end

      it "reports error mentioning to specify one the option if there is only one in unique options" do
        expect(Yast::Report).to receive(:Error).with("Specify the command 'c'.")

        subject.UniqueOption(["a", "b"], ["c"])
      end
    end

    context "in options is more then one of the options mentioned in unique_options" do
      it "returns nil" do
        expect(subject.UniqueOption(["a", "b"], ["a", "b", "e"])).to eq nil
      end

      it "reports error" do
        # FIXME: it looks bad that chaining
        # FIXME: do not print command that is not used in options
        expect(Yast::Report).to receive(:Error).with("Specify only one of the commands: 'a', 'b', or 'e'.")

        subject.UniqueOption(["a", "b"], ["a", "b", "e"])
      end
    end
  end
end
