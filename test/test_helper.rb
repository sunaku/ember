test_dir = File.dirname(__FILE__)
require Dir[test_dir + '/../lib/*.rb'].first

require 'dfect/auto'

require 'inochi/util/combo'
module WhitespaceHelper
  SPACE = [' ', "\t"]
  BREAK = ["\r", "\n", "\f"]
  WHITESPACE = SPACE + BREAK

  def each_whitespace
    WHITESPACE.combinations do |sequence|
      yield sequence.join
    end
  end

  def each_space
    SPACE.combinations do |sequence|
      yield sequence.join
    end
  end

  def each_break
    BREAK.combinations do |sequence|
      yield sequence.join
    end
  end
end
