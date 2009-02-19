require 'open-uri'

module Ember
  class Template
    ##
    # Builds a processor that evaluates eRuby directives
    # in the given input according to the given options.
    #
    # This processor transforms the given input into an
    # executable Ruby program (provided by the #to_s() method)
    # which is then executed by the #render() method on demand.
    #
    # @param [Hash] options
    #   Additional method parameters, which are all optional:
    #
    #   [#to_s] :result_variable =>
    #     Name of the variable which stores the result of
    #     template evaluation during template evaluation.
    #
    #     The default value is "_erbout".
    #
    #   [String] :input_file =>
    #     Name of the file which contains the given input.  This
    #     is shown in stack traces when reporting error messages.
    #
    #     The default value is "(input)".
    #
    #   [Integer] :input_line =>
    #     Line number at which the given input exists in the :input_file.
    #     This is shown in stack traces when reporting error messages.
    #
    #     The default value is 1.
    #
    #   [boolean] :chomp_before =>
    #     Omit newline before each eRuby directive?
    #
    #     The default value is false.
    #
    #   [boolean] :strip_before =>
    #     Omit spaces and tabs before each eRuby directive?
    #
    #     The default value is false.
    #
    #   [boolean] :chomp_after =>
    #     Omit newline after each eRuby directive?
    #
    #     The default value is false.
    #
    #   [boolean] :strip_after =>
    #     Omit spaces and tabs after each eRuby directive?
    #
    #     The default value is false.
    #
    def initialize input, options = {}
      @options = options
      @program = compile(input.to_s)
    end

    ##
    # Builds a template whose body is read from the given source.
    #
    def self.open source, options = {}
      input = Kernel.open(source) {|f| f.read }
      options[:input_file] = source

      new input, options
    end

    ##
    # Returns the executable Ruby program that was assembled from the
    # eRuby template provided as input to the constructor of this class.
    #
    def to_s
      @program
    end

    ##
    # Returns the result of executing the Ruby program for this template
    # (provided by the #to_s() method) inside the given context binding.
    #
    def render(context = TOPLEVEL_BINDING)
      eval @program, context,
        @options[:input_file] || '(input)',
        @options[:input_line] || 1
    end

    private

    OPERATION_ESCAPE   = '%'
    OPERATION_EVALUATE = '='
    OPERATION_COMMENT  = '#'
    OPERATION_LAMBDA   = '|'
    OPERATION_INCLUDE  = '<'

    ##
    # Transforms the given eRuby template into an executable Ruby program.
    #
    def compile template
      program = Program.new(@options[:result_variable] || :_erbout)

      # convert "% at beginning of line" usage into <% normal %> usage
      if @options[:shorthand]
        i = 0; contents, directives = # even/odd partition
          template.split(/(<%(?:.(?!<%))*?%>)/m).partition { (i += 1) & 1 == 1 }

        # only process the content; do not touch the directives
        # because they may contain code lines beginning with "%"
        contents.each do |content|
          content.gsub! %r{^([[:blank:]]*)(%.*)}, '\1<\2%>'
        end

        template = contents.zip(directives).join
      end

      # compile the template into an executable Ruby program
      chunks = template.split(/(\r?\n?)([[:blank:]]*)<%((?:.(?!<%))*?)%>([[:blank:]]*)(\r?\n?)/m)

      until chunks.empty?
        before_content, before_newline, before_spacing,
        directive, after_spacing, after_newline = chunks.slice!(0, 6)

        if directive
          operation = directive[0, 1]
          arguments = directive[1..-1]
        end

        if before_content
          lines = before_content.split(/^/)

          while line = lines.shift
            program.text line
            program.line unless lines.empty?
          end
        end

        if before_newline && !before_newline.empty? && !@options[:chomp_before]
          program.text before_newline
          program.line
        end

        if before_spacing && !before_spacing.empty? && !@options[:strip_before]
          program.text before_spacing
        end

        if operation
          case operation
          when OPERATION_ESCAPE
            program.text "<%#{arguments}%>"

          when OPERATION_EVALUATE
            program.expr arguments

          when OPERATION_COMMENT
            program.code directive.gsub(/\S/, ' ')

          when OPERATION_LAMBDA
            arguments =~ /(\bdo\b)?\s*(\|.*?\|)?\s*\z/
            program.code "#{$`} #{$1 || 'do'} #{$2}"

          when OPERATION_INCLUDE
            program.code "::Ember::Template.open((#{arguments}), #{@options.inspect}).render(Kernel.binding)"

          else
            program.code directive
          end
        end

        if after_spacing && !after_spacing.empty? && !@options[:strip_after]
          program.text after_spacing
        end

        if after_newline && !after_newline.empty?
          program.text after_newline unless @options[:chomp_after]
          program.line
        end
      end

      program.compile
    end

    class Program
      ##
      # Transforms this program into Ruby code which uses
      # the given variable name as the evaluation buffer.
      #
      def initialize result_variable
        @var   = result_variable
        @lines = [] # each line is composed of multiple statements
      end

      ##
      # Begins a new line in the program's source code.
      #
      def line
        @lines << []
      end

      ##
      # Schedules the given text to be inserted verbatim
      # into the evaluation buffer when this program is run.
      #
      def text value
        # combine adjacent text statements to reduce code size
        if prev = insertion_point.last and prev.type == :text
          prev.value << value
        else
          statement :text, value
        end
      end

      ##
      # Schedules the given Ruby code to be
      # evaluated when this program is run.
      #
      def code value
        statement :code, value
      end

      ##
      # Schedules the given Ruby code to be evaluated and inserted
      # into the evaluation buffer when this program is run.
      #
      def expr value
        statement :expr, value
      end

      ##
      # Transforms this program into executable Ruby source code.
      #
      def compile
        '(%s=[]; %s; %s.join)' % [
          @var,
          @lines.map {|l| l.map {|s| s.compile @var }.join('; ') }.join("\n"),
          @var,
        ]
      end

      private

      def insertion_point
        line if @lines.empty?
        @lines.last
      end

      def statement *args
        insertion_point << Statement.new(*args)
      end

      Statement = Struct.new :type, :value

      class Statement
        def compile result_variable
          case type
          when :code then value
          when :expr then "#{result_variable} << (#{value})"
          when :text then "#{result_variable} << #{value.inspect}"
          else            raise ArgumentError, type
          end
        end
      end
    end
  end
end