require 'pry'

def pr_str(mal_type)
  if mal_type.is_a? UserDefinedFunc or mal_type.is_a? Proc
    return "#<function>"
  end

  case mal_type.type
  when "MalList"
    "(" + mal_type.list.map{ |list_element| pr_str(list_element) }.join(" ") + ")"
  when "MalString"
    mal_type.value.dump
  when "MalAtom"
    "(atom #{pr_str(mal_type.value)})"
  else
    mal_type.value
  end
end