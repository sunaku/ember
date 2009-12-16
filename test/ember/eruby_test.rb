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
    T @parser.parse("before <% hello %>")
    T @parser.parse("<% hello %> after")
    T @parser.parse("before <% hello %> after")

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
end
