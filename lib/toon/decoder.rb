module Toon
  module Decoder
    module_function

    def parse(str, **opts)
      lines = str.gsub("\r\n", "\n").split("\n")
      parse_lines(lines)
    end

    def load(io, **opts)
      parse(io.read, **opts)
    end

    def parse_lines(lines)
      root = {}
      stack = [ { indent: -1, obj: root, parent: nil, key: nil } ]

      i = 0
      while i < lines.length
        raw = lines[i].rstrip
        i += 1

        next if raw.strip.empty? || raw.strip.start_with?('#')

        indent = leading_spaces(raw)
        content = raw.strip

        # Fix indentation
        while indent <= stack.last[:indent]
          stack.pop
        end

        current = stack.last
        parent_obj = current[:obj]

        # ============================================================
        # FLAT TABULAR ARRAY: users[2]{id,name}:
        # ============================================================
        if m = content.match(/^(\w+)\[(\d+)\]\{([^}]*)\}:$/)
          key     = m[1]
          count   = m[2].to_i
          fields  = m[3].split(",").map(&:strip)

          rows = []
          count.times do
            row = lines[i]&.strip
            i += 1
            next unless row
            values = split_row(row.strip)
            rows << Hash[fields.zip(values)]
          end

          parent_obj[key] = rows
          next
        end

        # ============================================================
        # FLAT PRIMITIVE ARRAY: colors[3]:
        # ============================================================
        if m = content.match(/^(\w+)\[(\d+)\]:$/)
          key   = m[1]
          count = m[2].to_i

          values = []
          count.times do
            row = lines[i]&.strip
            i += 1
            next unless row
            values << parse_scalar(row)
          end

          parent_obj[key] = values
          next
        end

        # ============================================================
        # NESTED OBJECT KEY: key:
        # ============================================================
        if m = content.match(/^(\w+):$/)
          key = m[1]
          new_obj = {}

          parent_obj[key] = new_obj
          stack << { indent: indent, obj: new_obj, parent: parent_obj, key: key }
          next
        end

        # Refresh frame for nested array parsing
        frame = stack.last
        parent = frame[:parent]
        key    = frame[:key]

        # ============================================================
        # NESTED TABULAR ARRAY:
        #   users:
        #     [2]{id,name}:
        # ============================================================
        if m = content.match(/^\[(\d+)\]\{([^}]*)\}:$/)
          count   = m[1].to_i
          fields  = m[2].split(',').map(&:strip)

          rows = []
          count.times do
            row = lines[i]&.strip
            i += 1
            next unless row
            values = split_row(row).map { |v| parse_scalar(v) }
            rows << Hash[fields.zip(values)]
          end

          parent[key] = rows
          stack.pop
          next
        end

        # ============================================================
        # NESTED PRIMITIVE ARRAY:
        #   colors:
        #     [3]:
        # ============================================================
        if m = content.match(/^\[(\d+)\]:$/)
          count = m[1].to_i

          if key.nil?
            raise Toon::Error, "Malformed TOON: array header '#{content}' must be under a key (e.g., 'colors:')"
          end

          values = []
          count.times do
            row = lines[i]&.strip
            i += 1
            next unless row
            values << parse_scalar(row)
          end

          parent[key] = values
          stack.pop
          next
        end

        # ============================================================
        # SIMPLE KEY: VALUE
        # ============================================================
        if m = content.match(/^(\w+):\s*(.*)$/)
          k = m[1]
          v = parse_scalar(m[2])
          parent_obj[k] = v
          next
        end
      end

      root
    end



    def leading_spaces(line)
      line[/^ */].length
    end

    def parse_scalar(str)
      # strip quotes
      if str == 'null' then nil
      elsif str == 'true' then true
      elsif str == 'false' then false
      elsif str.match?(/^".*"$/)
        str[1..-2].gsub('\\"','"')
      elsif str =~ /^-?\d+$/
        str.to_i
      elsif str =~ /^-?\d+\.\d+$/
        str.to_f
      else
        str
      end
    end

    def split_row(row)
      # simplistic split on comma that ignores quoted commas - naive
      row.scan(/(?:\"([^\"]*)\"|([^,]+))(?:,|$)/).map { |m| (m[0] || m[1]).to_s.strip }
    end
  end
end
