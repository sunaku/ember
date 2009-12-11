require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_delimited_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_directive"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby"

describe ERuby do
  setup do
    @parser = ERubyParser.new
  end

  context 'empty input' do
    assert @parser.parse('')
  end

  extend WhitespaceHelper

  context 'just content' do
    each_whitespace do |whitespace|
      assert @parser.parse(whitespace)
      assert @parser.parse("%%#{whitespace}")
      assert @parser.parse("<%%#{whitespace}%%>")
    end
  end

  context 'content and directives' do
    assert @parser.parse("before <% hello %>")
    assert @parser.parse("<% hello %> after")
    assert @parser.parse("before <% hello %> after")

    # escaped directives
    assert @parser.parse("before <%% hello %%>")
    assert @parser.parse("<%% hello %%> after")
    assert @parser.parse("before <%% hello %%> after")

    each_whitespace do |whitespace|
      assert @parser.parse("before\n#{whitespace}% hello")
      assert @parser.parse("#{whitespace}% hello\nafter")
      assert @parser.parse("before\n#{whitespace}% hello\n after")

      # escaped directives
      assert @parser.parse("before\n#{whitespace}%% hello")
      assert @parser.parse("#{whitespace}%% hello\nafter")
      assert @parser.parse("before\n#{whitespace}%% hello\n after")
    end
  end
end
