require 'stringio'

module Toon
  module Encoder
    module_function

    DEFAULT_OPTIONS = {
      delimiter: ',',
      indent: 2,
      compact_arrays: true, # try to use tabular form when possible
      pretty: false
    }.freeze

    # Generate a TOON string for +obj+ with the desired encoder options.
    # @param obj [Object] structure to serialize.
    # @param opts [Hash] overrides for {DEFAULT_OPTIONS}.
    # @return [String] TOON payload.
    def generate(obj, **opts)
      options = DEFAULT_OPTIONS.merge(opts)
      state = build_state(options)
      io = StringIO.new
      write_object(io, obj, 0, options, state)
      io.string
    end

    # Generate a human-friendly TOON payload irrespective of caller options.
    # @param obj [Object] structure to serialize.
    # @param opts [Hash] encoder overrides.
    # @return [String] prettified TOON payload.
    def pretty_generate(obj, **opts)
      generate(obj, **opts.merge(pretty: true))
    end

    # Stream the serialized payload directly to an IO target.
    # @param obj [Object] data to encode.
    # @param io [#write] destination stream (defaults to STDOUT).
    # @param opts [Hash] encoder overrides.
    # @return [nil]
    def dump(obj, io = STDOUT, **opts)
      io.write(generate(obj, **opts))
      nil
    end

    private

    # Precompute indentation state for the current encoding run.
    # @param options [Hash] encoder configuration.
    # @return [Hash] indent caching state.
    def build_state(options)
      width = options.fetch(:indent, DEFAULT_OPTIONS[:indent]).to_i
      width = DEFAULT_OPTIONS[:indent] if width <= 0
      indent_step = ' ' * width
      { indent_step: indent_step, indent_cache: [''] }
    end

    # Dispatch encoding logic for hashes, arrays, or scalar values.
    # @param io [#write] accumulating stream.
    # @param obj [Object] value to encode.
    # @param level [Integer] depth in the output tree.
    # @param options [Hash] encoder configuration.
    # @param state [Hash] cached encoder state (indent cache, etc.).
    def write_object(io, obj, level, options, state)
      case obj
      when Hash
        obj.each do |k, v|
          write_key(io, k, level, state)
          if simple_value?(v)
            io.write(format_simple(v))
            io.write("\n")
          else
            io.write("\n")
            write_object(io, v, level + 1, options, state)
          end
        end
      when Array
        keys = options[:compact_arrays] ? uniform_tabular_keys(obj) : nil
        if keys
          write_tabular(io, obj, level, options, state, keys)
        else
          write_list(io, obj, level, options, state)
        end
      else
        io.write(indent(level, state))
        io.write(format_simple(obj))
        io.write("\n")
      end
    end

    # Emit a hash key label aligned to the requested indentation depth.
    # @param io [#write] accumulating stream.
    # @param key [String, Symbol] key to render.
    # @param level [Integer] indentation level.
    # @param state [Hash] encoder state.
    def write_key(io, key, level, state)
      io.write(indent(level, state))
      io.write("#{key}:")
    end

    # Render an array of hashes using the compact tabular notation.
    # @param io [#write] accumulating stream.
    # @param arr [Array<Hash>] rows to encode.
    # @param level [Integer] indentation level.
    # @param options [Hash] encoder configuration.
    # @param state [Hash] encoder state.
    # @param keys [Array] ordered set of tabular columns.
    def write_tabular(io, arr, level, options, state, keys)
      io.write(indent(level, state))
      io.write("[#{arr.length}]{#{keys.join(',')}}:\n")
      arr.each do |row|
        io.write(indent(level + 1, state))
        vals = keys.map { |k| format_simple(row[k]) }
        io.write(vals.join(options[:delimiter]))
        io.write("\n")
      end
    end

    # Render a heterogeneous array in the multi-line list form.
    # @param io [#write] accumulating stream.
    # @param arr [Array] values to encode.
    # @param level [Integer] indentation level.
    # @param options [Hash] encoder configuration.
    # @param state [Hash] encoder state.
    def write_list(io, arr, level, options, state)
      io.write(indent(level, state))
      io.write("[#{arr.length}]:\n")
      arr.each do |el|
        io.write(indent(level + 1, state))
        if simple_value?(el)
          io.write(format_simple(el))
          io.write("\n")
        else
          write_object(io, el, level + 1, options, state)
        end
      end
    end

    # Produce indentation padding for the supplied level.
    # @param level [Integer] nesting depth.
    # @param state [Hash] encoder state.
    # @return [String] spaces for indent.
    def indent(level, state)
      cache = state[:indent_cache]
      if cache.length <= level
        step = state[:indent_step]
        current = cache.last
        (cache.length..level).each do
          current = current + step
          cache << current
        end
      end
      cache[level]
    end

    # Identify whether +v+ is a scalar that can be inlined.
    # @param v [Object] value to test.
    # @return [Boolean] true if +v+ is nil, numeric, boolean, or string.
    def simple_value?(v)
      v.nil? || v.is_a?(Numeric) || v.is_a?(String) || v == true || v == false
    end

    # Convert a scalar value into its TOON string representation.
    # @param v [Object] scalar value.
    # @return [String] formatted representation.
    def format_simple(v)
      case v
      when String
        # naive quoting: quote when contains delimiter or colon or newline
        if v.empty? || v.match(/[,:\n{}\[\]]/)
          '"' + v.gsub('"', '\\"') + '"'
        else
          v
        end
      when nil
        'null'
      when true
        'true'
      when false
        'false'
      else
        v.to_s
      end
    end

    # Return column keys when +arr+ contains hashes sharing identical key sets.
    # @param arr [Array] array to test.
    # @return [Array,nil] ordered keys when tabular encoding applies.
    def uniform_tabular_keys(arr)
      return nil if arr.empty?
      first = arr.first
      return nil unless first.is_a?(Hash)
      reference = first.keys
      sorted_reference = reference.sort
      arr.each do |hash|
        return nil unless hash.is_a?(Hash) && hash.keys.sort == sorted_reference
      end
      reference
    end

    module_function :write_object, :write_key, :write_tabular, :write_list,
                    :indent, :simple_value?, :format_simple, :uniform_tabular_keys,
                    :build_state
  end
end
