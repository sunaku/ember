require 'rubygems'
gem 'inochi', '~> 0'
require 'inochi'

Inochi.init :Ember,
  :version => '0.0.0',
  :release => '2009-02-13',
  :website => 'http://snk.tuxfamily.org/lib/ember',
  :tagline => 'eRuby template processor',
  :require => {}

require 'ember/template'
