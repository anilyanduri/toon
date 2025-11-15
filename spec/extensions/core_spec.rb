require "spec_helper"
require "json"

RSpec.describe "Core extensions" do
  describe Hash do
    it "responds to #to_toon" do
      toon = { "foo" => "bar" }.to_toon
      expect(toon).to be_a(String)
      expect(toon).to include("foo:bar")
    end

    it "responds to #to_json without extra requires" do
      json = { "foo" => "bar" }.to_json
      expect(JSON.parse(json)["foo"]).to eq("bar")
    end
  end

  describe Array do
    it "responds to #to_toon" do
      toon = [1, 2].to_toon
      expect(toon).to include("[2]:")
    end

    it "responds to #to_json" do
      json = [1, 2].to_json
      expect(JSON.parse(json)).to eq([1, 2])
    end
  end
end
