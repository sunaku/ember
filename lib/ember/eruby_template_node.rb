require 'ember/eruby_content_node'
require 'ember/eruby_directive_node'

module ERubyTemplateNode
  ##
  # Returns an array of all content and directive nodes, in the
  # order that they occur in the input, from this parse tree.
  #
  def to_a
    list = []

    visitor = lambda do |node|
      if node.kind_of? ERubyContentNode or node.kind_of? ERubyDirectiveNode

        # make the SyntaxNode#text_value field appendable
        text_value = node.text_value

        class << node
          undef text_value
          attr_accessor :text_value
        end

        node.text_value = text_value

        # collapse adjacent content nodes into a single one
        if node.kind_of? ERubyContentNode and
           prev_node = list.last and
           prev_node.kind_of? ERubyContentNode
        then
          prev_node.text_value << node.text_value
        else
          list << node
        end

      elsif node.nonterminal?
        node.elements.each(&visitor)
      end
    end

    visitor.call self

    list
  end
end
