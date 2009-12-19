require 'test_helper'
require 'ember/eruby'

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
      [ERubyContent, "before "],
      [ERubyDirective, " hello "]

    parse "<% hello %> after",
      [ERubyDirective, " hello "],
      [ERubyContent, " after"]

    parse "before <% hello %> after",
      [ERubyContent, "before "],
      [ERubyDirective, " hello "],
      [ERubyContent, " after"]

    # escaped directives
    parse "before <%% hello %%>",
      [ERubyContent, "before <%% hello %%>"]

    parse "<%% hello %%> after",
      [ERubyContent, "<%% hello %%> after"]

    parse "before <%% hello %%> after",
      [ERubyContent, "before <%% hello %%> after"]

    each_whitespace do |whitespace|
      parse "before#{whitespace}\n% hello",
        [ERubyContent, "before#{whitespace}\n"],
        [ERubyDirective, " hello"]

      parse "% hello\n#{whitespace}after",
        [ERubyDirective, " hello"],
        [ERubyContent, "\n#{whitespace}after"]

      parse "#{whitespace}\n% hello\n after",
        [ERubyContent, "#{whitespace}\n"],
        [ERubyDirective, " hello"],
        [ERubyContent, "\n after"]

      parse "before\n#{whitespace}\n% hello\n#{whitespace}after",
        [ERubyContent, "before\n#{whitespace}\n"],
        [ERubyDirective, " hello"],
        [ERubyContent, "\n#{whitespace}after"]

      # escaped directives
      [nil, "\n"].each do |newline| # newline before '%' should not matter
        parse "before\n#{whitespace}#{newline}%% hello",
          [ERubyContent, "before\n#{whitespace}#{newline}%% hello"]

        parse "#{whitespace}#{newline}%% hello\nafter",
          [ERubyContent, "#{whitespace}#{newline}%% hello\nafter"]

        parse "before\n#{whitespace}#{newline}%% hello\n after",
          [ERubyContent, "before\n#{whitespace}#{newline}%% hello\n after"]
      end
    end
  end

  def parse input, *expected_sequence
    tree = @parser.parse(input)
    list = tree.to_a

    expected_sequence.each do |expected_node, expected_text|
      node = list.shift

      T { node.kind_of? expected_node }
      T { node.text_value == expected_text }
    end

    tree
  end
end
