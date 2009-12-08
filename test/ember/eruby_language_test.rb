require File.dirname(__FILE__) + '/../helper.rb'

require 'treetop'
Treetop.load "#{Ember::LIBRARY_DIR}/ember/eruby_language"

describe ERubyLanguage do
  setup do
    @parser = ERubyLanguageParser.new
  end

  context 'empty directives' do
    assert @parser.parse('<%%>')
  end
end

