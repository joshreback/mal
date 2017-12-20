require_relative "reader"
require_relative "printer"

def READ(str)
  read_str(str)
end

def EVAL(str)
  str
end

def PRINT(str)
  pr_str(str)
end

def rep(str)
  PRINT(
    EVAL(
      READ(str)
    )
  )
end

loop do
  begin
    print "user> "
    puts rep(gets.chomp)
  rescue MalformedStringError => e
    puts "MalformedStringError"
  end
end