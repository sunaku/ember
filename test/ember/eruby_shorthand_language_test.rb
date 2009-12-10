require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_language"

describe ERubyShorthandLanguage do
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
end
