require "spec_helper"

RSpec.describe Toon do
  describe "encode + decode" do
    it "encodes and decodes a simple object" do
      obj = { "name" => "Alice", "age" => 30 }
      encoded = Toon.generate(obj)
      decoded = Toon.parse(encoded)

      expect(decoded["name"]).to eq("Alice")
      expect(decoded["age"]).to eq(30)
    end

    it "encodes and decodes nested objects" do
      obj = {
        "user" => {
          "id" => 1,
          "name" => "Bob"
        }
      }

      encoded = Toon.generate(obj)
      decoded = Toon.parse(encoded)

      expect(decoded["user"]["id"]).to eq(1)
      expect(decoded["user"]["name"]).to eq("Bob")
    end

    it "encodes and decodes arrays of primitives" do
      obj = { "colors" => ["red", "green", "blue"] }

      encoded = Toon.generate(obj)
      decoded = Toon.parse(encoded)

      expect(decoded["colors"]).to eq(["red", "green", "blue"])
    end

    it "encodes and decodes uniform arrays of objects (tabular)" do
      obj = {
        "users" => [
          { "id" => 1, "name" => "A" },
          { "id" => 2, "name" => "B" }
        ]
      }

      encoded = Toon.generate(obj)
      decoded = Toon.parse(encoded)

      expect(decoded["users"]).to be_an(Array)
      expect(decoded["users"].length).to eq(2)
      expect(decoded["users"][0]["id"]).to eq(1)
      expect(decoded["users"][0]["name"]).to eq("A")
      expect(decoded["users"][1]["id"]).to eq(2)
      expect(decoded["users"][1]["name"]).to eq("B")
    end
  end

  describe "decode only" do
    it "decodes simple TOON object" do
      toon = <<~TOON
        name: Alice
        age: 30
      TOON

      decoded = Toon.parse(toon)

      expect(decoded["name"]).to eq("Alice")
      expect(decoded["age"]).to eq(30)
    end

    it "decodes nested TOON structures" do
      toon = <<~TOON
        user:
          id: 100
          name: John
      TOON

      decoded = Toon.parse(toon)

      expect(decoded["user"]["id"]).to eq(100)
      expect(decoded["user"]["name"]).to eq("John")
    end

    it "decodes simple arrays" do
      toon = <<~TOON
        colors[3]:
          red
          green
          blue
      TOON

      decoded = Toon.parse(toon)

      expect(decoded["colors"]).to eq(["red", "green", "blue"])
    end

    it "decodes tabular rows" do
      toon = <<~TOON
        users[2]{id,name}:
          1,Alice
          2,Bob
      TOON

      decoded = Toon.parse(toon)

      expect(decoded["users"][0]["id"]).to eq("1")  # decoder gives strings for now
      expect(decoded["users"][0]["name"]).to eq("Alice")
      expect(decoded["users"][1]["id"]).to eq("2")
      expect(decoded["users"][1]["name"]).to eq("Bob")
    end
  end
end
