@echo off
title ISE Command Shell:
rem ###############################################################
rem ###
rem ##  File:  setup_symbols.cmd
rem ##  description:  Establish the system environment varialbes required by ISE
rem ##         within an MS Windows cmd.exe console environment
rem ##
rem ##  IMPORTANT: Delayed binding of system environment variables must be
rem ##             turned on within cmd.exe through a command line switch:
rem ##                   cmd.exe /e:on /v:on
rem ##             In the alias that starts your command shell make sure the
rem ##             has the /e and /v switchs turned on.
rem ##
rem ##  IMPORTANT: To ease maintenance please keep the order of settings in
rem ##             this file in sync with the setup_symbols.cmd file.
rem #

SETLOCAL EnableDelayedExpansion

set HOME=%HOMEDRIVE%%HOMEPATH%
set ISE_RC=%HOME%\dot_iserc.cmd

rem # set HTTP_PROXY=http://138.209.111.74:80

rem # Extract the IPADDRESS from ipconfig

for /f "delims=" %%a in ('ipconfig ^| findstr [0-9].\.') do @for /f "tokens=1,2 delims=:" %%i in ('@echo %%a ^| findstr "Address"') do @for /f %%o in ('@echo %%j') do @set IPADDRESS=%%o


rem HOSTNAME is not a standard windows environment variable.
rem Using the technique below the HOSTNAME environment variable is set
rem for /f %%x in ('c:\windows\system32\hostname.exe') do set HOSTNAME=%%x

set HOSTNAME=%COMPUTERNAME%
set USER=%USERNAME%

echo ############################################################
echo %HOSTNAME%: %USER% @ %IPADDRESS%
echo ############################################################
echo Setting ISE variables ...

set ISE_QUEEN=127.0.0.1

set ISE_GATEWAY=127.0.0.1
set ISE_PORT=8003

rem # %CD% is the current working directory

set ISE_ROOT=%CD%
set ISE_RUN=%CD%

setx ISE_ROOT %ISE_ROOT%
setx ISE_RUN %ISE_RUN%

set ISE_CLUSTER=LabPC105 pcig22 pcig24 pcig26 pcig28 pcig31

setx ISE_CLUSTER "%ISE_CLUSTER%"

rem ###########################
rem # Environment used by Rails
rem # Values:         Meaning:
rem #   development ... working on localhost
rem #   test .......... integration testing
rem #   staging ....... acceptance testing
rem #   production .... live

echo ############################################################
echo Setting RAILS variables ...

set ISE_ENV=production
set RAILS_ENV=%ISE_ENV%

setx ISE_ENV %ISE_ENV%
setx RAILS_ENV %RAILS_ENV%

rem ############################
rem # Ruby and Rails Things

set RAILS_ROOT=%ISE_ROOT%\WebApp\Portal
setx RAILS_ROOT %RAILS_ROOT%

set RUBYLIB=%RAILS_ROOT%\lib
set RUBYLIB=%RUBYLIB%;%RAILS_ROOT%\app\models
set RUBYLIB=%RUBYLIB%;%ISE_ROOT%\Models\RubyModels
set RUBYLIB=%RUBYLIB%;%ISE_ROOT%\Models\RubyModels\lib
set RUBYLIB=%RUBYLIB%;%ISE_ROOT%\RubyPeer
set RUBYLIB=%RUBYLIB%;%ISE_ROOT%\Scenarios
set RUBYLIB=%RUBYLIB%;%ISE_ROOT%\Common\Messages
setx RUBYLIB %RUBYLIB%

rem ##############################################
rem # Make rake tasks available outside the Portal
rem # symbolic links are bug sources on MS Windows
rem # make sure that svn:ignore Rakefile is set for %ISE_ROOT%

if not exist %ISE_ROOT%\Rakefile (
    copy %RAILS_ROOT%\Rakefile %ISE_ROOT%
)

rem #######################################################
rem # Create the svn:ignored directories inside $RAILS_ROOT

if not exist %RAILS_ROOT%\log (
    mkdir %RAILS_ROOT%\log
    mkdir %RAILS_ROOT%\tmp
)


rem ####################################
rem # In support of the MPC build system

echo ############################################################
echo Setting system-level build/execution variables ...

rem # MySQL version 5.1 API not yet supported by RAILS
rem #   ... using latest revision of 5.0

if "x%MYSQL_ROOT%" == "x" (
    set MYSQL_ROOT=C:\mysql-5.0.77-win32
    setx MYSQL_ROOT !MYSQL_ROOT!
)

if "x%ACE_ROOT%" == "x" (
    set ACE_ROOT=C:\ACE_wrappers
    set MPC_ROOT=!ACE_ROOT!\MPC
    set TAO_ROOT=!ACE_ROOT!\TAO

    setx ACE_ROOT !ACE_ROOT!
    setx MPC_ROOT !MPC_ROOT!
    setx TAO_ROOT !TAO_ROOT!
)

rem # %boost% is only used with remake.rb inside the shell

set boost=1

if "x%BOOST_ROOT%" == "x" (
    set BOOST_ROOT=C:\Program Files\boost\boost_1_38
    set BOOST_VERSION=1_38
    set BOOST_CFG=mt

    setx BOOST_ROOT "!BOOST_ROOT!"
    setx BOOST_VERSION !BOOST_VERSION!
    setx BOOST_CFG !BOOST_CFG!
)


rem ####################################################################
rem # Allow local developer to over-ride standard environment variables

IF EXIST "%ISE_RC%" (
    echo Setting User over-rides for %USER% ...
    call "%ISE_RC%"
)


rem ######################################################################
rem # Completely overlay any existing value for %ISE_PATH%

rem # SMELL: the Debug / Release directories

set ISE_PATH=%ISE_ROOT%\bin\Debug
set ISE_PATH=!ISE_PATH!;!ISE_ROOT!\bin
set ISE_PATH=!ISE_PATH!;!ISE_ROOT!\bin\cm_tools\regression_test
set ISE_PATH=!ISE_PATH!;!ISE_ROOT!\bin\cm_tools
set ISE_PATH=!ISE_PATH!;!ISE_ROOT!\lib
set ISE_PATH=!ISE_PATH!;!ACE_ROOT!\bin
set ISE_PATH=!ISE_PATH!;!ACE_ROOT!\lib
set ISE_PATH=!ISE_PATH!;!BOOST_ROOT!\
set ISE_PATH=!ISE_PATH!;!MYSQL_ROOT!\bin
set ISE_PATH=!ISE_PATH!;!MYSQL_ROOT!\lib\opt

setx  ISE_PATH "!ISE_PATH!"


rem #######################################################
rem # For the purpose of this shell and any sub-shells
rem # temporarily over-ride system environment setting

set Path=!ISE_PATH!;%Path%



rem #######################################################
rem # Manually ensure that the system %Path% has %ISE_PATH%
rem # Goto Start > Control Panels > System > Advanced > Environment Variables
rem # Edit the Path variable by adding ISE_PATH variable to the end

echo ############################################################
echo Ready.  Use 'dump_env' to see complete environment settings.

@echo on
