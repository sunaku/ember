#--
# Copyright 2009 Suraj N. Kurapati
# See the LICENSE file for details.
#++

require 'rubygems'
gem 'inochi', '~> 1'
require 'inochi'

Inochi.init :Ember,
  :version => '0.0.0',
  :release => '2009-02-13',
  :website => 'http://snk.tuxfamily.org/lib/ember',
  :tagline => 'eRuby template processor'

require 'ember/template'
