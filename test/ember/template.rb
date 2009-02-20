require 'inochi/util/combo'

describe "Ruby program compiled from a template" do
  it "should have the same number of lines, regardless of template options" do
    test_num_lines("")
    test_num_lines("\n")
    test_num_lines("hello \n world")
  end

  private

  ##
  # Checks that the given input template is compiled into the same
  # number of lines of Ruby code for all possible template options.
  #
  def test_num_lines input
    num_input_lines = count_lines(input)

    OPTIONS.each_combo do |options|
      template = Ember::Template.new(input, options)
      program = template.to_s

      count_lines(program).must_equal num_input_lines, "template compiled with #{options.inspect} has different number of lines for input #{input.inspect}"
    end
  end

  ##
  # Counts the number of lines in the given string.
  #
  def count_lines string
    string.to_s.scan(/$/).length
  end

  OPTIONS = [:chomp_before, :strip_before, :chop_after, :strip_after, :unindent]

  ##
  # Invokes the given block once for every
  # possible combination of template options.
  #
  def OPTIONS.each_combo
    raise ArgumentError unless block_given?

    combinations do |flags|
      yield Hash[ *flags.map {|f| [f, true] }.flatten ]
    end
  end
end

describe "A template" do
  it "should render comments as nothing" do
    [
      "<%#   single line comment   %>",
      "<%#
                multi
          line

            comment %>",
    ].each do |input|
      render(input).must_equal("")
    end
  end

  it "should render empty directives as nothing" do
    WHITESPACE.each_combo do |space|
      [nil, '=', '#'].each do |operation|
        render("<%#{operation}#{space}%>").must_equal("")
      end
    end
  end

  it "should render escaped directives in unescaped form" do
    render("<%%%>").must_equal("<%%>")

    render("<%% %>").must_equal("<% %>")

    lambda { render("<% %%>") }.
      must_raise(SyntaxError, "the trailing delimiter must not be unescaped")

    render("<%%%%>").wont_equal("<%%>",
      "only the opening delimiter must be unescaped")

    render("<%%%%>").must_equal("<%%%>",
      "the trailing delimiter must not be unescaped")

    render("<%% single line directive %>").
      must_equal("<% single line directive %>")

    render("<%% multi \n line \n\n directive %>").
      must_equal("<% multi \n line \n\n directive %>")
  end

  it "should preserve whitespace surrounding directives" do
    WHITESPACE.each_combo do |space|
      render("#{space}<%%>").must_equal(space)
      render("<%%>#{space}").must_equal(space)
      render("#{space}<%%>#{space}").must_equal(space * 2)
    end
  end

  private

  def render input, options = {}
    Ember::Template.new(input, options).render
  end

  WHITESPACE = [" ", "\t", "\n"]

  ##
  # Invokes the given block once for every
  # possible combination of whitespace strings.
  #
  def WHITESPACE.each_combo
    raise ArgumentError unless block_given?

    permutations do |combo|
      space = combo.join
      yield space
    end
  end
end
