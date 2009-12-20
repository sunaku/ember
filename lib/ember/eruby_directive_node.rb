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
end
