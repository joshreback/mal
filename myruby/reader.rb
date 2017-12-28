require_relative "types"
require_relative "errors"

class Reader
  attr_reader :position, :tokens

  def initialize(tokens)
    @tokens = tokens
    @position = 0
  end

  def peek
    raise MalformedStringError.new if position == tokens.length

    return tokens[position]
  end

  def next
    raise MalformedStringError.new if position == tokens.length

    token = tokens[position]
    @position += 1
    token
  end
end

def read_str(str)
  tokens = tokenizer(str)
  reader = Reader.new(tokens)
  read_form(reader)
end

def tokenizer(raw_string)
  # gives all match data
  tokens = raw_string.scan(/[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/).flatten
  tokens
end

def read_form(reader)
  ast = case reader.peek
  when "("
    reader.next  # consume the "(" token
    read_list(reader)
  else
    read_atom(reader)
  end
  ast
end

def read_list(reader)
  list = MalList.new

  until (next_read_form = read_form(reader)) == ")" do
    list << next_read_form
  end

  list
end

def read_atom(reader)
  # NOTE: for now, just numbers & symbols
  next_token = reader.next
  case next_token
  when /\Anil|true|false\z/
    MalAtom.new(next_token)
  when /\A-?[0-9]+\z/
    MalNum.new(next_token)
  when /\A".*"\z/
    MalString.new(next_token)
  when /\A<=|>=|<|>|=|\/|\*|\+|\*\*|[-0-9a-zA-Z!]+\z/
    MalSymbol.new(next_token)
  when ")"
    next_token
  end
end
