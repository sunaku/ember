require 'ember/eruby_directive_node'

module ERubyShorthandDirectiveNode
  include ERubyDirectiveNode

  ##
  # The chomp is not defined for shorthand directives in the
  # official eRuby language specification, so we do not
  # support it here---even though it is technically feasible.
  #
  def chomp?
    false
  end
end
