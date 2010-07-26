require 'ember/template'
require 'combinatorics'

describe Ember::Template do
  BLANK      = [''] # the empty string
  NEWLINES   = ["\n", "\r\n"]
  SPACES     = [' ', "\t"]
  WHITESPACE = SPACES + NEWLINES
  OPERATIONS = [nil, '=', '#', *WHITESPACE]

  ##
  # Invokes the given block, passing in the result
  # of Array#join, for every possible combination.
  #
  def each_join array
    raise ArgumentError unless block_given?

    array.permutations do |combo|
      yield combo.join
    end
  end

  describe "A template" do
    it "renders single & multi-line comments as nothing" do
      each_join(WHITESPACE) do |s|
        render("<%##{s}an#{s}eRuby#{s}comment#{s}%>").must_equal("")
      end
    end

    it "renders directives with whitespace-only bodies as nothing" do
      each_join(WHITESPACE) do |s|
        OPERATIONS.each do |o|
          render("<%#{o}#{s}%>").must_equal("")
        end
      end
    end

    it "renders escaped directives in unescaped form" do
      render("<%%%>").must_equal("<%%>")

      render("<%% %>").must_equal("<% %>")

      E SyntaxError, "the trailing delimiter must not be unescaped" do
        render("<% %%>")
      end

      render("<%%%%>").must_equal("<%%%>",
        "the trailing delimiter must not be unescaped")

      each_join(WHITESPACE) do |s|
        body = "#{s}an#{s}eRuby#{s}directive#{s}"

        OPERATIONS.each do |o|
          render("<%%#{o}#{body}%>").must_equal("<%#{o}#{body}%>")
        end
      end
    end

    it "renders whitespace surrounding vocal directives correctly" do
      o = rand.to_s
      i = "<%= #{o} %>"

      each_join(WHITESPACE) do |s|
        (BLANK + NEWLINES).enumeration do |a, b|
          render("a#{a}#{s}#{i}#{b}#{s}b").must_equal("a#{a}#{s}#{o}#{b}#{s}b")
        end
      end
    end

    it "renders whitespace surrounding silent directives correctly" do
      i = '<%%>'
      o = ''

      each_join(SPACES) do |s|
        NEWLINES.each do |n|
          # without preceding newline
          render("a#{s}#{i}#{n}b").must_equal("a#{o}b")

          # with preceding newline
          render("a#{n}#{s}#{i}#{n}b").must_equal("a#{n}#{o}b")
        end
      end
    end

    def render input, options = {}
      Ember::Template.new(input, options).render
    end
  end

  describe "A program compiled from a template" do
    it "has the same number of lines as its input, regardless of template options" do
      (BLANK + NEWLINES).each do |s|
        test_num_lines s
        test_num_lines "hello#{s}world"

        OPERATIONS.each do |o|
          test_num_lines "<%#{o}hello#{s}world%>"
        end
      end
    end

    OPTIONS = [:shorthand, :infer_end, :unindent]

    ##
    # Checks that the given input template is compiled into the same
    # number of lines of Ruby code for all possible template options.
    #
    def test_num_lines input
      num_input_lines = count_lines(input)

      each_option_combo(OPTIONS) do |options|
        template = Ember::Template.new(input, options)
        program = template.program

        count_lines(program).must_equal num_input_lines, "template program compiled with #{options.inspect} has different number of lines for input #{input.inspect}"
      end
    end

    ##
    # Counts the number of lines in the given string.
    #
    def count_lines string
      string.to_s.scan(/$/).length
    end

    ##
    # Invokes the given block, passing in an options hash
    # for Ember::Template, for every possible combination.
    #
    def each_option_combo options
      raise ArgumentError unless block_given?

      options.combinations do |flags|
        yield Hash[ *flags.map {|f| [f, true] }.flatten ]
      end
    end
  end
end
