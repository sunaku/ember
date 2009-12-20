module ERubyDirectiveNode
  def comment?
    text_value =~ /\A#/
  end

  def assign?
    text_value =~ /\A=/
  end

  def chomp?
    text_value =~ /-\z/
  end

  def delimited?
    kind_of? ERubyDelimitedDirectiveNode
  end

  def shorthand?
    kind_of? ERubyShorthandDirectiveNode
  end
end

require 'ember/eruby_delimited_directive_node'
require 'ember/eruby_shorthand_directive_node'
