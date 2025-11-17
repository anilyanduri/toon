module Toon
  module Decoder
    module_function

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
        raw = lines[i]
        i += 1
        next unless raw

        raw = raw.rstrip
        stripped = raw.strip
        next if stripped.empty? || stripped.start_with?('#')

        indent = leading_spaces(raw)
        content = stripped

        while indent <= stack.last[:indent]
          stack.pop
        end

        current = stack.last
        parent_obj = current[:obj]

        if (header = detect_flat_tabular(content))
          key, count, field_str = header
          fields = parse_fields(field_str)
          rows, i = read_tabular_rows(fields, lines, i, count, parse_values: false)
          parent_obj[key] = rows
          next
        end

        if (header = detect_flat_primitive(content))
          key, count = header
          values, i = read_primitive_values(lines, i, count)
          parent_obj[key] = values
          next
        end

        if (key = detect_nested_object(content))
          new_obj = {}
          parent_obj[key] = new_obj
          stack << { indent: indent, obj: new_obj, parent: parent_obj, key: key }
          next
        end

        frame = stack.last
        parent = frame[:parent]
        key = frame[:key]

        if (header = detect_nested_tabular(content))
          count, field_str = header
          fields = parse_fields(field_str)
          rows, i = read_tabular_rows(fields, lines, i, count, parse_values: true)
          parent[key] = rows
          stack.pop
          next
        end

        if (count = detect_nested_primitive(content))
          raise Toon::Error, "Malformed TOON: array header '#{content}' must be under a key (e.g., 'colors:')" if key.nil?

          values, i = read_primitive_values(lines, i, count)
          parent[key] = values
          stack.pop
          next
        end

        if (kv = detect_simple_kv(content))
          k, value = kv
          parent_obj[k] = parse_scalar(value)
          next
        end
      end

      root
    end

    # Count the indentation depth (in spaces) at the beginning of +line+.
    # @param line [String] line from the TOON payload.
    # @return [Integer] number of leading spaces.
    def leading_spaces(line)
      count = 0
      line.each_char do |char|
        break unless char == ' '
        count += 1
      end
      count
    end

    # Convert a scalar token into the appropriate Ruby object.
    # @param str [String] textual token.
    # @return [Object] decoded scalar (String, Numeric, true/false, nil).
    def parse_scalar(str)
      return nil if str == 'null'
      return true if str == 'true'
      return false if str == 'false'

      if quoted?(str)
        return unescape_quoted(str[1..-2])
      end

      return str.to_i if integer_string?(str)
      return str.to_f if float_string?(str)

      str
    end

    # Split a comma-delimited row while preserving quoted delimiters.
    # @param row [String] raw row contents.
    # @return [Array<String>] tokenized column values.
    def split_row(row)
      values = []
      buffer = +''
      in_quotes = false
      escape = false

      row.each_char do |char|
        if in_quotes
          if escape
            buffer << char
            escape = false
          elsif char == '\\'
            escape = true
          elsif char == '"'
            in_quotes = false
          else
            buffer << char
          end
        else
          case char
          when '"'
            in_quotes = true
          when ','
            values << buffer.strip
            buffer = +''
          else
            buffer << char
          end
        end
      end

      values << buffer.strip
      values
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

        row_content = raw.lstrip
        values = split_row(row_content)
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
        values << parse_scalar(raw.lstrip)
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

    # Detect `users[2]{id,name}:` flat tabular header.
    def detect_flat_tabular(content)
      parse_tabular_header(content, expect_key: true)
    end

    # Detect `[2]{id,name}:` nested tabular header.
    def detect_nested_tabular(content)
      parse_tabular_header(content, expect_key: false)
    end

    # Detect `colors[3]:` flat primitive header.
    def detect_flat_primitive(content)
      parse_primitive_header(content, expect_key: true)
    end

    # Detect `[3]:` nested primitive header.
    def detect_nested_primitive(content)
      header = parse_primitive_header(content, expect_key: false)
      header&.last
    end

    # Detect `key:` nested object declaration.
    def detect_nested_object(content)
      return nil unless content.end_with?(':')
      idx = content.index(':')
      return nil unless idx == content.length - 1
      key = content[0...idx]
      valid_key?(key) ? key : nil
    end

    # Detect `key: value` simple assignment.
    def detect_simple_kv(content)
      idx = content.index(':')
      return nil unless idx && idx < content.length - 1

      key = content[0...idx]
      return nil unless valid_key?(key)

      value = content[(idx + 1)..-1]
      [key, value.lstrip]
    end

    # Parse headers like `[n]{fields}:`, with optional leading key.
    def parse_tabular_header(content, expect_key:)
      return nil unless content.end_with?(':')

      header = content[0...-1]
      key = nil
      body = header

      if expect_key
        bracket_idx = header.index('[')
        return nil unless bracket_idx

        key = header[0...bracket_idx]
        return nil unless valid_key?(key)
        body = header[bracket_idx..-1]
      end

      count, fields = extract_count_and_fields(body)
      return nil unless count && fields

      expect_key ? [key, count, fields] : [count, fields]
    end

    # Parse headers like `[n]:`, with optional leading key.
    def parse_primitive_header(content, expect_key:)
      return nil unless content.end_with?(':')

      header = content[0...-1]
      key = nil
      body = header

      if expect_key
        bracket_idx = header.index('[')
        return nil unless bracket_idx

        key = header[0...bracket_idx]
        return nil unless valid_key?(key)
        body = header[bracket_idx..-1]
      end

      count = extract_count(body)
      return nil unless count

      expect_key ? [key, count] : [count]
    end

    # Extract `[n]{fields}` parts from +body+.
    def extract_count_and_fields(body)
      count, remainder = extract_bracket_count(body)
      return unless count
      return unless remainder&.start_with?('{') && remainder.end_with?('}')

      fields = remainder[1..-2]
      [count, fields]
    end

    # Extract `[n]` count from +body+ and return the rest.
    def extract_count(body)
      count, remainder = extract_bracket_count(body)
      return nil unless count && remainder == ''
      count
    end

    # Helper to extract `[n]` prefix from +body+.
    def extract_bracket_count(body)
      return [nil, nil] unless body.start_with?('[')
      close_idx = body.index(']')
      return [nil, nil] unless close_idx

      count_str = body[1...close_idx]
      return [nil, nil] unless integer_string?(count_str)

      remainder = body[(close_idx + 1)..-1] || ''
      [count_str.to_i, remainder]
    end

    # Whether the string is quoted with double quotes.
    def quoted?(str)
      str.length >= 2 && str.start_with?('"') && str.end_with?('"')
    end

    # Unescape \" sequences within a quoted string.
    def unescape_quoted(str)
      return '' if str.empty?
      buffer = +''
      escape = false

      str.each_char do |char|
        if escape
          buffer << char
          escape = false
        elsif char == '\\'
          escape = true
        else
          buffer << char
        end
      end

      buffer
    end

    # Check whether +str+ represents an integer.
    def integer_string?(str)
      return false if str.empty?

      i = 0
      if str.getbyte(0) == 45 # '-'
        return false if str.length == 1
        i += 1
      end

      while i < str.length
        byte = str.getbyte(i)
        return false unless byte >= 48 && byte <= 57
        i += 1
      end
      true
    end

    # Check whether +str+ represents a float with a single decimal point.
    def float_string?(str)
      return false if str.empty?

      i = 0
      if str.getbyte(0) == 45 # '-'
        return false if str.length == 1
        i += 1
      end

      dot_seen = false
      digits_before = 0
      digits_after = 0

      while i < str.length
        byte = str.getbyte(i)
        if byte == 46 # '.'
          return false if dot_seen
          dot_seen = true
        elsif byte >= 48 && byte <= 57
          if dot_seen
            digits_after += 1
          else
            digits_before += 1
          end
        else
          return false
        end
        i += 1
      end

      dot_seen && digits_before.positive? && digits_after.positive?
    end

    # Validate keys (letters, digits, underscore) to avoid malformed headers.
    def valid_key?(key)
      return false if key.empty?
      key.each_byte do |byte|
        next if byte == 95 # _
        next if byte >= 48 && byte <= 57
        next if byte >= 65 && byte <= 90
        next if byte >= 97 && byte <= 122
        return false
      end
      true
    end
  end
end
