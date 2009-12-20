require 'treetop'
Treetop.load __FILE__.sub('_parser.rb', '.treetop')

require 'ember/eruby_shorthand_directive_node'
require 'ember/eruby_content_node'
