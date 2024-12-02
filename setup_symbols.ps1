###############################################################
###
##  File:  setup_symbols.ps1
##  Desc:  Establish the system environment varialbes required by ISE
##         within an MS Windows Powershell console environment
##
##  IMPORTANT: To ease maintenance please keep the order of settings in
##             this file in sync with the setup_symbols.cmd file.
#

$env:HOME    = "$env:HOMEDRIVE$env:HOMEPATH"
$env:ISE_RC  = "$env:HOME\dot_iserc.ps1"

# new-item -force -path env: -name HTTP_PROXY -value "http://138.209.111.74:80"

#####################################
# Extract the IPADDRESS from ipconfig

new-item -force -path env: -name IPADDRESS -value ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]

$env:HOSTNAME  = "$env:COMPUTERNAME"
$env:USER      = "$env:USERNAME"

Write-Output
Write-Output "$env:HOSTNAME: $env:USER @ $env:IPADDRESS"
Write-Output "Setting ISE variables ..."

new-item -force -path env: -name ISE_QUEEN    -value "138.209.52.146"


$env:ISE_GATEWAY = "138.209.52.146"
$env:ISE_PORT    = "8003"


new-item -force -path env: -name ISE_ROOT -value (get-location)
new-item -force -path env: -name ISE_RUN  -value (get-location)

new-item -force -path env: -name  ISE_CLUSTER -value "LabPC105 pcig22 pcig24 pcig26 pcig28 pcig31"


###########################
# Environment used by Rails
# Values:         Meaning:
#   development ... working on localhost
#   test .......... integration testing
#   staging ....... acceptance testing
#   production .... live

Write-Output "Setting RAILS variables ..."

new-item -force -path env: -name ISE_ENV   -value "development"
new-item -force -path env: -name RAILS_ENV -value "$env:ISE_ENV"

############################
# Ruby and Rails Things

new-item -force -path env: -name RAILS_ROOT -value "$env:ISE_ROOT\WebApp\Portal"
new-item -force -path env: -name RUBYLIB -value "$env:RAILS_ROOT\lib;$env:RAILS_ROOT\app\models"

##############################################
# Make rake tasks available outside the Portal
# symbolic links are bug sources on MS Windows
# make sure that svn:ignore Rakefile is set for %ISE_ROOT%

if (not exist $env:ISE_ROOT\Rakefile)
{
    Copy-Item $filesystem::$env:RAILS_ROOT\Rakefile -destination $filesystem::$env:ISE_ROOT"
}

#######################################################
# Create the svn:ignored directories inside $RAILS_ROOT

# FIXME: ps1 conditional and mkdir

if (not exist $env:RAILS_ROOT\log)
{
    Mkdir $env:RAILS_ROOT\log
    Mkdir $env:RAILS_ROOT\tmp
}

####################################
# In support of the MPC build system

echo "Setting system-level build/execution variables ..."

# MySQL version 5.1 API not yet supported by RAILS
#   ... using latest revision of 5.0

if ("x$env:MYSQL_ROOT" -eq "x")
{
    new-item -force -path env: -name MYSQL_ROOT    -value "C:\mysql-5.0.77-win32"
}

if ("x$env:ACE_ROOT" -eq "x")
{
    new-item -force -path env: -name ACE_ROOT -value "C:\ACE_wrappers"
    new-item -force -path env: -name MPC_ROOT -value "$env:ACE_ROOT\MPC"
    new-item -force -path env: -name TAO_ROOT -value "$env:ACE_ROOT\TAO"
}

# $env:boost is only used with remake.rb inside the shell

$env:boost = 1

if ("x$env:BOOST_ROOT" == "x")
{
    new-item -force -path env: -name BOOST_ROOT    -value "C:\Program Files\boost\boost_1_37"
    new-item -force -path env: -name BOOST_VERSION -value "1_37"
    new-item -force -path env: -name BOOST_CFG     -value "mt"
}



####################################################################
# Allow local developer to over-ride standard environment variables

if (exist '$env:ISE_RC')
    Write-Output "Setting User ovdr-rides ..."
    call '$env:ISE_RC'"
}

######################################################################
# Completely overlay any existing value for %ISE_PATH%

# SMELL: the Debug / Release directories

set-item -path env:ISE_PATH -value "$env:ISE_ROOT\bin\Debug"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\bin"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\bin\cm_tools\regression_test"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\bin\cm_tools"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\lib"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\bin"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:ISE_ROOT\lib"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:BOOST_ROOT"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:MYSQL_ROOT\bin"
set-item -path env:ISE_PATH -value "$env:ISE_PATH;$env:MYSQL_ROOT\lib\opt"



#######################################################
# For the purpose of this shell and any sub-shells
# temporarily over-ride system environment setting

# $env:Path = $env:ISE_PATH;$env:Path



############################################################
# Manually ensure that the system $env:Path has $env:ISE_PATH
# Goto Start > Control Panels > System > Advanced > Environment Variables
# Edit the Path variable by adding ISE_PATH variable to the end


Write-Output "Ready.  Use 'dump_env' to see complete environment settings."

Write-Output
Write-Output "This is Windows Powershell. I " -nonewline
Write-Output "HATE" -foregroundcolor white -backgroundcolor red -nonewline
Write-Output " windows."
Write-Output "You should as well."
Write-Output
