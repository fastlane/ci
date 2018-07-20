module FastlaneCI
  ##
  # little helper class for parsing ansi to html
  class Ansi
    PATTERN = /\\u001b\[([0-9;]+)?m/m
    CODES = {
      "1" => "font-weight: bold",
      "3" => "font-style: italic",
      "4" => "text-decoration: underline",
      "30" => "color: #262626", # black
      "31" => "color: #d30102", # red'
      "32" => "color: #859900", # green
      "33" => "color: #b58900", # yellow
      "34" => "color: #268bd2", # blue
      "35" => "color: #d33682", # magenta
      "36" => "color: #2aa198", # cyan
      "37" => "color: #e4e4e4"  # white
    }
    def self.to_html(text)
      new(text).to_html
    end

    def initialize(text)
      @scanner = StringScanner.new(text)
    end

    ##
    # remove ansi codes, returning text
    def strip
      text = ""
      while (segment = @scanner.scan_until(PATTERN))
        match = @scanner.matched
        text << segment.sub(match, "")
      end
      text << @scanner.rest

      return text
    end

    ##
    # this can probably be re-written to be recursive.
    def to_html
      html = ""
      while (segment = @scanner.scan_until(PATTERN))
        stack_count = 1
        match = @scanner.matched
        if @scanner[1] == "0"
          tag = "</span>" * stack_count
          stack_count = 1
        else
          style = @scanner[1].gsub(/\d+/) { |code| CODES[code] }
          tag = "<span style='#{style}'>"
          stack_count += 1
        end
        html << segment.sub(match, tag)
      end
      html << @scanner.rest

      return html
    end
  end
end
