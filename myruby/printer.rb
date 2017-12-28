require 'pry'

def pr_str(mal_type)
  if mal_type.is_a? UserDefinedFunc
    return "#<function>"
  end

  case mal_type.type
  when "MalList"
    "(" + mal_type.list.map{ |list_element| pr_str(list_element) }.join(" ") + ")"
  else
    mal_type.value
  end
end