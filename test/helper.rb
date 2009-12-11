test_dir = File.dirname(__FILE__)
$LOAD_PATH << test_dir
require Dir[test_dir + '/../lib/*.rb'].first

require 'dfect/auto'
require 'dfect/mini'
require 'dfect/nice'

require 'inochi/util/combo'
module WhitespaceHelper
  def each_whitespace
    [' ', "\t", "\r", "\n", "\f"].shuffle.combinations do |sequence|
      yield sequence.join
    end
  end
end
