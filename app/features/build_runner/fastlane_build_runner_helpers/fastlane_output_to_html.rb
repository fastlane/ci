module FastlaneCI
  # Responsible for converting JSON based message information, e.g.
  #
  # {
  #   type: success,
  #   message: "Step: default_platform"
  # }
  #
  # to HTML code, e.g.
  #
  # <p class="success">Step: default_platform</p>
  #
  # It does so for each row
  #
  class FastlaneOutputToHtml
    class << self
      def convert_row(row)
        wrapping_type = "p"
        wrapping_class = type_to_class(row.type)

        return <<~HTML
          <#{wrapping_type} class=\"#{wrapping_class}\">#{format_string(row.time)}#{row.message}</#{wrapping_type}>
        HTML
      end

      def type_to_class(type)
        if [:crash, :shell_error, :build_failure, :test_failure, :abort].include?(type)
          return "crash"
        elsif type == :user_error
          return "user_error"
        else
          return type.to_s
        end
      end

      def format_string(datetime)
        "[#{datetime.strftime('%H:%M:%S')}]: "
      end
    end
  end
end
