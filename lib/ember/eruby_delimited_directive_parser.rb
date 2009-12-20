require 'treetop'
Treetop.load __FILE__.sub('_parser.rb', '.treetop')

require 'ember/eruby_delimited_directive_node'
