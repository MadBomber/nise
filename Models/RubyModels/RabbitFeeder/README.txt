#######################################################################
###
##  File: README.txt
##  Desc: Describes the contents of this directory
##  Loc:  $ISE_ROOT/Models/RubyModels/RabbitFeeder
#

This directory contains all of the Ruby library files that are specific to
the rabbit_feeder IseRubyModel.

The rabbit_feeder IseRubyModel is patterned after the web_app_feeder in that it
can be used with existing or legacy IseJobs to flow common IseMessages from the
IseDispatcher into another message service.  In this case the other service is
the RabbitMQ AMQP Server.

However, it is not necessary to use the rabbit_feeder to get IseMessages into the
AMQP servier.  All new development can make use of the options hash available with
all IseMessage@publish invocations.  For example the ThreatWarning IseMessage can be
published via the IseDispatcher and the AMQP server like this:

  tw = ThreatWarning.new

  tw.yada_yada = yada_yada_etc
  
  tw.publish :via => :both

See the IseRouter and IseRouterConcept topics in the ISEwiki

  

