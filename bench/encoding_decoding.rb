#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require_relative "../lib/toon"

SAMPLES = {
  simple: { "name" => "Alice", "age" => 30 },
  nested: { "user" => { "id" => 1, "name" => "Bob" } },
  array:  { "colors" => %w[red green blue] },
  tabular: {
    "users" => [
      { "id" => 1, "name" => "A" },
      { "id" => 2, "name" => "B" }
    ]
  }
}.transform_values { |obj| [obj, Toon.generate(obj)] }.freeze

Benchmark.ips do |x|
  SAMPLES.each do |label, (ruby_obj, toon_str)|
    x.report("encode #{label}") { Toon.generate(ruby_obj) }
    x.report("decode #{label}") { Toon.parse(toon_str) }
  end
  x.compare!
end
