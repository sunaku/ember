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
      [ERubyDirective, "<% hello %>"]

    parse "<% hello %> after",
      [ERubyDirective, "<% hello %>"],
      [ERubyContent, " after"]

    parse "before <% hello %> after",
      [ERubyContent, "before "],
      [ERubyDirective, "<% hello %>"],
      [ERubyContent, " after"]

    # escaped directives
    T @parser.parse("before <%% hello %%>")
    T @parser.parse("<%% hello %%> after")
    T @parser.parse("before <%% hello %%> after")

    each_whitespace do |whitespace|
      T @parser.parse("before\n#{whitespace}% hello")
      T @parser.parse("#{whitespace}% hello\nafter")
      T @parser.parse("before\n#{whitespace}% hello\n after")

      # escaped directives
      T @parser.parse("before\n#{whitespace}%% hello")
      T @parser.parse("#{whitespace}%% hello\nafter")
      T @parser.parse("before\n#{whitespace}%% hello\n after")
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
