require "spec_helper"
require "open3"
require "json"

RSpec.describe "toon CLI" do
  let(:exe) { File.expand_path("../../bin/toon", __dir__) }

  it "encodes JSON to TOON with --encode" do
    input = '{"name":"Alice","age":30}'

    stdout, stderr, status = Open3.capture3(exe, "--encode", stdin_data: input)

    expect(status.success?).to eq(true)
    expect(stderr).to eq("")

    # Output should be a TOON string like:
    # name:Alice
    # age:30
    #
    # We just check for key presence.
    expect(stdout).to include("name:")
    expect(stdout).to include("Alice")
    expect(stdout).to include("age:")
    expect(stdout).to include("30")
  end

  it "decodes TOON to JSON with --decode" do
    input = <<~T
      name:Alice
      age:30
    T

    stdout, stderr, status = Open3.capture3(exe, "--decode", stdin_data: input)

    expect(status.success?).to eq(true)
    expect(stderr).to eq("")

    json = JSON.parse(stdout)
    expect(json["name"]).to eq("Alice")
    expect(json["age"]).to eq(30)
  end

  it "reads from STDIN when no file is given" do
    input = '{"hello":"world"}'

    stdout, stderr, status = Open3.capture3(exe, "--encode", stdin_data: input)

    expect(status.success?).to eq(true)
    expect(stdout).to include("hello:")
  end
end
