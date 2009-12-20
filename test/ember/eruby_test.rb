require 'test_helper'
require 'ember/eruby_parser'

D ERuby do
  D.< do
    @parser = ERubyParser.new
  end

  D 'empty input' do
    T @parser.parse('')
  end

  extend WhitespaceHelper

  D 'content only' do
    each_whitespace do |whitespace|
      T @parser.parse(whitespace)
      T @parser.parse("%%#{whitespace}")
      T @parser.parse("<%%#{whitespace}%%>")
    end
  end

  D 'content and directives' do
    parse "before <% hello %>",
      [ERubyContentNode, "before "],
      [ERubyDirectiveNode, " hello "]

    parse "<% hello %> after",
      [ERubyDirectiveNode, " hello "],
      [ERubyContentNode, " after"]

    parse "before <% hello %> after",
      [ERubyContentNode, "before "],
      [ERubyDirectiveNode, " hello "],
      [ERubyContentNode, " after"]

    # escaped directives
    parse "before <%% hello %%>",
      [ERubyContentNode, "before <%% hello %%>"]

    parse "<%% hello %%> after",
      [ERubyContentNode, "<%% hello %%> after"]

    parse "before <%% hello %%> after",
      [ERubyContentNode, "before <%% hello %%> after"]

    each_whitespace do |whitespace|
      parse "before#{whitespace}\n% hello",
        [ERubyContentNode, "before#{whitespace}\n"],
        [ERubyDirectiveNode, " hello"]

      parse "% hello\n#{whitespace}after",
        [ERubyDirectiveNode, " hello"],
        [ERubyContentNode, "\n#{whitespace}after"]

      parse "#{whitespace}\n% hello\n after",
        [ERubyContentNode, "#{whitespace}\n"],
        [ERubyDirectiveNode, " hello"],
        [ERubyContentNode, "\n after"]

      parse "before\n#{whitespace}\n% hello\n#{whitespace}after",
        [ERubyContentNode, "before\n#{whitespace}\n"],
        [ERubyDirectiveNode, " hello"],
        [ERubyContentNode, "\n#{whitespace}after"]

      # escaped directives
      [nil, "\n"].each do |newline| # newline before '%' should not matter
        parse "before\n#{whitespace}#{newline}%% hello",
          [ERubyContentNode, "before\n#{whitespace}#{newline}%% hello"]

        parse "#{whitespace}#{newline}%% hello\nafter",
          [ERubyContentNode, "#{whitespace}#{newline}%% hello\nafter"]

        parse "before\n#{whitespace}#{newline}%% hello\n after",
          [ERubyContentNode, "before\n#{whitespace}#{newline}%% hello\n after"]
      end
    end
  end

  D 'comment directives' do
    parse "a<%# hello %>b",
      [ERubyContentNode, "a"],
      [ERubyDirectiveNode, "# hello ", :comment?],
      [ERubyContentNode, "b"]

    parse "a\n%# hello \nb",
      [ERubyContentNode, "a\n"],
      [ERubyDirectiveNode, "# hello ", :comment?],
      [ERubyContentNode, "\nb"]
  end

  D 'assignment directives' do
    parse "a<%= hello %>b",
      [ERubyContentNode, "a"],
      [ERubyDirectiveNode, "= hello ", :assign?],
      [ERubyContentNode, "b"]

    parse "a\n%= hello \nb",
      [ERubyContentNode, "a\n"],
      [ERubyDirectiveNode, "= hello ", :assign?],
      [ERubyContentNode, "\nb"]
  end

  D 'chomping directives' do
    parse "a<%= hello -%>b",
      [ERubyContentNode, "a"],
      [ERubyDirectiveNode, "= hello -", :assign?, :chomp?],
      [ERubyContentNode, "b"]

    # not present in the official eRuby language
    parse "a\n%= hello -\nb",
      [ERubyContentNode, "a\n"],
      [ERubyDirectiveNode, "= hello -", :assign?, :chomp?],
      [ERubyContentNode, "\nb"]
  end

  def parse input, *expected_sequence
    tree = @parser.parse(input)
    list = tree.to_a

    expected_sequence.each do |expected_class, expected_text, *expected_atts|
      node = list.shift

      T { node.kind_of? expected_class }
      T { node.text_value == expected_text }

      expected_atts.each do |expected_attr|
        T { node.__send__(expected_attr) }
      end
    end

    tree
  end
end
