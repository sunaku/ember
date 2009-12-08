require File.dirname(__FILE__) + '/../helper.rb'
require 'inochi/util/combo'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_language"

describe ERubyLanguage do
  setup do
    @parser = ERubyLanguageParser.new
  end

  context 'empty directives' do
    assert @parser.parse('<%%>')
  end

  context 'blank directives' do
    [' ', "\t", "\r", "\n", "\f"].permutations do |sequence|
      assert @parser.parse("<%#{sequence.join}%>")
    end
  end
end

