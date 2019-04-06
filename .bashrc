#!/usr/bin/env bash
#
#


# Exports variables needed for the rest, and set options with shopt
source ~/.bashrc.env

# First(almost) things first.
source ~/.bashrc.init

if [ -s ~/.bashrc.$(hostname -s) ]
then  
    source ~/.bashrc.$(hostname -s)
fi

#Add home/bin/ to path.
export PATH="~/bin/:$PATH"


source ~/.bashrc.alias

source ~/.bashrc.functions

source ~/.gitComplete.bash

__git_complete g __git_main
__git_complete gco _git_checkout
__git_complete gb _git_branch


if  ! pgrep ssh-agent
then
    if [ -z "$NO_SSH_AGENT" ]
    then
	logPrint "Starting SSH-AGENT SSH_AUTH_SOCK=[$SSH_AUTH_SOCK] SSH_AGENT_PID=[$SSH_AGENT_PID]"
	export SSH_AGENT_START=`ssh-agent -s`
	echo $SSH_AGENT_START >/tmp/ssh_agent
	eval $SSH_AGENT_START
	if ! [ -z $TQ_SSH_KEY ]
	then
	    ssh-add $TQ_SSH_KEY
	else  
	    logPrint "Skipping adding SSH key to ssh-agent, running @: $SSH_AGENT_START"
	fi
    fi
else
    INFO=`cat /tmp/ssh_agent`
    logPrint "Reading SSH_AGENT info: [$INFO]"
    eval $INFO
fi

if isInteractiveShell
then
    echo "Finished processing .bashrc for user $USER (HOME=$HOME)"
    uptime
    # Only run when interactive, otherwise messes up scp..
fi
#export PS1="\$(printGitBranchForPS1IfAvail)\u@\h:$BLUE$BOLD\W$DEFAULT\e[0m/]>"
export PS1="\$(printGitBranchForPS1IfAvail)\u@\h:\W]>"
