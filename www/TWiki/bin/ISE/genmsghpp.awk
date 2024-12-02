#!/usr/bin/gawk -f
###########################################################################
###
##	File:	genmsghpp
##	Desc:	Generates Message Header file from a TWiki *Message topic
##
#

BEGIN {	FS=" "
	OFS="\t"

	spaces="                                                                                      "
	x = 0
	y = 0
	z = 0
	type_len_max = -1

	messageTop   = "messageTop.tmpl"
	messageBottom= "messageBottom.tmpl"
	messageField = "messageField.tmpl"
	messageSuffix= ".hpp"

	message_name = "" ### The name of the message
	message_UNAME= "" ### the name in all uppercase
	message_desc = "" ### The one line description of the message
	field_cnt    = 0
	fields[0]    = "Ignore this"

	print "Content-type: text/html\n\n"
###	print "<pre>"

}

"#" == substr($0,1,1) { next }
0 == NR { next }

"NAME" == $3 {
	message_name = $NF
	gsub(" ", "_", message_name)
	message_UNAME = toupper(message_name)
	next
}

"DESCRIPTION" == $3 {
	message_desc = substr($0,index($0, "=")+3)
	gsub(/\/+/,"-",message_desc)
	FS="|"
	next
}

#########################################
## Only process the field table

"|" != substr($0,1,1) { next }

{ ### For every field

# The first table row is a header row, so when field_cnt = 0 do nothing

	fields[field_cnt++] = $0

# $1 and $8 are always empty due to way TWiki codes tables

	field_number   = trim($2)
	field_variable = trim($3)
	field_type     = trim($4)
	field_size     = trim($5)
	field_units    = trim($6)
	field_comment  = trim($7)

	gsub(" ", "_", field_variable)
	gsub(/\/+/,"_",field_variable)

	if ( 0 == length(field_type) )
	{
		field_type = "UNDEFINED"
	}

	field_types[field_number]     = field_type
	field_variables[field_number] = field_variable
}

END {

	message_filename = message_name messageSuffix

	if ( 0 == length(message_desc) ) message_desc = message_name " Message"

	myCommand = "sed 's/___NAME___/" message_name "/g' " messageTop " | "
	myCommand = myCommand "sed 's/___UNAME___/" message_UNAME "/g' | "
	myCommand = myCommand "sed 's/___DESC___/" message_desc "/g'"

	system(myCommand)


########################################
## Now put out the fields

	for (x=1; x<field_cnt;x++)
	{
		if (length(field_types[x]) > type_len_max)
		{
			type_len_max = length(field_types[x])
		}
	} 

	type_len_max += 2

	for (x=1; x<field_cnt-1; x++)
	{
		field_type     = field_types[x]
		y = length(field_type)
		field_variable = field_variables[x]

		print "\tITEM(" field_type "," substr(spaces,1,type_len_max-y) field_variable "_) \\"
	}

	field_type     = field_types[field_cnt-1]
	y = length(field_type)
	field_variable = field_variables[field_cnt-1]

	print "\tITEM(" field_type "," substr(spaces,1,type_len_max-y) field_variable "_)"


	system("cat " messageBottom )

###	print "</pre>"
}


function trim(v) {
    ## Remove leading and trailing spaces (add tabs if you like)
    sub(/^ */,"",v)
    sub(/ *$/,"",v)
    return v
}

