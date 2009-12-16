require 'ember/eruby_directive'

require 'treetop'
Treetop.load __FILE__.sub(/rb$/, 'treetop')

module ERubyDocument
  ##
  # Returns an array of all content and directive nodes, in the
  # order that they occur in the input, from this parse tree.
  #
  def to_a
    list = []

    visitor = lambda do |node|
      if node.kind_of? ERubyContent or node.kind_of? ERubyDirective
        list << node
        next # do not visit the children of this nonterminal
      end

      if node.nonterminal?
        node.elements.each(&visitor)
      end
    end

    visitor.call self

    list
  end
end

module ERubyContent
end
