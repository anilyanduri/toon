module Toon
  module Extensions
    module ActiveSupport
      module ObjectMethods
        # Serialize the object into TOON, preferring +as_json+ when available.
        # @param opts [Hash] encoder options passed to {Toon.generate}.
        # @return [String] TOON payload.
        def to_toon(**opts)
          payload = respond_to?(:as_json) ? as_json : self
          Toon.generate(payload, **opts)
        end
      end

      module_function

      # Inject +to_toon+ into Object so any model can be exported.
      # @return [void]
      def install!
        return if Object.method_defined?(:to_toon)
        Object.include(ObjectMethods)
      end

      # Install Object methods only when ActiveSupport is present.
      # @return [void]
      def ensure_installed!
        return unless defined?(::ActiveSupport)
        install!
      end

      # Attach a TracePoint that installs hooks once ActiveSupport loads.
      # @return [void]
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
