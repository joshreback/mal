class MalType
  def type
    self.class.name
  end
end

class MalList < MalType
  attr_reader :list

  def initialize(list=[])
    @list = list
  end

  def <<(mal_type)
    list << mal_type if !mal_type.nil?
  end
end

class MalNum < MalType
  attr_reader :num

  def initialize(num)
    @num = num.to_i
  end
end

class MalSymbol < MalType
  attr_reader :sym

  def initialize(sym)
    @sym = sym
  end
end

class MalAtom < MalType
  attr_reader :value
  def initialize(primitive)
    @value = {
      "nil": nil,
      "false": false,
      "true": true
    }[primitive]
  end
end