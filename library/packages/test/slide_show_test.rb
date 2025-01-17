#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "SlideShow"
Yast.import "Slides"
Yast.import "UI"

describe "Yast::SlideShow" do
  before(:each) do
    Yast.y2milestone "--------- Running test ---------"
    allow(::File).to receive(:exist?).and_return(true)
  end

  TOTAL_PROGRESS_ID = Yast::SlideShowClass::UI_ID::TOTAL_PROGRESS

  describe "#UpdateGlobalProgress" do
    before(:each) do
      allow(Yast::SlideShow).to receive(:ShowingSlide).and_return(false)

      # reseting total progress before each test
      Yast::SlideShow.UpdateGlobalProgress(0, "")
    end

    describe "when total progress widget is missing" do
      it "does not update the total progress" do
        expect(Yast::UI).to receive(:WidgetExists).with(TOTAL_PROGRESS_ID).and_return(false)
        expect(Yast::UI).not_to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, anything, anything)

        Yast::SlideShow.UpdateGlobalProgress(1, "new label -1")
      end
    end

    describe "when total progress widget exists" do
      before(:each) do
        allow(Yast::UI).to receive(:WidgetExists).and_return(false)
        expect(Yast::UI).to receive(:WidgetExists).with(TOTAL_PROGRESS_ID).and_return(true)
      end

      it "updates the progress value and label" do
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Value, 100)
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Label, "finished")

        Yast::SlideShow.UpdateGlobalProgress(100, "finished")
      end

      it "does not update progress label when setting it to nil" do
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Value, 25)
        expect(Yast::UI).not_to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Label, anything)

        Yast::SlideShow.UpdateGlobalProgress(25, nil)
      end

      it "does not update progress value when setting it to nil" do
        expect(Yast::UI).not_to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Value, anything)
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Label, "new label 1")

        Yast::SlideShow.UpdateGlobalProgress(nil, "new label 1")
      end

      # optimizes doing useless UI changes
      it "does not update progress value or label if setting them to their current value" do
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Value, 31).once
        expect(Yast::UI).to receive(:ChangeWidget).with(TOTAL_PROGRESS_ID, :Label, "new label 5").once

        # updates UI only once
        3.times { Yast::SlideShow.UpdateGlobalProgress(31, "new label 5") }
      end
    end
  end

  describe "#Setup" do
    it "the total progress is adjusted to exact 100%" do
      # input data from minimal SLES installation
      stages = [
        { "name" => "disk", "description" => "Preparing disks...", "value" => 120, "units" => :sec },
        { "name" => "images", "description" => "Deploying Images...", "value" => 0, "units" => :kb },
        { "name" => "packages", "description" => "Installing Packages...", "value" => 1_348_246, "units" => :kb },
        { "name" => "finish", "description" => "Finishing Basic Installation", "value" => 100, "units" => :sec }
      ]

      Yast::SlideShow.Setup(stages)
      total_size = Yast::SlideShow.GetSetup.values.reduce(0) { |a, e| a + e["size"] }
      expect(total_size).to eq(100)
    end
  end
end
