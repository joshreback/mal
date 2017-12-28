require_relative "printer"

NS = {
  '+': lambda { |a,b| a+b },
  '-': lambda { |a,b| a-b },
  '*': lambda { |a,b| a*b },
  '/': lambda { |a,b| a/b },
  'prn': lambda { |ast| puts pr_str(ast); return MalAtom.new("nil") },
  'list': lambda { |*elems| MalList.new(elems.to_a) },
  'list?': lambda { |mal_type| MalAtom.new((mal_type.type == "MalList").to_s) },
  'empty?': lambda { |mal_type| MalAtom.new((mal_type.length == 0).to_s) },
  'count': lambda { |mal_list| MalNum.new(mal_list.type == "MalList" ? mal_list.length : 0) },
  '=': lambda { |a, b| MalAtom.new(a.mal_eq(b)) },
  '<': lambda { |a, b| a < b },
  '<=': lambda { |a, b| a <= b },
  '>': lambda { |a, b| a > b },
  '>=': lambda { |a, b| a >= b }
}