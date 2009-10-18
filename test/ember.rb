unless Ember.const_defined? :INOCHI
  fail "Ember must be established by Inochi"
end

Ember::INOCHI.each do |param, value|
  const = param.to_s.upcase

  unless Ember.const_defined? const
    fail "Ember::#{const} must be established by Inochi"
  end

  unless Ember.const_get(const) == value
    fail "Ember::#{const} is not what Inochi established"
  end
end

puts "Inochi establishment tests passed!"
