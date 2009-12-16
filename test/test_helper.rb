test_dir = File.dirname(__FILE__)
require Dir[test_dir + '/../lib/*.rb'].first

require 'dfect/auto'

require 'inochi/util/combo'
module WhitespaceHelper
  def each_whitespace
    [' ', "\t", "\r", "\n", "\f"].combinations do |sequence|
      yield sequence.join
    end
  end
end
