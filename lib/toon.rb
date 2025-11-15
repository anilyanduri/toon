require_relative "toon/version"
require_relative "toon/encoder"
require_relative "toon/decoder"
require_relative "extensions/core"
require_relative "extensions/active_support"

module Toon
  class Error < StandardError; end

  # Generate a TOON-formatted String from any serializable Ruby object.
  # @param obj [Object] the object to encode.
  # @param opts [Hash] encoder options forwarded to `Toon::Encoder`.
  # @return [String] the TOON payload.
  def self.generate(obj, **opts)
    Toon::Encoder.generate(obj, **opts)
  end

  # Generate a human-friendly TOON String with extra spacing and indentation.
  # @param obj [Object] the object to encode.
  # @param opts [Hash] encoder options forwarded to `Toon::Encoder`.
  # @return [String] the prettified TOON payload.
  def self.pretty_generate(obj, **opts)
    Toon::Encoder.pretty_generate(obj, **opts)
  end

  # Parse a TOON String and reconstruct the Ruby data structure.
  # @param str [String] the TOON representation.
  # @param opts [Hash] decoder options forwarded to `Toon::Decoder`.
  # @return [Object] the decoded Ruby structure.
  def self.parse(str, **opts)
    Toon::Decoder.parse(str, **opts)
  end

  # Read a TOON payload from any IO-like object and parse it.
  # @param io [#read] an IO that responds to `#read`.
  # @param opts [Hash] decoder options forwarded to `Toon::Decoder`.
  # @return [Object] the decoded Ruby structure.
  def self.load(io, **opts)
    Toon::Decoder.load(io, **opts)
  end

  # Stream a TOON payload for +obj+ into the provided IO target.
  # @param obj [Object] the object to encode.
  # @param io [#write] where the payload should be written.
  # @param opts [Hash] encoder options forwarded to `Toon::Encoder`.
  # @return [nil]
  def self.dump(obj, io = STDOUT, **opts)
    Toon::Encoder.dump(obj, io, **opts)
  end
end
