require_relative "reader"
require_relative "printer"
require_relative "errors"
require_relative "env"
require_relative "core"
require "pry"

UserDefinedFunc = Struct.new(:ast, :params, :env, :fn, :is_macro)

def setup_env()
  env = Env.new()
  NS.each do |op, func|
    env.set(op, func)
  end
  env.set("eval", lambda { |ast| EVAL(ast, env)} )
  env.set("*ARGV*", MalList.new(ARGV))
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
    ast = macroexpand(ast, repl_env)
    if ast.type != "MalList"
      return eval_ast(ast, repl_env)
    end

    if ast.type == "MalList"
      return ast if ast.list.empty?

      # non-empty list
      if ast.list[0].is_a? Proc
        op_fn = ast.list[0]
        op_fn_args = ast.list[1..-1]
        return op_fn.call(*op_fn_args)
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "do"
        unevaled_list = MalList.new(ast.list[1...-1])
        evaled_list = eval_ast(unevaled_list, repl_env)
        ast = ast.list[-1]
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "if"
        cond = EVAL(ast.list[1], repl_env)
        if_branch, else_branch = ast.list[2], ast.list[3]
        ast = if cond.value != "nil" && cond.value != "false"
          if_branch
        else
          else_branch || MalBool.new("nil")
        end
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "fn*"
        return UserDefinedFunc.new(
          ast.list[2],
          ast.list[1].list,
          repl_env,
          lambda { |*exprs|
            binds = ast.list[1].list
            new_env = Env.new(repl_env, binds, exprs)
            user_defined_func = ast.list[-1]
            EVAL(user_defined_func, new_env)
          },
          false
        )
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "def!"
        repl_env.set(ast.list[1].value,
          EVAL(ast.list[2], repl_env)
        )
        return repl_env.get(ast.list[1].value)
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "defmacro!"
        macro = EVAL(ast.list[2], repl_env)
        macro.is_macro = true
        repl_env.set(ast.list[1].value, macro)
        return repl_env.get(ast.list[1].value)
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "macroexpand"
        return macroexpand(ast.list[1], repl_env)
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "let*"
        new_env = Env.new(repl_env)
        ast.list[1].list.each_slice(2) do |k, v|
          env_key = k.sym
          env_value = EVAL(v, new_env)
          new_env.set(env_key, env_value)
        end
        # To support TCO
        repl_env = new_env
        ast = ast.list[2]
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "quote"
        return ast.list[1]
      elsif ast.list[0].type == "MalSymbol" && ast.list[0].sym == "quasiquote"
        ast = quasiquote(ast.list[1])
      else
        evaled_list = eval_ast(ast, repl_env)
        op_fn = evaled_list.list[0]
        op_fn_args = evaled_list.list[1..-1]

        if op_fn.is_a?(UserDefinedFunc)
          repl_env = Env.new(op_fn.env, op_fn.params, op_fn_args)
          ast = op_fn.ast
        else
          ret = op_fn.call(*op_fn_args)
          return ret
        end
      end
    else
      return eval_ast(ast, repl_env)
    end
  end
end

def is_macro_call?(ast, env)
  begin
    (ast.type == "MalList" &&
      ast.list[0].type == "MalSymbol" &&
      env.get(ast.list[0].value).is_a?(UserDefinedFunc) &&
      env.get(ast.list[0].value).is_macro)
  rescue KeyNotFoundError
    false
  end
end

def macroexpand(ast, env)
  while is_macro_call?(ast, env) do
    macro_func = env.get(ast.list[0].value)
    ast = if macro_func.is_a? UserDefinedFunc
      macro_func.fn.call(*ast.list[1..-1])
    else
      macro_func.call(*ast.list[1..-1])  # TODO: Does this need to be a MalList
    end
  end
  return ast
end

def quasiquote(ast)
  if !_is_pair(ast)
    return MalList.new([MalSymbol.new("quote"), ast])
  elsif ast.list[0].type == "MalSymbol" && ast.list[0].value == "unquote"
    return ast.list[1]
  elsif _is_pair(ast) && ast.list[0].type == "MalSymbol" && ast.list[0].value == "splice-unquote"
    return MalList.new([MalSymbol.new("concat"), ast.list[1]])
  else
    new_list = [MalSymbol.new("cons"), quasiquote(ast.list[0]), quasiquote(MalList.new(ast.list[1..-1]))]
    return MalList.new(new_list)
  end
end

def _is_pair(arg)
  return arg.type == "MalList" && arg.value.length > 0
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
rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))", env)
rep("(def! not (fn* (a) (if a false true)))", env)

loop do
  begin
    print "user> "
    puts rep(gets.chomp, env)
  rescue MalformedStringError, UnrecognizedSymbolError, KeyNotFoundError => e
    puts e.message
  end
end