module Toon
  module Decoder
    module_function

    TABULAR_FLAT_REGEX     = /^(\w+)\[(\d+)\]\{([^}]*)\}:$/.freeze
    PRIMITIVE_FLAT_REGEX   = /^(\w+)\[(\d+)\]:$/.freeze
    NESTED_OBJECT_REGEX    = /^(\w+):$/.freeze
    TABULAR_NESTED_REGEX   = /^\[(\d+)\]\{([^}]*)\}:$/.freeze
    PRIMITIVE_NESTED_REGEX = /^\[(\d+)\]:$/.freeze
    SIMPLE_KV_REGEX        = /^(\w+):\s*(.*)$/.freeze

    # Parse a TOON string and produce the corresponding Ruby structure.
    # @param str [String] TOON payload.
    # @param opts [Hash] reserved for future parser options.
    # @return [Object] reconstructed Ruby data.
    def parse(str, **opts)
      lines = str.gsub("\r\n", "\n").split("\n")
      parse_lines(lines)
    end

    # Read all data from an IO-like object and parse it as TOON.
    # @param io [#read] source stream.
    # @param opts [Hash] reserved for future parser options.
    # @return [Object] reconstructed Ruby data.
    def load(io, **opts)
      parse(io.read, **opts)
    end

    # Core parser that works on an array of sanitized TOON lines.
    # @param lines [Array<String>] TOON lines without newlines.
    # @return [Hash] root object constructed from the input.
    def parse_lines(lines)
      root = {}
      stack = [{ indent: -1, obj: root, parent: nil, key: nil }]

      i = 0
      while i < lines.length
        raw = lines[i].rstrip
        i += 1

        stripped = raw.strip
        next if stripped.empty? || stripped.start_with?('#')

        indent = leading_spaces(raw)
        content = stripped

        while indent <= stack.last[:indent]
          stack.pop
        end

        current = stack.last
        parent_obj = current[:obj]

        if (m = TABULAR_FLAT_REGEX.match(content))
          key = m[1]
          count = m[2].to_i
          fields = parse_fields(m[3])
          rows, i = read_tabular_rows(fields, lines, i, count, parse_values: false)
          parent_obj[key] = rows
          next
        end

        if (m = PRIMITIVE_FLAT_REGEX.match(content))
          key = m[1]
          count = m[2].to_i
          values, i = read_primitive_values(lines, i, count)
          parent_obj[key] = values
          next
        end

        if (m = NESTED_OBJECT_REGEX.match(content))
          key = m[1]
          new_obj = {}

          parent_obj[key] = new_obj
          stack << { indent: indent, obj: new_obj, parent: parent_obj, key: key }
          next
        end

        frame = stack.last
        parent = frame[:parent]
        key = frame[:key]

        if (m = TABULAR_NESTED_REGEX.match(content))
          count = m[1].to_i
          fields = parse_fields(m[2])
          rows, i = read_tabular_rows(fields, lines, i, count, parse_values: true)
          parent[key] = rows
          stack.pop
          next
        end

        if (m = PRIMITIVE_NESTED_REGEX.match(content))
          count = m[1].to_i

          if key.nil?
            raise Toon::Error, "Malformed TOON: array header '#{content}' must be under a key (e.g., 'colors:')"
          end

          values, i = read_primitive_values(lines, i, count)
          parent[key] = values
          stack.pop
          next
        end

        if (m = SIMPLE_KV_REGEX.match(content))
          k = m[1]
          v = parse_scalar(m[2])
          parent_obj[k] = v
          next
        end
      end

      root
    end

    # Count the indentation depth (in spaces) at the beginning of +line+.
    # @param line [String] line from the TOON payload.
    # @return [Integer] number of leading spaces.
    def leading_spaces(line)
      line[/^ */].length
    end

    # Convert a scalar token into the appropriate Ruby object.
    # @param str [String] textual token.
    # @return [Object] decoded scalar (String, Numeric, true/false, nil).
    def parse_scalar(str)
      if str == 'null' then nil
      elsif str == 'true' then true
      elsif str == 'false' then false
      elsif str.match?(/^".*"$/)
        str[1..-2].gsub('\\"', '"')
      elsif str =~ /^-?\d+$/
        str.to_i
      elsif str =~ /^-?\d+\.\d+$/
        str.to_f
      else
        str
      end
    end

    # Split a comma-delimited row while preserving quoted delimiters.
    # @param row [String] raw row contents.
    # @return [Array<String>] tokenized column values.
    def split_row(row)
      row.scan(/(?:\"([^\"]*)\"|([^,]+))(?:,|$)/).map { |m| (m[0] || m[1]).to_s.strip }
    end

    # Parse the column list from a tabular header.
    # @param field_str [String] raw column descriptor.
    # @return [Array<String>] sanitized field names.
    def parse_fields(field_str)
      field_str.split(',').map!(&:strip)
    end

    # Read +count+ rows for a tabular array, optionally parsing scalar values.
    # @param fields [Array<String>] column names.
    # @param lines [Array<String>] all lines being parsed.
    # @param index [Integer] current cursor within +lines+.
    # @param count [Integer] number of rows to consume.
    # @param parse_values [Boolean] whether to run +parse_scalar+ on values.
    # @return [Array<Array<Hash>>, Integer] rows plus updated line index.
    def read_tabular_rows(fields, lines, index, count, parse_values:)
      rows = []
      count.times do
        raw = lines[index]
        index += 1
        next unless raw
        values = split_row(raw.strip)
        values.map! { |v| parse_scalar(v) } if parse_values
        rows << build_row_hash(fields, values)
      end
      [rows, index]
    end

    # Read +count+ primitive entries.
    # @param lines [Array<String>] payload lines.
    # @param index [Integer] cursor.
    # @param count [Integer] number of rows.
    # @return [Array<Object>, Integer] values and updated cursor.
    def read_primitive_values(lines, index, count)
      values = []
      count.times do
        raw = lines[index]
        index += 1
        next unless raw
        values << parse_scalar(raw.strip)
      end
      [values, index]
    end

    # Build a hash row from field/value pairs.
    # @param fields [Array<String>] column names.
    # @param values [Array] decoded values.
    # @return [Hash] row hash.
    def build_row_hash(fields, values)
      row_hash = {}
      fields.each_index do |idx|
        row_hash[fields[idx]] = values[idx]
      end
      row_hash
    end
  end
end
