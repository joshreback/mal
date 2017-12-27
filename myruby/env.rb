require_relative "errors"

class Env
  attr_accessor :data
  attr_reader :outer

  def initialize(outer=nil, binds=[], exprs=[])
    binds = binds.map { |binding| binding.sym.to_sym }
    @data = Hash[binds.zip(exprs)]
    @outer = outer
  end

  def set(key, value)
    data[key.to_sym] = value
  end

  def find(key)
    if !data[key.to_sym].nil?
      return self
    end

    if !outer.nil?
      return outer.find(key)
    end
  end

  def get(key)
    env = self.find(key)

    if env.nil?
      raise KeyNotFoundError.new("#{key} not found.")
    else
      return env.data[key.to_sym]
    end
  end
end