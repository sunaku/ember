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

        # collapse adjacent content nodes into a single one
        if node.kind_of? ERubyContent

          # make the text_value field appendable
          content = node.text_value
          class << node
            undef text_value
            attr_accessor :text_value
          end
          node.text_value = content

          # combine their content
          if prev_node = list.last and prev_node.kind_of? ERubyContent
            prev_node.text_value << node.text_value
          else
            list << node
          end

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

module ERubyContent
end
