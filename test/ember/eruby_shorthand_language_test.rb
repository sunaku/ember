require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_language"

describe ERubyShorthandLanguage do
  extend WhitespaceHelper

  setup do
    @parser = ERubyShorthandLanguageParser.new
  end

  context 'empty input' do
    refute @parser.parse('')
  end

  context 'empty directives' do
    assert @parser.parse('%')
    refute @parser.parse('%%')
  end

  context 'blank directives' do
    each_whitespace do |whitespace|
      assert @parser.parse("%#{whitespace}")
      refute @parser.parse("%%#{whitespace}")

      next if whitespace.empty?
      assert @parser.parse("%#{whitespace}%")
      assert @parser.parse("%#{whitespace}%%")
    end
  end

  context 'non-blank directives' do
    assert @parser.parse("%hello")
    assert @parser.parse("% hello")
    assert @parser.parse("%hello ")
    assert @parser.parse("% hello ")
  end
end
