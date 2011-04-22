# -*- encoding: utf-8 -*-

gemspec = Gem::Specification.new do |s|
  s.name = %q{ember}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Suraj N. Kurapati"]
  s.date = %q{2011-04-22}
  s.description = %q{Ember (EMBEdded Ruby) is an [eRuby] template processor that allows debugging, reduces markup, and improves composability of eRuby templates.}
  s.executables = ["ember"]
  s.files = ["bin/ember", "lib/ember", "lib/ember/helpers", "lib/ember/helpers/rails_helper.rb", "lib/ember/template.rb", "lib/ember/inochi.rb", "lib/ember.rb", "LICENSE", "man/man1/ember.1"]
  s.homepage = %q{http://snk.tuxfamily.org/lib/ember/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{eRuby template processor}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
system 'inochi', *gemspec.files
gemspec
