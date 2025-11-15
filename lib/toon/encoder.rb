require 'stringio'
module Toon
  module Encoder
    module_function

    DEFAULT_OPTIONS = {
      delimiter: ',',
      indent: 2,
      compact_arrays: true, # try to use tabular form when possible
      pretty: false
    }

    def generate(obj, **opts)
      options = DEFAULT_OPTIONS.merge(opts)
      io = StringIO.new
      write_object(io, obj, 0, options)
      io.string
    end

    def pretty_generate(obj, **opts)
      generate(obj, **opts.merge(pretty: true))
    end

    def dump(obj, io = STDOUT, **opts)
      str = generate(obj, **opts)
      io.write(str)
      nil
    end

    private

    def write_object(io, obj, level, options)
      case obj
      when Hash
        obj.each do |k, v|
          write_key(io, k, level)
          if simple_value?(v)
            io.write(format_simple(v))
            io.write("\n")
          else
            io.write("\n")
            write_object(io, v, level + 1, options)
          end
        end
      when Array
        # Try to detect uniform objects for tabular style
        if options[:compact_arrays] && array_uniform_hashes?(obj)
          write_tabular(io, obj, level, options)
        else
          write_list(io, obj, level, options)
        end
      else
        # scalar
        io.write(indent(level))
        io.write(format_simple(obj))
        io.write("\n")
      end
    end

    def write_key(io, key, level)
      io.write(indent(level))
      io.write("#{key}:")
    end

    def write_tabular(io, arr, level, options)
      keys = (arr.map(&:keys).reduce(:|) || []).uniq
      io.write(indent(level))
      io.write("[#{arr.length}]{#{keys.join(',')}}:\n")
      arr.each do |row|
        io.write(indent(level + 1))
        vals = keys.map { |k| format_simple(row[k]) }
        io.write(vals.join(options[:delimiter]))
        io.write("\n")
      end
    end

    def write_list(io, arr, level, options)
      io.write(indent(level))
      io.write("[#{arr.length}]:\n")
      arr.each do |el|
        io.write(indent(level + 1))
        if simple_value?(el)
          io.write(format_simple(el))
          io.write("\n")
        else
          # nested object or array
          write_object(io, el, level + 1, options)
        end
      end
    end

    def indent(level)
      ' ' * (level * 2)
    end

    def simple_value?(v)
      v.nil? || v.is_a?(Numeric) || v.is_a?(String) || v == true || v == false
    end

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

    def array_uniform_hashes?(arr)
      return false if arr.empty?
      arr.all? { |e| e.is_a?(Hash) } && (arr.map { |h| h.keys.sort } .uniq.length == 1)
    end

    module_function :write_object, :write_key, :write_tabular, :write_list,
                :indent, :simple_value?, :format_simple, :array_uniform_hashes?
  end
end
