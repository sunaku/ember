require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_delimited_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby"

test ERuby do
  prepare do
    @parser = ERubyParser.new
  end

  test 'empty input' do
    aver @parser.parse('')
  end

  extend WhitespaceHelper

  test 'just content' do
    each_whitespace do |whitespace|
      aver @parser.parse(whitespace)
      aver @parser.parse("%%#{whitespace}")
      aver @parser.parse("<%%#{whitespace}%%>")
    end
  end

  test 'content and directives' do
    aver @parser.parse("before <% hello %>")
    aver @parser.parse("<% hello %> after")
    aver @parser.parse("before <% hello %> after")

    # escaped directives
    aver @parser.parse("before <%% hello %%>")
    aver @parser.parse("<%% hello %%> after")
    aver @parser.parse("before <%% hello %%> after")

    each_whitespace do |whitespace|
      aver @parser.parse("before\n#{whitespace}% hello")
      aver @parser.parse("#{whitespace}% hello\nafter")
      aver @parser.parse("before\n#{whitespace}% hello\n after")

      # escaped directives
      aver @parser.parse("before\n#{whitespace}%% hello")
      aver @parser.parse("#{whitespace}%% hello\nafter")
      aver @parser.parse("before\n#{whitespace}%% hello\n after")
    end
  end
end
