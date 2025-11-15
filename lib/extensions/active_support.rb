module Toon
  module Extensions
    module ActiveSupport
      module ObjectMethods
        def to_toon(**opts)
          Toon.generate(self, **opts)
        end
      end

      module_function

      def install!
        return if Object.method_defined?(:to_toon)
        Object.include(ObjectMethods)
      end

      def ensure_installed!
        return unless defined?(::ActiveSupport)
        install!
      end

      def watch_for_active_support!
        return if defined?(@tracepoint) && @tracepoint&.enabled?
        @tracepoint = TracePoint.new(:end) do |tp|
          next unless tp.self.is_a?(Module)
          next unless tp.self.name == "ActiveSupport"
          ensure_installed!
          @tracepoint.disable
        end
        @tracepoint.enable
      end
    end
  end
end

if defined?(::ActiveSupport)
  Toon::Extensions::ActiveSupport.ensure_installed!
else
  Toon::Extensions::ActiveSupport.watch_for_active_support!
end
