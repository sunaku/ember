require 'pathname'

module Ember
  class Template
    ##
    # Returns the executable Ruby program that was assembled from the
    # eRuby template provided as input to the constructor of this class.
    #
    attr_reader :program

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
    # Returns the result of executing the Ruby program for this template
    # (provided by the #to_s() method) inside the given context binding.
    #
    def render(context = TOPLEVEL_BINDING)
      eval @program, context,
        (@options[:source_file] || :SOURCE).to_s,
        (@options[:source_line] || 1).to_i
    end

    class << self
      ##
      # Builds a template whose body is read from the given source.
      #
      # If the source is a relative path, it will be resolved
      # relative to options[:source_file] if that is a valid path.
      #
      def load_file path, options = {}
        path = resolve_path(path, options)
        new File.read(path), options.merge(:source_file => path)
      end

      ##
      # Returns the contents of the given file, which can be relative to
      # the current template in which this command is being executed.
      #
      # If the source is a relative path, it will be resolved
      # relative to options[:source_file] if that is a valid path.
      #
      def read_file path, options = {}
        File.read resolve_path(path, options)
      end

      private

      def resolve_path path, options = {}
        unless Pathname.new(path).absolute?
          if base = options[:source_file] and File.exist? base
            # target is relative to the file in
            # which the include directive exists
            path = File.join(File.dirname(base), path)
          end
        end

        path
      end
    end


    private

    OPERATIONS            = [
                              OPERATION_EVAL_EXPRESSION      = '=',
                              OPERATION_CODE_COMMENT         = '#',
                              OPERATION_BEGIN_LAMBDA         = '|',
                              OPERATION_EVAL_TEMPLATE_FILE   = '+',
                              OPERATION_EVAL_TEMPLATE_STRING = '*',
                              OPERATION_INSERT_PLAIN_FILE    = '<',
                            ]

    VOCAL_OPERATIONS      = [
                              OPERATION_EVAL_EXPRESSION,
                              OPERATION_EVAL_TEMPLATE_FILE,
                              OPERATION_EVAL_TEMPLATE_STRING,
                            ]

    DIRECTIVE_HEAD        = '<%'
    DIRECTIVE_BODY        = '(?:(?#
                                there is nothing here before the alternation
                                because we want to match the "<%%>" base case
                              )|[^%](?:.(?!<%))*?)'
    DIRECTIVE_TAIL        = '-?%>'

    SHORTHAND_HEAD        = '%'
    SHORTHAND_BODY        = '(?:(?#
                                there is nothing here before the alternation
                                because we want to match the "<%%>" base case
                              )|[^%].*)'
    SHORTHAND_TAIL        = '$'

    NEWLINE               = '\r?\n'
    SPACING               = '[[:blank:]]*'

    MARGIN_REGEXP         = /^#{SPACING}(?=\S)/o

    LAMBDA_BEGIN_REGEXP   = /\b(do)\b\s*(\|.*?\|)?\s*$/

    build_keyword_regexp  = lambda {|*words| /\A\s*\b(#{words.join '|'})\b/ }

    BLOCK_BEGIN_REGEXP    = build_keyword_regexp[
                              # generic
                              :begin,

                              # conditional
                              :if, :unless, :case,

                              # loops
                              :for, :while, :until
                            ]

    BLOCK_CONTINUE_REGEXP = build_keyword_regexp[
                              # generic
                              :rescue, :ensure,

                              # conditional
                              :else, :elsif, :when
                            ]

    BLOCK_END_REGEXP      = build_keyword_regexp[
                              # generic
                              :end
                            ]

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
            content.gsub! %r/^(#{SPACING})(#{SHORTHAND_HEAD}#{SHORTHAND_BODY})#{SHORTHAND_TAIL}/o, '\1<\2%>'

            # unescape escaped directives
            content.gsub! %r/^(#{SPACING})(#{SHORTHAND_HEAD})#{SHORTHAND_HEAD}/o, '\1\2'
          end

          template = contents.zip(directives).join
        end

      # build program from template
        margins = []
        crowns  = []

        # parser actions
          close_block = lambda do
            raise 'cannot close unopened block' if margins.empty?
            margins.pop
            crowns.pop
          end

          emit_end = lambda do
            program.code :end
          end

          infer_end = lambda do |line, skip_last_level|
            if @options[:infer_end] and
               program.new_line? and
               not line.empty? and
               current = line[MARGIN_REGEXP]
            then
              # number of levels to ascend
              levels = margins.select {|previous| current < previous }

              # in the case of block-continuation and -ending directives,
              # we must not ascend the very last (outmost) level at this
              # point of the algorithm.  that work will be done later on
              levels.pop if skip_last_level

              levels.each do
                p :infer => line if $DEBUG
                close_block.call
                emit_end.call
              end
            end
          end

          unindent = lambda do |line|
            if @options[:unindent] and
               program.new_line? and
               margin = margins.last and
               crown = crowns.first
            then
              line.sub(/^#{margin}/, crown)
            else
              line
            end
          end

          process_content = lambda do |content|
            content.split(/^/).each do |content_line|
              # before_spacing
              infer_end.call content_line, false
              content_line = unindent.call(content_line)

              # content + after_spacing
              content_line.gsub! '<%%', '<%' # unescape escaped directives
              program.text content_line

              # after_newline
              program.new_line if content_line =~ /\n\z/
            end
          end

          process_directive = lambda do |content_line, before_spacing, directive, after_spacing, after_newline, after_content|

            operation = directive[0, 1]

            if OPERATIONS.include? operation
              arguments = directive[1..-1]
            else
              operation = ''
              arguments = directive
            end

            is_vocal = VOCAL_OPERATIONS.include? operation
            is_single_line = arguments !~ /\n/

            # before_spacing
              after_margin = after_content[MARGIN_REGEXP]

              open_block = lambda do
                margins << after_margin
                crowns  << before_spacing
              end

              # '.' stands in place of the directive body,
              # which may be empty in the case of '<%%>'
              infer_end.call before_spacing + '.',
                operation.empty? &&
                arguments =~ BLOCK_END_REGEXP ||
                arguments =~ BLOCK_CONTINUE_REGEXP

              program.text unindent.call(before_spacing) if is_vocal

            # directive
              template_class_name  = '::Ember::Template'
              nested_template_args = "(#{arguments}), #{@options.inspect}"

              nest_template_with = lambda do |meth|
                program.code "#{template_class_name}.#{meth}(#{
                  nested_template_args
                }.merge!(:continue_result => true)).render(binding)"
              end

              case operation
              when OPERATION_EVAL_EXPRESSION
                program.expr arguments

              when OPERATION_CODE_COMMENT
                program.code directive.gsub(/\S/, ' ')

              when OPERATION_BEGIN_LAMBDA
                arguments =~ /(\bdo\b)?\s*(\|.*?\|)?\s*\z/
                program.code "#{$`} #{$1 || 'do'} #{$2}"

                p :begin => directive if $DEBUG
                open_block.call

              when OPERATION_EVAL_TEMPLATE_STRING
                nest_template_with[:new]

              when OPERATION_EVAL_TEMPLATE_FILE
                nest_template_with[:load_file]

              when OPERATION_INSERT_PLAIN_FILE
                program.expr "#{template_class_name}.read_file(#{nested_template_args})"

              else
                program.code arguments

                if is_single_line # don't bother parsing multi-line directives
                  case arguments
                  when BLOCK_BEGIN_REGEXP, LAMBDA_BEGIN_REGEXP
                    p :begin => directive if $DEBUG
                    open_block.call

                  when BLOCK_CONTINUE_REGEXP
                    p :continue => directive if $DEBUG
                    close_block.call
                    open_block.call

                  when BLOCK_END_REGEXP
                    p :close => directive if $DEBUG
                    close_block.call
                  end
                end
              end

            # after_spacing
              program.text after_spacing if is_vocal || after_newline.empty?

            # after_newline
              program.text after_newline if is_vocal
              program.new_line unless after_newline.empty?
          end

        # parser logic
          directive_matches = template.scan(/#{
            '((%s)%s(%s)%s(%s)(%s?))' % [
              SPACING,
              DIRECTIVE_HEAD,
              DIRECTIVE_BODY,
              DIRECTIVE_TAIL,
              SPACING,
              NEWLINE,
            ]
          }/mo)

          directive_matches.each do |match|
            # iteratively whittle the template
            before_content, after_content = template.split(match[0], 2)
            template = after_content

            # process the raw content before the directive
            process_content.call before_content

            # process the directive itself
            args = match + [after_content]
            process_directive.call(*args)
          end

          # process remaining raw content *after* last directive
          process_content.call template

        # missing ends
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
      def new_line
        @source_lines << []
      end

      ##
      # Returns true if a new (blank) line is
      # ready in the program's source code.
      #
      def new_line?
        insertion_point.empty?
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

          @source_lines.map do |source_line|
            compiled_line = []
            combine_prev = false

            source_line.each do |stmt|
              is_code = stmt.type == :code
              is_expr = stmt.type == :expr

              # ignore empty statements
              next if (is_code || is_expr) && stmt.value.to_s !~ /\S/

              if is_code
                compiled_line << stmt.value
                combine_prev = false

              else
                code =
                  if is_expr
                    " << (#{stmt.value})"
                  else
                    " << #{stmt.value.inspect}"
                  end

                if combine_prev
                  compiled_line.last << code
                else
                  compiled_line << @result_variable.to_s + code
                end

                combine_prev = true
              end
            end

            compiled_line.join('; ')

          end.join("\n"),

          @result_variable,
        ]
      end

      private

      def insertion_point
        new_line if empty?
        @source_lines.last
      end

      def statement *args
        insertion_point << Statement.new(*args)
      end

      Statement = Struct.new :type, :value
    end
  end
end