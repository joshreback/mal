require_relative "reader"
require_relative "printer"
require_relative "errors"
require_relative "env"
require "pry"

def setup_env()
  env = Env.new()
  env.set('+', lambda { |a,b| a+b })
  env.set('-', lambda { |a,b| a-b })
  env.set('*', lambda { |a,b| a*b })
  env.set('/', lambda { |a,b| a/b })
  return env
end

def eval_ast(ast, repl_env)
  case ast.type
  when "MalSymbol"
    func = repl_env.get(ast.sym)
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
    if ast.list[0].type == "MalSymbol" && ast.list[0].sym == "do"
      unevaled_list = ast.list[1]
      evaled_list = eval_ast(unevaled_list, repl_env)
      evaled_list[-1]
    elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "if"
      cond = EVAL(ast.list[1], repl_env)
      if_branch, else_branch = ast.list[2], ast.list[3]
      if cond.value != nil && cond.value != false
        EVAL(if_branch, repl_env)
      else
        else_branch ? EVAL(else_branch, repl_env) : else_branch
      end
    elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "fn*"
      lambda { |*exprs|
        exprs = exprs.to_a
        binds = [ast.list[1]]
        new_env = Env.new(repl_env, binds, exprs)
        EVAL(ast.list[2], new_env)
      }
    elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "def!"
      repl_env.set(ast.list[1].sym,
        EVAL(ast.list[2], repl_env)
      )
    elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "let*"
      new_env = Env.new(repl_env)
      ast.list[1].list.each_slice(2) do |k, v|
        env_key = k.sym
        env_value = EVAL(v, new_env)
        new_env.set(env_key, env_value)
      end
      EVAL(ast.list[2], new_env)
    else
      evaled_list = eval_ast(ast, repl_env)
      op_fn = evaled_list.list[0]
      op_fn_args = evaled_list.list[1..-1].map(&:num)
      MalNum.new(op_fn.call(*op_fn_args))
    end
  else
    eval_ast(ast, repl_env)
  end
end

def PRINT(str)
  pr_str(str)
end

def rep(str, repl_env)
  PRINT(
    EVAL(
      READ(str), repl_env
    )
  )
end

env = setup_env()

loop do
  begin
    print "user> "
    puts rep(gets.chomp, env)
  rescue MalformedStringError, UnrecognizedSymbolError, KeyNotFoundError => e
    puts e.message
  end
end