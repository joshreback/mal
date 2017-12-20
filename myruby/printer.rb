def pr_str(mal_type)
  case mal_type.type
  when "MalList"
    "(" + mal_type.list.map{ |list_element| pr_str(list_element) }.join(" ") + ")"
  when "MalNum"
    mal_type.num
  when "MalSymbol"
    mal_type.sym
  end
end