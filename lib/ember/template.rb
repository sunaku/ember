require 'pathname'

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
    # eRuby directives that contribute to the output of
    # the given template are called "vocal" directives.
    # Those that do not are called "silent" directives.
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
    #   [boolean] :continue_result =>
    #     Append to the result variable if it already exists?
    #
    #     The default value is false.
    #
    #   [String] :source_file =>
    #     Name of the file which contains the given input.  This
    #     is shown in stack traces when reporting error messages.
    #
    #     The default value is "SOURCE".
    #
    #   [Integer] :source_line =>
    #     Line number at which the given input exists in the :source_file.
    #     This is shown in stack traces when reporting error messages.
    #
    #     The default value is 1.
    #
    #   [boolean] :shorthand =>
    #     Treat lines beginning with "%" as eRuby directives.
    #
    #     The default value is false.
    #
    #   [boolean] :infer_end =>
    #     Add missing <% end %> statements based on indentation.
    #
    #     The default value is false.
    #
    #   [boolean] :unindent =>
    #     Unindent the content of eRuby blocks (everything
    #     between <% do %> ...  <% end %>) hierarchically.
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
    # If the source is a relative path, it will be resolved
    # relative to options[:source_file] if that is a valid path.
    #
    def self.load_file path, options = {}
      # resolve relative path to path file
      unless Pathname.new(path).absolute?
        if base = options[:source_file] and File.exist? base
          # target is relative to the file in
          # which the include directive exists
          path = File.join(File.dirname(base), path)
        end
      end

      new File.read(path), options.merge(:source_file => path)
    end

    ##
    # Returns the executable Ruby program that was assembled from the
    # eRuby template provided as input to the constructor of this class.
    #
    attr_reader :program

    ##
    # Returns the result of executing the Ruby program for this template
    # (provided by the #to_s() method) inside the given context binding.
    #
    def render(context = TOPLEVEL_BINDING)
      eval @program, context,
        (@options[:source_file] || :SOURCE).to_s,
        (@options[:source_line] || 1).to_i
    end


    private


    OPERATION_EVALUATE      = '='
    OPERATION_COMMENT       = '#'
    OPERATION_LAMBDA        = '|'
    OPERATION_INCLUDE       = '+'
    OPERATION_TEMPLATE      = '*'
    OPERATION_INSERT        = '^'

    VOCAL_OPERATIONS        = [
                                OPERATION_EVALUATE,
                                OPERATION_INCLUDE,
                                OPERATION_TEMPLATE,
                              ]

    DIRECTIVE_HEAD          = '<%'
    DIRECTIVE_BODY          = '(?:(?#
                                there is nothing here before the alternation
                                because we want to match the "<%%>" base case
                              )|[^%](?:.(?!<%))*?)'
    DIRECTIVE_TAIL          = '-?%>'

    NEWLINE                 = '\r?\n'
    SPACING                 = '[[:blank:]]*'

    CHUNKS_REGEXP           = /#{
                                '(%s?)(%s)%s(%s)%s' % [
                                  NEWLINE,
                                  SPACING,
                                  DIRECTIVE_HEAD,
                                  DIRECTIVE_BODY,
                                  DIRECTIVE_TAIL,
                                ]
                              }/mo

    MARGIN_REGEXP           = /^#{SPACING}(?=\S)/o

    LAMBDA_BEGIN_REGEXP     = /\b(do)\b\s*(\|.*?\|)?\s*$/

    block_begin_keywords    = [
                                # generic
                                :begin,

                                # conditional
                                :if,
                                :unless,
                                :case,

                                # loops
                                :for,
                                :while,
                                :until
                              ]

    block_continue_keywords = [
                                # generic
                                :rescue,
                                :ensure,

                                # conditional
                                :else,
                                :elsif,
                                :when
                              ]

    block_end_keywords      = [
                                # generic
                                :end
                              ]

    keyword_regexp_builder  = lambda do |keywords|
                                /^\s*\b(#{keywords.join '|'})\b/
                              end

    BLOCK_BEGIN_REGEXP      = keyword_regexp_builder[block_begin_keywords]
    BLOCK_CONTINUE_REGEXP   = keyword_regexp_builder[block_continue_keywords]
    BLOCK_END_REGEXP        = keyword_regexp_builder[block_end_keywords]

    ##
    # Transforms the given eRuby template into an executable Ruby program.
    #
    def compile template
      program = Program.new(
        @options[:result_variable] || :_erbout,
        @options[:continue_result]
      )

      # convert "% at beginning of line" usage into <% normal %> usage
        if @options[:shorthand]
          i = 0
          contents, directives =
            template.split(/(#{DIRECTIVE_HEAD}#{DIRECTIVE_BODY}#{DIRECTIVE_TAIL})/mo).
            partition { (i += 1) & 1 == 1 } # even/odd partition

          # only process the content; do not touch the directives
          # because they may contain code lines beginning with "%"
          contents.each do |content|
            # process unescaped directives
            content.gsub! %r/^(#{SPACING})(%[^%].*)$/o, '\1<\2%>'

            # unescape escaped directives
            content.gsub! %r/^(#{SPACING})(%)%/o, '\1\2'
          end

          template = contents.zip(directives).join
        end

      # compile the template into an executable Ruby program
        margins = []
        crowns = []

        # parser actions
          end_block = lambda do
            raise 'attempt to close unopened block' if margins.empty?
            STDERR.puts "end block => YES"
            margins.pop
            crowns.pop
          end

          emit_end = lambda do
            STDERR.puts "emit end => YES"
            program.code :end
          end

          infer_end = lambda do |line, skip_last_level|
            STDERR.puts "inferring end for line=#{line.inspect}"
            STDERR.puts "inferring end on margins=#{margins.inspect}"

            if current = line[MARGIN_REGEXP]
              # determine the number of levels to ascend
              levels = margins.select {|previous| current < previous }

              # in the case of block-continuation and -ending directives,
              # we must not ascend the very last (outmost) level at this
              # point of the algorithm.  that work will be done later on
              levels.pop if skip_last_level

              levels.each do
                end_block.call
                emit_end.call
                STDERR.puts "infer end => YES, new margins=#{margins.inspect}"
              end
            end
          end

          unindent = lambda do |line|
            STDERR.puts ">>> unindenting #{line.inspect} for margins: #{margins.inspect}"
            if margin = margins.last and crown = crowns.first
              line.sub(/^#{margin}/, crown)
            else
              line
            end
          end

          process_line = lambda do |content_type, before_newline, before_spacing, content, after_margin|
            have_before_newline = before_newline && !before_newline.empty?
            on_separate_line = have_before_newline || program.empty?
            can_infer_end = @options[:infer_end] && have_before_newline && before_spacing

            case content_type
            when :content
              line = "#{before_spacing}#{content}"

              if can_infer_end
                infer_end.call line, false
              end

              if have_before_newline
                program.text before_newline
              end

              if on_separate_line
                program.line

                if @options[:unindent]
                  STDERR.puts ">>> before unindent=#{line.inspect}"
                  line = unindent.call(line)
                  STDERR.puts ">>> after unindent=#{line.inspect}"
                end
              end

              # unescape escaped directives
              line.gsub! '<%%', '<%'

              program.text line

            when :directive
              directive = content
              operation = directive[0, 1]
              arguments = directive[1..-1]

              is_vocal_directive = VOCAL_OPERATIONS.include? operation
              is_single_line_directive = directive !~ /\n/

              # don't bother parsing multi-line code directives
              if can_infer_end && (is_vocal_directive || is_single_line_directive)
                # '.' stands in place of the directive body,
                # which may be empty in the case of '<%%>'
                infer_end.call before_spacing + '.',
                               arguments =~ BLOCK_END_REGEXP ||
                               arguments =~ BLOCK_CONTINUE_REGEXP
              end

              # omit before_newline for silent directives
              if have_before_newline && is_vocal_directive
                program.text before_newline
              end

              if on_separate_line
                program.line
              end

              if before_spacing && !before_spacing.empty?
                # XXX: do not modify before_spacing because it is
                #      used later on in the code to infer_end !!!
                margin = before_spacing

                if on_separate_line && @options[:unindent]
                  STDERR.puts ">>> before unindent=#{margin.inspect}"
                  margin = unindent.call(margin)
                  STDERR.puts ">>> after unindent=#{margin.inspect}"
                end

                # omit before_spacing for silent directives
                if !on_separate_line || is_vocal_directive
                  program.text margin
                end
              end

              begin_block = lambda do
                margins << after_margin
                crowns  << before_spacing
                STDERR.puts "begin block => YES, margins=#{margins.inspect}"
              end

              handle_nested_template = lambda do |meth|
                program.code "::Ember::Template.#{meth}((#{arguments}), #{@options.inspect}.merge!(:continue_result => true)).render(binding)"
              end

              if operation && !operation.empty?
                case operation
                when OPERATION_EVALUATE
                  program.expr arguments

                when OPERATION_COMMENT
                  program.code directive.gsub(/\S/, ' ')

                when OPERATION_LAMBDA
                  arguments =~ /(\bdo\b)?\s*(\|.*?\|)?\s*\z/
                  program.code "#{$`} #{$1 || 'do'} #{$2}"

                  begin_block.call

                when OPERATION_TEMPLATE
                  handle_nested_template.call :new

                when OPERATION_INCLUDE
                  handle_nested_template.call :load_file

                when OPERATION_INSERT
                  program.code "::File.read(#{arguments})"

                else
                  program.code directive

                  if is_single_line_directive
                    case directive
                    when BLOCK_BEGIN_REGEXP, LAMBDA_BEGIN_REGEXP
                      STDERR.puts "begin block on directive:  #{directive.inspect}"
                      begin_block.call

                    when BLOCK_CONTINUE_REGEXP
                      STDERR.puts "SWITCH block on directive:  #{directive.inspect}"
                      end_block.call
                      begin_block.call

                    when BLOCK_END_REGEXP
                      STDERR.puts "end block on directive:  #{directive.inspect}"
                      end_block.call
                    end
                  end
                end

              end
            else
              raise ArgumentError, content_type
            end
          end

        # parser logic
          chunks = template.split(CHUNKS_REGEXP)

          while true
            # raw content before the directive
            if before_content = chunks.shift
              lines = before_content.scan(/(#{NEWLINE}|\A)(#{SPACING})(.*)()/o)

              lines.each do |matches|
                STDERR.puts '', '', '', :content, matches.inspect
                process_line.call :content, *matches
              end
            end

            break unless chunks.length >= 3

            # the directive itself
            args = chunks.slice!(0, 3)

            # '.' stands in place of the directive body,
            # which may be empty in the case of '<%%>'
            after_content = chunks.first(3).join + '.' # look ahead
            after_margin = after_content[MARGIN_REGEXP]
            args << after_margin

            STDERR.puts '', '', '', :directive, args.inspect
            # STDERR.puts "<<< after_content: #{after_content.inspect}"
            # STDERR.puts "<<< after_margin: #{after_margin.inspect}"

            process_line.call :directive, *args
          end

        # handle leftover blocks
          if @options[:infer_end]
            margins.each do
              emit_end.call
            end
          else
            warn "There are at least #{margins.length} missing '<% end %>' statements in the eRuby template." unless margins.empty?
          end

      program.compile
    end

    class Program
      ##
      # Transforms this program into Ruby code which uses
      # the given variable name as the evaluation buffer.
      #
      # If continue_result is true, the evaluation buffer is
      # reused if it already exists in the rendering context.
      #
      def initialize result_variable, continue_result
        @result_variable = result_variable
        @continue_result = continue_result
        @source_lines = [] # each line is composed of multiple statements
      end

      ##
      # Returns true if there are no source lines in this program.
      #
      def empty?
        @source_lines.empty?
      end

      ##
      # Begins a new line in the program's source code.
      #
      def line
        @source_lines << []
      end

      ##
      # Schedules the given text to be inserted verbatim
      # into the evaluation buffer when this program is run.
      #
      def text value
        # don't bother emitting empty strings
        return if value.empty?

        # combine adjacent statements to reduce code size
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
        '(%s %s []; %s; %s.join)' % [
          @result_variable,
          @continue_result ? '||=' : '=',

          @source_lines.map do |line|
            line.map {|stmt| stmt.compile @result_variable }.join('; ')
          end.join("\n"),

          @result_variable,
        ]
      end

      private

      def insertion_point
        line if empty?
        @source_lines.last
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
          else raise ArgumentError, type
          end
        end
      end
    end
  end
end