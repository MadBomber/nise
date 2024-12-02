###################################################################
###
##  File: README.txt
##  Desc: Describes the content of this directory
##  Loc:  $ISE_ROOT/Models/RubyModels
#

The RubyModels directory is the central location of all IseRubyModels and
common libraries.  By having all these ruby-based products in a central area
we can shorten the RUBYLIB environmenat variable.  RUBYLIB acts simulat to
PATH and LD_LIBRARY_PATH but its for ruby code.

By convention the main file for an IseRubyModel is located at the root of
the RubyModels directory.  The file name is all lower case in a form known as
'snake case' -- this_is_snake_case.rb  No special characters other than the
underscode should be used.  The filename (sans the '.rb' extension) is used
as a key within the IseDatabase to identify the model.

Any files that are unique to the ruby model are located in a sub-directory of
RubyModels that follows the CamelCase naming convention.  For example:

  The model:                                my_great_model.rb
  Has its unique files in the directory:    MyGreatModel

All IseMessages used by the IseRubyModel are located in $ISE_ROOT/Models/Messages
We do this to co-locate the ruby version of an IseMessage with its C++ equivalent.


The sub-directory 'lib' contains library files that are common to many IseRubyModels
and command line tools.

