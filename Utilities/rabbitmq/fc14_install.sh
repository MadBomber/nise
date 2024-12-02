#!/bin/sh

#These directories have the rabbit plugins from http://www.rabbitmq.com/plugins.html
#Fedora 14 currently distributes version 2.1 server as an rpm package.

sudo cp 2.2/* /usr/lib/rabbitmq/lib/rabbitmq_server-2.2.0/plugins

