#!/bin/sh
#################################################
###
##  File: build.sh
##  Desc: Creates the jar file for this java project
#

javac HelloWorld.java
echo "Main-Class: HelloWorld" > manifest.txt
jar cvfm HelloWorld.jar manifest.txt *.class

