require_relative "toon/version"
require_relative "toon/encoder"
require_relative "toon/decoder"
require_relative "extensions/core"
require_relative "extensions/active_support"

module Toon
  class Error < StandardError; end

  def self.generate(obj, **opts)
    Toon::Encoder.generate(obj, **opts)
  end

  def self.pretty_generate(obj, **opts)
    Toon::Encoder.pretty_generate(obj, **opts)
  end

  def self.parse(str, **opts)
    Toon::Decoder.parse(str, **opts)
  end

  def self.load(io, **opts)
    Toon::Decoder.load(io, **opts)
  end

  def self.dump(obj, io = STDOUT, **opts)
    Toon::Encoder.dump(obj, io, **opts)
  end
end
