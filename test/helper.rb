require Dir[File.dirname(__FILE__) + '/../lib/*.rb'].first
require 'dfect/auto'
require 'dfect/mini'

require 'inochi/util/combo'
module WhitespaceHelper
  def each_whitespace
    [' ', "\t", "\r", "\n", "\f"].permutations do |sequence|
      yield sequence.join
    end
  end
end
