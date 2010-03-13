#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'pathname'

module Ember
  class Template
    ##
    # Builds a processor that evaluates eRuby directives
    # in the given input according to the given options.
    #
    # This processor transforms the given input
    # into an executable Ruby program (provided
    # by the #program() method) which is then
    # executed by the #render() method on demand.
    #
    # eRuby directives that contribute to the output of
    # the given template are called "vocal" directives.
    # Those that do not are called "silent" directives.
    #
    # ==== Options
    #
    # [:result_variable]
    #   Name of the variable which stores the result of
    #   template evaluation during template evaluation.
    #
    #   The default value is "_erbout".
    #
    # [:continue_result]
    #   Append to the result variable if it already exists?
    #
    #   The default value is false.
    #
    # [:source_file]
    #   Name of the file which contains the given input.  This
    #   is shown in stack traces when reporting error messages.
    #
    #   The default value is "SOURCE".
    #
    # [:source_line]
    #   Line number at which the given input exists in the :source_file.
    #   This is shown in stack traces when reporting error messages.
    #
    #   The default value is 1.
    #
    # [:shorthand]
    #   Treat lines beginning with "%" as eRuby directives?
    #
    #   The default value is false.
    #
    # [:infer_end]
    #   Add missing <% end %> statements based on indentation?
    #
    #   The default value is false.
    #
    # [:unindent]
    #   Unindent the content of eRuby blocks (everything
    #   between <% do %> ...  <% end %>) hierarchically?
    #
    #   The default value is false.
    #
    def initialize input, options = {}
      @options = options
      @render_context_id = object_id
      @compile = compile(input.to_s)
    end

    ##
    # Ruby source code assembled from the eRuby template
    # provided as input to the constructor of this class.
    #
    def program
      @compile
    end

    @@contexts = {}

    ##
    # Returns the result of executing the Ruby program for this template
    # (provided by the #program() method) inside the given context binding.
    #
    def render context = TOPLEVEL_BINDING, parent_context_id = nil
      context ||= @@contexts[parent_context_id] # inherit parent context
      @@contexts[@render_context_id] = context  # provide to children

      result = eval @compile, context,
        (@options[:source_file] || :SOURCE).to_s,
        (@options[:source_line] || 1).to_i

      @@contexts.delete @render_context_id      # free the memory
      result
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

    OPERATION_EVAL_EXPRESSION      = '='
    OPERATION_COMMENT_LINE         = '#'
    OPERATION_BEGIN_LAMBDA         = '|'
    OPERATION_EVAL_TEMPLATE_FILE   = '+'
    OPERATION_EVAL_TEMPLATE_STRING = '~'
    OPERATION_INSERT_PLAIN_FILE    = '<'

    #:stopdoc:

    OPERATIONS            = [
                              OPERATION_COMMENT_LINE,
                              OPERATION_BEGIN_LAMBDA,
                              OPERATION_EVAL_EXPRESSION,
                              OPERATION_EVAL_TEMPLATE_FILE,
                              OPERATION_EVAL_TEMPLATE_STRING,
                              OPERATION_INSERT_PLAIN_FILE,
                            ]

    SILENT_OPERATIONS     = [
                              OPERATION_COMMENT_LINE,
                              OPERATION_BEGIN_LAMBDA,
                            ]

    VOCAL_OPERATIONS      = OPERATIONS - SILENT_OPERATIONS

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

    #:startdoc:

    ##
    # Transforms the given eRuby template into an executable Ruby program.
    #
    def compile template
      @program = Program.new(
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

      # convert single-line comment directives into nothing
        template.gsub!(/^#{SPACING}#{DIRECTIVE_HEAD}##{DIRECTIVE_BODY}#{DIRECTIVE_TAIL}#{SPACING}$/, '')

      # translate template into Ruby code
        @margins = []
        @crowns  = []

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
          process_content before_content

          # process the directive itself
          args = match + [after_content]
          process_directive(*args)
        end

        # process remaining raw content *after* last directive
        process_content template

        # handle missing ends
        if @options[:infer_end]
          @margins.each { emit_end }
        else
          warn "There are at least #{@margins.length} missing '<% end %>' statements in the eRuby template." unless @margins.empty?
        end

      @program.compile
    end

    def close_block
      raise 'cannot close unopened block' if @margins.empty?
      @margins.pop
      @crowns.pop
    end

    def emit_end
      @program.emit_end
    end

    def infer_end line, skip_last_level = false
      if @options[:infer_end] and
         @program.new_line? and
         not line.empty? and
         current = line[MARGIN_REGEXP]
      then
        # number of levels to ascend
        levels = @crowns.select {|previous| current <= previous }.length

        # in the case of block-continuation and -ending directives,
        # we must not ascend the very last (outmost) level at this
        # point of the algorithm.  that work will be done later on
        levels -= 1 if skip_last_level

        levels.times do |i|
          p :infer => line if $DEBUG
          close_block
          emit_end
        end
      end
    end

    ##
    # Returns a new string containing the result of unindentation.
    #
    def unindent line
      if @options[:unindent] and
         @program.new_line? and
         margin = @margins.last and
         crown = @crowns.first
      then
        line.gsub(/^#{margin}/, crown)
      else
        line
      end
    end

    def process_content content
      content.split(/^/).each do |content_line|
        # before_spacing
        infer_end content_line, false
        content_line = unindent(content_line)

        # content + after_spacing
        content_line.gsub! '<%%', '<%' # unescape escaped directives
        @program.emit_text content_line

        # after_newline
        @program.new_line if content_line =~ /\n\z/
      end
    end

    def process_directive content_line, before_spacing, directive, after_spacing, after_newline, after_content
      operation = directive[0, 1]

      if OPERATIONS.include? operation
        arguments = directive[1..-1]
      else
        operation = ''
        arguments = directive
      end

      arguments = unindent(arguments)

      is_vocal = VOCAL_OPERATIONS.include? operation

      # before_spacing
        after_margin = after_content[MARGIN_REGEXP]

        open_block = lambda do
          @margins << after_margin
          @crowns  << before_spacing
        end

        # '.' stands in place of the directive body,
        # which may be empty in the case of '<%%>'
        infer_end before_spacing + '.',
          operation.empty? &&
          arguments =~ BLOCK_END_REGEXP ||
          arguments =~ BLOCK_CONTINUE_REGEXP

        @program.emit_text unindent(before_spacing) if is_vocal

      # directive
        template_class_name  = '::Ember::Template'
        nested_template_args = "(#{arguments}), #{@options.inspect}"

        nest_template_with = lambda do |meth|
          @program.emit_code "#{template_class_name}.#{meth}(#{
            nested_template_args
          }.merge!(:continue_result => true)).render(nil, #{@render_context_id.inspect})"
        end

        case operation
        when OPERATION_EVAL_EXPRESSION
          @program.emit_expr arguments

        when OPERATION_COMMENT_LINE
          @program.emit_code directive.gsub(/\S/, ' ')

        when OPERATION_BEGIN_LAMBDA
          arguments =~ /(\bdo\b)?\s*(\|[^\|]*\|)?\s*\z/
          @program.emit_code "#{$`} #{$1 || 'do'} #{$2}"

          p :begin => directive if $DEBUG
          open_block.call

        when OPERATION_EVAL_TEMPLATE_STRING
          nest_template_with[:new]

        when OPERATION_EVAL_TEMPLATE_FILE
          nest_template_with[:load_file]

        when OPERATION_INSERT_PLAIN_FILE
          @program.emit_expr "#{template_class_name}.read_file(#{nested_template_args})"

        else
          @program.emit_code arguments

          unless arguments =~ /\n/ # don't bother parsing multi-line directives
            case arguments
            when BLOCK_BEGIN_REGEXP, LAMBDA_BEGIN_REGEXP
              p :begin => directive if $DEBUG
              open_block.call

            when BLOCK_CONTINUE_REGEXP
              # reopen because the new block might have a different margin
              p :continue => directive if $DEBUG
              close_block
              open_block.call

            when BLOCK_END_REGEXP
              p :close => directive if $DEBUG
              close_block
            end
          end
        end

      # after_spacing
        @program.emit_text after_spacing if is_vocal || after_newline.empty?

      # after_newline
        @program.emit_text after_newline if is_vocal
        @program.new_line unless after_newline.empty?
    end

    class Program #:nodoc:
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
        ary = insertion_point
        ary.empty? || ary.all? {|stmt| stmt.type == :code }
      end

      ##
      # Schedules the given text to be inserted verbatim
      # into the evaluation buffer when this program is run.
      #
      def emit_text value
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
      def emit_code value
        statement :code, value
      end

      ##
      # Schedules the given Ruby code to be evaluated and inserted
      # into the evaluation buffer when this program is run.
      #
      def emit_expr value
        statement :expr, value
      end

      ##
      # Inserts an <% end %> directive before the
      # oldest non-whitespace statement possible.
      #
      # Preceding lines that only emit whitespace are skipped.
      #
      def emit_end
        ending  = Statement.new(:code, :end)
        current = insertion_point

        can_skip_line = lambda do |line|
          line.empty? ||
          line.all? {|stmt| stmt.type == :text && stmt.value =~ /\A\s*\z/ }
        end

        if can_skip_line[current]
          target = current

          # skip past empty whitespace in previous lines
          @source_lines.reverse_each do |line|
            break unless can_skip_line[line]
            target = line
          end

          target.unshift ending
        else
          current.push ending
        end
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
