#!/usr/bin/env bash
#
#
# First(almost) things first.
if [ -s ~/.bash_init ]
then  
	source ~/.bash_init
else
    logPrint "Skipping missing ~/.bash_init"	
fi

# Exports variables needed for the rest, and set options with shopt (Move to .init?)
if [ -s ~/.bash_env ]
then  
	source ~/.bash_env
else
    logPrint "Skipping missing ~/.bash_env"	
fi

if [ -s ~/.bash_$(hostname -s) ]
then  

    source ~/.bash_$(hostname -s)
fi

#Add home/bin/ to path.
export PATH="~/bin/:$PATH"

source ~/.bash_alias

source ~/.bash_functions

source ~/.gitComplete.bash
source ~/.bash_complete

__git_complete g __git_main
__git_complete gco _git_checkout
__git_complete gb _git_branch
#MY_SSH_KEY="~/.ssh/taisto.pem"
if  ! AGENT_PID=`pgrep  ssh-agent`
then
    logPrint "Starting SSH-AGENT SSH_AUTH_SOCK=[$SSH_AUTH_SOCK] SSH_AGENT_PID=[$SSH_AGENT_PID]"
    export SSH_AGENT_START=`ssh-agent -s`
    echo $SSH_AGENT_START >/tmp/ssh_agent
    eval $SSH_AGENT_START >/dev/null
    if [ -z "$MY_SSH_KEY" ]
    then
	logPrint "Skipping adding SSH key to ssh-agent, running @: $SSH_AGENT_START"
    else  
	ssh-add $MY_SSH_KEY
    fi
else
    INFO=`cat /tmp/ssh_agent`
    if [ -z "$INFO" ]
    then
        logPrint "Why havent we got accurate ssh_agent info? $(pgrep ssh-agent)"
        find /tmp/ -type s -name "*agent*"
    fi
    logPrint "Reading SSH_AGENT info: [$INFO] (PID:$AGENT_PID)"
    eval $INFO >/dev/null
fi

if isInteractiveShell
then
    echo "Finished processing .bashrc for user $USER (HOME=$HOME)"
    uptime
    # Only run when interactive, otherwise messes up scp..
fi
#export PS1="\$(printGitBranchForPS1IfAvail)\u@\h:$BLUE$BOLD\W$DEFAULT\e[0m/]>"
export PS1="\$(printGitBranchForPS1IfAvail)\u@\h:\W]>"
