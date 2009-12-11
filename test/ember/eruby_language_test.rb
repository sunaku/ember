require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_directive_language"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_shorthand_language"
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_language"

describe ERubyLanguage do
  extend WhitespaceHelper

  setup do
    @parser = ERubyLanguageParser.new
  end

  context 'empty input' do
    assert @parser.parse('')
  end
end
