################################################
###
##  File: sim_msg_type_h2rb.awk
##  Desc: convert the file SimMsgType.h into SimMsgType.rb
#

BEGIN { FS=" "

  start_looking = "enum"
  stop_looking  = "};"
  
  max_length = 0
  
  spaces = "                                                            "
  
  
  FALSE = 0
  TRUE  = 1
  
  working = FALSE

}

0 == NF {  ## skip blank lines
# print "skipping"
  next
}

FALSE == working && $1 == start_looking{
  working = TRUE
  next
}

TRUE == working && $1 == stop_looking {
  working = FALSE
  next
}

FALSE == working { next }

$1 == "//" {
  # got number and desc
  number = $2
  gsub(":", "", number)
  colon_index = index($0, ": ")
  desc = substr($0,colon_index+2)   # expect colon followed by a space
  
  if(length(item) > max_length)
  {
    max_length = length(item)
  }
  
  x = max_length - length(item) + 1
  
  print "@my_hash[:" item "]" substr(spaces,1,x) "= [" number ", \"" desc "\"]"
  
  next
}

{
  item = $1
  gsub(",","",item)
}


END {
}

