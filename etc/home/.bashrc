##########################################################
###
##  File: .bashrc
##  Desc: Setup basic symboles for ISE operation
##
# NOTE: Nothing should be printed on STDOUT/STDERR unless
#       $SHLVL is 3.
#


###########################
# Source global definitions

if [ -f /etc/bashrc ]; then
	source /etc/bashrc
fi

if [ -f $HOME/.proxyrc ]; then
	source $HOME/.proxyrc
fi

if [ -f $HOME/.roots ]; then
	source $HOME/.roots
fi


######################################
## Setup the Ruby environment

export RUBYOPT=rubygems

if [ -s ~/.rvm/scripts/rvm ] ; then
  source ~/.rvm/scripts/rvm
  PS1="\$(~/.rvm/bin/rvm-prompt) $PS1"
fi

alias r187='rvm use 1.8.7'
alias r192='rvm use 1.9.2'
alias r193='rvm use 1.9.3-head'
alias r2='rvm use ruby-head'
#
alias rjr='rvm use jruby'
alias rree='rvm use ree'
alias rsys='rvm use system'
alias rdef='rvm use default'


#####################################
# User specific aliases and functions

alias ls='ls --color=never'
alias ll='ls -alF'
alias lll='ll | less'

alias ssh='ssh -X'

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias xdd="xxdiff -r -e '.svn' -e '*~'"
alias ii='ps aux | fgrep -i ise'
alias agrep="agrep -d '\n\n'"

alias kr='ise --killrun'
alias status='svn status | fgrep -v .svn | fgrep -v .depend | fgrep -v GNUmakefile | fgrep -v .vcproj | fgrep -v .shobj | fgrep -v .obj'

alias roots='echo; env|sort|fgrep ROOT -;echo'

alias cpan='perl -MCPAN -e shell'


export PATH=$HOME/scripts:$HOME/bin:/usr/sbin:/sbin:$PATH


# Establish the top-level setup symbols for all projects under development
fgrep _ROOT ~/.roots | gawk -F'[ =]' '{print "source $" $2"/setup_symbols"}' > $HOME/setup_symbols
alias sss='source $HOME/setup_symbols'


# rsync on windows requires a "clean" shell which means no echos
# A remote login like done by rsync on windows, sets SHLVL to 1
# ssh will also set SHLVL to 1
# Local login to a shell from gnome sets SHLVL to 3

if [ 3 -eq $SHLVL ]
then
  echo ""
  echo "Ready.  Enter the command 'sss' to establish the ISE environment."
fi
