unless Ember.const_defined? :INOCHI
  fail "#{Ember} must have INOCHI constant"
end

Ember::INOCHI.each do |param, value|
  const = param.to_s.upcase

  unless Ember.const_defined? const
    fail "#{Ember} must have #{const} constant"
  end

  unless Ember.const_get(const) == value
    fail "#{Ember}'s #{const} constant must be provided by Inochi"
  end
end

puts "Inochi establishment tests passed!"