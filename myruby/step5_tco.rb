require_relative "reader"
require_relative "printer"
require_relative "errors"
require_relative "env"
require_relative "core"
require "pry"

UserDefinedFunc = Struct.new(:ast, :params, :env, :fn)

def setup_env()
  env = Env.new()
  NS.each do |op, func|
    env.set(op, func)
  end
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
  loop do
    if ast.type == "MalList"
      return ast if ast.list.empty?

      # non-empty list
      if ast.list[0].type == "MalSymbol" && ast.list[0].sym == "do"
        unevaled_list = MalList.new(ast.list[1...-1])
        evaled_list = eval_ast(unevaled_list, repl_env)
        ast = ast.list[-1]
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "if"
        cond = EVAL(ast.list[1], repl_env)
        if_branch, else_branch = ast.list[2], ast.list[3]
        ast = if cond.value != "nil" && cond.value != "false"
          if_branch
        else
          else_branch || MalAtom.new("nil")
        end
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "fn*"
        return UserDefinedFunc.new(
          ast.list[2],
          ast.list[1].list,
          repl_env
        )
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "def!"
        repl_env.set(ast.list[1].value,
          EVAL(ast.list[2], repl_env)
        )
        return repl_env.get(ast.list[1].value)
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "let*"
        new_env = Env.new(repl_env)
        ast.list[1].list.each_slice(2) do |k, v|
          env_key = k.sym
          env_value = EVAL(v, new_env)
          new_env.set(env_key, env_value)
        end
        # To support TCO
        repl_env = new_env
        ast = ast.list[1]
      else
        evaled_list = eval_ast(ast, repl_env)
        op_fn = evaled_list.list[0]
        op_fn_args = evaled_list.list[1..-1]

        if op_fn.is_a?(UserDefinedFunc)
          repl_env = Env.new(op_fn.env, op_fn.params, op_fn_args)
          ast = op_fn.ast
        else
          ret = op_fn.call(*op_fn_args)
          return MalType.from_value(ret.value)
        end
      end
    else
      return eval_ast(ast, repl_env)
    end
  end
end

def PRINT(ast)
  pr_str(ast)
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