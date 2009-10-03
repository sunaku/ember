#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'rubygems'
gem 'inochi', '~> 1'
require 'inochi'

Inochi.init :Ember,
  :version => '0.0.1',
  :release => '2009-10-03',
  :website => 'http://snk.tuxfamily.org/lib/ember/',
  :tagline => 'eRuby template processor'

require 'ember/template'
