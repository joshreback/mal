require_relative "reader"
require_relative "printer"
require_relative "errors"
require "pry"

$repl_env = {
  '+': lambda { |a,b| a+b },
  '-': lambda { |a,b| a-b },
  '*': lambda { |a,b| a*b },
  '/': lambda { |a,b| a/b }
}

def eval_ast(ast, repl_env)
  case ast.type
  when "MalSymbol"
    func = repl_env[ast.sym.to_sym]
    if func.nil?
      raise UnrecognizedSymbolError.new("'#{ast.sym.to_s}' not found.")
    end
    func
  when "MalList"
    evaled_list = ast.list.map { |elem| EVAL(elem, repl_env) }
    evaled_list = MalList.new(evaled_list)
    evaled_list
  else
    ast
  end
end

def READ(str)
  read_str(str)
end

def EVAL(ast, repl_env)
  if ast.type == "MalList"
    return ast if ast.list.empty?

    # non-empty list
    evaled_list = eval_ast(ast, repl_env)
    op_fn = evaled_list.list[0]
    arg1 = evaled_list.list[1]
    arg2 = evaled_list.list[2]
    MalNum.new(op_fn.call(arg1.num, arg2.num))
  else
    eval_ast(ast, repl_env)
  end
end

def PRINT(str)
  pr_str(str)
end

def rep(str)
  PRINT(
    EVAL(
      READ(str), $repl_env
    )
  )
end

loop do
  begin
    print "user> "
    puts rep(gets.chomp)
  rescue MalformedStringError, UnrecognizedSymbolError => e
    puts e.message
  end
end