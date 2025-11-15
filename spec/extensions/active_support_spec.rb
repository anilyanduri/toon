require "spec_helper"

RSpec.describe "ActiveSupport extension" do
  it "adds #to_toon to Object when ActiveSupport is loaded" do
    require "active_support"
    require "active_support/core_ext/object"
    require "toon"

    obj = { "a" => 1 }

    expect(obj.respond_to?(:to_toon)).to eq(true)
    expect(obj.to_toon).to be_a(String)
    expect(obj.to_toon).to include("a:1")
  end
end
