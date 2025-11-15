require 'json'

module Toon
  module Extensions
    module Core
      module_function

      def hash_to_toon(target, **opts)
        Toon.generate(target, **opts)
      end

      def array_to_toon(target, **opts)
        Toon.generate(target, **opts)
      end

      def to_json_payload(target, *args)
        JSON.generate(target, *args)
      end
    end
  end
end

class Hash
  unless method_defined?(:to_toon)
    def to_toon(**opts)
      Toon::Extensions::Core.hash_to_toon(self, **opts)
    end
  end

  unless method_defined?(:to_json)
    def to_json(*args)
      Toon::Extensions::Core.to_json_payload(self, *args)
    end
  end
end

class Array
  unless method_defined?(:to_toon)
    def to_toon(**opts)
      Toon::Extensions::Core.array_to_toon(self, **opts)
    end
  end

  unless method_defined?(:to_json)
    def to_json(*args)
      Toon::Extensions::Core.to_json_payload(self, *args)
    end
  end
end
