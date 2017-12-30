class MalType
  class << self
    def from_value(value)
      if value.is_a?(Integer)
        return MalNum.new(value)
      elsif value.is_a?(Array)
        return MalList.new(value)
      elsif ["nil", "false", "true"].include?(value)
        return MalBool.new(value)
      else
        return MalSymbol.new(value)
      end
    end
  end

  def type
    self.class.name
  end
end

class MalAtom < MalType
  attr_accessor :value

  def initialize(value)
    @value = value
  end
end

class MalList < MalType
  attr_reader :list

  def initialize(list=[])
    @list = list
  end

  def value
    list
  end

  def <<(mal_type)
    list << mal_type if !mal_type.nil?
  end

  def length
    list.length
  end

  def mal_eq(other)
    (other.type == "MalList" && length == other.length &&
      list.zip(other.list).all? { |elem, other_elem| elem.mal_eq other_elem })
  end
end

class MalNum < MalType
  attr_reader :num

  def initialize(num)
    @num = num.to_i
  end

  def value
    num
  end

  def +(other)
    MalNum.new(self.num + other.num)
  end

  def -(other)
    MalNum.new(self.num - other.num)
  end

  def *(other)
    MalNum.new(self.num * other.num)
  end

  def /(other)
    MalNum.new(self.num / other.num)
  end

  def >=(other)
    MalBool.new((num >= other.num).to_s)
  end

  def >(other)
    MalBool.new((num > other.num).to_s)
  end

  def <=(other)
    MalBool.new((num <= other.num).to_s)
  end

  def <(other)
    MalBool.new((num < other.num).to_s)
  end

  def mal_eq(other)
    other.type == "MalNum" && num == other.num
  end
end

class MalSymbol < MalType
  attr_reader :sym

  def initialize(sym)
    @sym = sym
  end

  def value
    sym
  end

  def mal_eq(other)
    other.type == "MalSymbol" && sym == other.sym
  end
end

class MalBool < MalType
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def mal_eq(other)
    other.type == "MalBool" && value == other.value
  end
end

class MalString < MalType
  attr_reader :value

  def initialize(value)
    @value = value.gsub("\"", "")
  end

  def mal_eq(other)
    other.type == "MalString" && value == other.value
  end
end