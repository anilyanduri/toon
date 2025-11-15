# Optional ActiveSupport integration
begin
  require 'active_support'
  require 'active_support/core_ext/object'
  class Object
    def to_toon(**opts)
      Toon.generate(self, **opts)
    end
  end
rescue LoadError
  # no activesupport available
end
