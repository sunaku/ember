require 'inochi/util/combo'

describe "Ruby program compiled from a template" do
  it "should have the same number of lines, regardless of template options" do
    test_num_lines('')
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

      count_lines(program).must_equal num_input_lines,
        "template compiled with #{options.inspect} has different number of lines"
    end
  end

  ##
  # Counts the number of lines in the given string.
  #
  def count_lines string
    string.to_s.scan(/^/).length
  end

  OPTIONS = [:chomp_before, :strip_before, :chop_after, :strip_after, :unindent]

  ##
  # Invokes the given block once for every
  # possible combination of template options.
  #
  def OPTIONS.each_combo
    raise ArgumentError unless block_given?

    length.times do |i|
      combination(i) do |flags|
        yield Hash[ *flags.map {|f| [f, true] }.flatten ]
      end
    end
  end
end

describe "A template" do
  it "should render comments as nothing" do
    [
      "<%# single line comment %>",
      "<%     # offset single line comment %>",
      "<%#
                multi
          line

            comment %>",
    ].each do |input|
      render(input).must_equal("")
    end
  end

  private

  def render input, options = {}
    Ember::Template.new(input, options).render
  end
end
