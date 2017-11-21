def READ(str)
  str
end

def EVAL(str)
  str
end

def PRINT(str)
  str
end

def rep(str)
  PRINT(
    EVAL(
      READ(str)
    )
  )
end

loop do
  print "user> "
  puts rep(gets.chomp)
end