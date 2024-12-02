# mvn --version
# /usr/lib/jvm/java
# Apache Maven 2.2.1 (rNON-CANONICAL_2010-12-06_15-01_mockbuild; 2010-12-06 09:01:36-0600)
# Java version: 1.6.0_20
# Java home: /usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre
# Default locale: en_US, platform encoding: UTF-8
# OS name: "linux" version: "2.6.35.11-83.fc14.x86_64" arch: "amd64" Family: "unix"



# This directory structure was created by maven
# with the following command line:

mvn archetype:generate  -DgroupId=com.lmco.mfc.ise \
                        -DartifactId=HelloMaven \
                        -DarchetypeArtifactId=maven-archetype-quickstart \
                        -DinteractiveMode=false


source build.s to build a jar file

source run.s to execute the jar file

The file pom.xml.original was the original pom.xml created by
the 'mvn archetype:generate ...' command.  It failed to add
the main class to the manifest file inside the jar.  The current
pom.xml added the <build /> section that makes use of a plugin
to control the building of the jar.

