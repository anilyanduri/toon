require 'json'

module Toon
  module Extensions
    module Core
      module_function

      # Serialize a Hash-like object into TOON using the global encoder.
      # @param target [Hash] structure to encode.
      # @param opts [Hash] options passed through to {Toon.generate}.
      # @return [String] TOON string.
      def hash_to_toon(target, **opts)
        Toon.generate(target, **opts)
      end

      # Serialize an Array into TOON by delegating to {Toon.generate}.
      # @param target [Array] structure to encode.
      # @param opts [Hash] options passed through to the encoder.
      # @return [String] TOON string.
      def array_to_toon(target, **opts)
        Toon.generate(target, **opts)
      end

      # Convert the object to JSON using the bundled JSON gem.
      # @param target [Object] structure to encode.
      # @param args [Array] options forwarded to {JSON.generate}.
      # @return [String] JSON payload.
      def to_json_payload(target, *args)
        JSON.generate(target, *args)
      end
    end
  end
end

class Hash
  unless method_defined?(:to_toon)
    # Serialize the hash into TOON format.
    # @param opts [Hash] encoder options.
    # @return [String] TOON payload.
    def to_toon(**opts)
      Toon::Extensions::Core.hash_to_toon(self, **opts)
    end
  end

  unless method_defined?(:to_json)
    # Serialize the hash into JSON via the core extension helper.
    # @param args [Array] JSON serialization options.
    # @return [String] JSON payload.
    def to_json(*args)
      Toon::Extensions::Core.to_json_payload(self, *args)
    end
  end
end

class Array
  unless method_defined?(:to_toon)
    # Serialize the array into TOON format.
    # @param opts [Hash] encoder options.
    # @return [String] TOON payload.
    def to_toon(**opts)
      Toon::Extensions::Core.array_to_toon(self, **opts)
    end
  end

  unless method_defined?(:to_json)
    # Serialize the array into JSON via the core extension helper.
    # @param args [Array] JSON serialization options.
    # @return [String] JSON payload.
    def to_json(*args)
      Toon::Extensions::Core.to_json_payload(self, *args)
    end
  end
end
