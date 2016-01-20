module Gitlab
  module Diff
    class InlineDiffMarker
      attr_accessor :raw_line, :rich_line

      def initialize(raw_line, rich_line = raw_line)
        @raw_line = raw_line
        @rich_line = rich_line
      end

      def mark(line_inline_diffs)
        offset = 0
        line_inline_diffs.each do |inline_diff_range|
          # Map the inline-diff range based on the raw line to character positions in the rich line
          inline_diff_positions = position_mapping[inline_diff_range].flatten
          # Turn the array of character positions into ranges
          marker_ranges = collapse_ranges(inline_diff_positions)

          # Mark each range
          marker_ranges.each do |range|
            offset = insert_around_range(rich_line, range, "<span class='idiff'>", "</span>", offset)
          end
        end

        rich_line
      end

      private

      # Mapping of character positions in the raw line, to the rich (highlighted) line
      def position_mapping
        @position_mapping ||= begin
          mapping = []
          rich_pos = 0
          (0..raw_line.length).each do |raw_pos|
            rich_char = rich_line[rich_pos]

            # The raw and rich lines are the same except for HTML tags,
            # so skip over any `<...>` segment
            while rich_char == '<'
              until rich_char == '>'
                rich_pos += 1
                rich_char = rich_line[rich_pos]
              end

              rich_pos += 1
              rich_char = rich_line[rich_pos]
            end

            # multi-char HTML entities in the rich line correspond to a single character in the raw line
            if rich_char == '&'
              multichar_mapping = [rich_pos]
              until rich_char == ';'
                rich_pos += 1
                multichar_mapping << rich_pos
                rich_char = rich_line[rich_pos]
              end

              mapping[raw_pos] = multichar_mapping
            else
              mapping[raw_pos] = rich_pos
            end

            rich_pos += 1
          end

          mapping
        end
      end

      # Takes an array of integers, and returns an array of ranges covering the same integers
      def collapse_ranges(positions)
        return [] if positions.empty?
        ranges = []

        start = prev = positions[0]
        range = start..prev
        positions[1..-1].each do |pos|
          if pos == prev + 1
            range = start..pos
            prev = pos
          else
            ranges << range
            start = prev = pos
            range = start..prev
          end
        end
        ranges << range

        ranges
      end

      # Inserts tags around the characters identified by the given range
      def insert_around_range(text, range, before, after, offset = 0)
        text.insert(offset + range.begin, before)
        offset += before.length

        text.insert(offset + range.end + 1, after)
        offset += after.length

        offset
      end
    end
  end
end
