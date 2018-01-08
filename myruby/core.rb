require_relative "printer"
require_relative "reader"

NS = {
  '+': lambda { |a,b| a+b },
  '-': lambda { |a,b| a-b },
  '*': lambda { |a,b| a*b },
  '/': lambda { |a,b| a/b },

  'prn': lambda { |*args| puts args.map { |a| pr_str(a) }.join(" "); MalAtom.new("nil") },
  'str': lambda { |*args| MalString.new(args.map { |a| pr_str(a) }.join("")) },
  'list': lambda { |*elems| MalList.new(elems) },
  'list?': lambda { |mal_type| MalBool.new((mal_type.type == "MalList").to_s) },
  'empty?': lambda { |mal_type| MalBool.new((mal_type.length == 0).to_s) },
  'count': lambda { |mal_list| MalNum.new(mal_list.type == "MalList" ? mal_list.length : 0) },
  'read-string': lambda { |string| read_str(string.value) },
  'slurp': lambda do |file|
    curr_dir = Pathname(File.expand_path($0)).dirname
    file_name = curr_dir.join(file.value)
    MalString.new(File.read(file_name.to_s))
  end,

  '=': lambda { |a, b| MalBool.new(a.mal_eq(b).to_s) },
  '<': lambda { |a, b| a < b },
  '<=': lambda { |a, b| a <= b },
  '>': lambda { |a, b| a > b },
  '>=': lambda { |a, b| a >= b },

  'atom': lambda { |mal_value| MalAtom.new(mal_value) },
  'atom?': lambda { |mal_value| MalBool.new((mal_value.is_a? MalAtom).to_s) },
  'deref': lambda { |atom| atom.value },
  'reset!': lambda { |atom, value| atom.value = value; value },
  'swap!': lambda do |atom, func, *args|
    func_args = [atom.value] + args
    if func.is_a? UserDefinedFunc
      atom.value = func.fn.call(*func_args)
    else
      atom.value = func.call(*func_args)
    end
    atom.value
  end,

  'cons': lambda { |arg, mal_list| MalList.new([arg] + mal_list.list) },
  'concat': lambda { |*mal_lists| MalList.new(mal_lists.map(&:list).reduce([], :+)) },
  'throw': lambda { |exception| raise MalException.new(exception.value) },
  'apply': lambda { |func, *args, mal_list|
    concat_list = NS[:concat].call(MalList.new(args), mal_list)
    if func.is_a?(UserDefinedFunc)
      func.fn.call(*concat_list.list)
    else
      func.call(*concat_list.list)
    end
  },
  'map': lambda do |func, mal_list|
    new_list = mal_list.list.map do |elem|
      if func.is_a?(UserDefinedFunc)
        func.fn.call(elem)
      else
        func.call(elem)
      end
    end
    MalList.new(new_list)
  end,
  'nil?': lambda { |arg| MalBool.new(arg.is_a?(MalType) && arg.type == "MalBool" && arg.value == "nil") },
  'true?': lambda { |arg| MalBool.new(arg.is_a?(MalType) && arg.type == "MalBool" && arg.value == "true") },
  'false?': lambda { |arg| MalBool.new(arg.is_a?(MalType) && arg.type == "MalBool" && arg.value == "false") },
  'symbol?': lambda { |arg| MalBool.new(arg.is_a?(MalType) && arg.type == "MalSymbol") }
}