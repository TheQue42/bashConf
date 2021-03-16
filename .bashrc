#!/usr/bin/env bash
#
#
# First(almost) things first.
if [ -s ~/.bashrc.init ]
then  
	source ~/.bashrc.init
else
    logPrint "Skipping missing ~/.bashrc.init"	
fi

# Exports variables needed for the rest, and set options with shopt (Move to .init?)
if [ -s ~/.bashrc.env ]
then  
	source ~/.bashrc.env
else
    logPrint "Skipping missing ~/.bashrc.env"	
fi

if [ -s ~/.bashrc.$(hostname -s) ]
then  
    logPrint "Sourcing ~/.bashrc.$(uname -s)"
    source ~/.bashrc.$(hostname -s)
fi

if [ -s ~/.bashrc.$(uname -s) ]
then  
    logPrint "Sourcing ~/.bashrc.$(uname -s)"
    source ~/.bashrc.$(uname -s)
fi

#Add home/bin/ to path.
export PATH="~/bin/:$PATH"
if [ -d ~/bin/$(hostname -s) ]
then
    logPrint "Adding ~/bin/$(hostname -s) to PATH"
    export PATH="~/bin/$(hostname -s):$PATH"
fi

if [ -d ~/bin/$(uname -s) ]
then
    logPrint "Adding ~/bin/$(uname -s) to PATH"
    export PATH="~/bin/$(uname -s):$PATH"
fi

if isInteractiveShell
then
    # Source all aliases
    source ~/.bashrc.alias

    # Source all bash functions. (And manually 'export -f' them)
    source ~/.bashrc.functions

    source ~/.bashrc.git #https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    source ~/.bashrc.complete # Alias completion!

    __git_complete g __git_main
    __git_complete gco _git_checkout
    __git_complete gb _git_branch

    if [ -z "$SSH_AGENT_PID" ]
    then
        #MY_SSH_KEY="~/.ssh/taisto.pem"
        AGENT_PID=`pgrep -u $USER ssh-agent`
        AGENT_INFO_FILE=/tmp/ssh_agent_$USER
        if  [ -z "$AGENT_PID" ]
        then
            logPrint "Starting SSH-AGENT (Current SSH_AGENT_PID: $SSH_AGENT_PID)"
            export SSH_AGENT_START=`ssh-agent -s`
            echo $SSH_AGENT_START > $AGENT_INFO_FILE
            eval $SSH_AGENT_START >/dev/null
            if [ -z "$MY_SSH_KEY" ]
            then
                logPrint "Skipping adding SSH key to ssh-agent, running @: $SSH_AGENT_START"
            else
                ssh-add $MY_SSH_KEY
            fi
        else
            INFO=`cat $AGENT_INFO_FILE`
            if [ -z "$INFO" ]
            then
                logPrint "Why havent we got accurate ssh_agent info? $(pgrep -u $USER ssh-agent) AGENT_PID=$AGENT_PID"
            else
                logPrint "Reading saved ssh-agent info from $AGENT_INFO_FILE"
                eval $INFO >/dev/null
            fi
            echo "SSH_AGENT_PID: $SSH_AGENT_PID"
        fi
    else
        logPrint "Skipping ssh agent startup. SSH_AGENT_PID: $SSH_AGENT_PID"
    fi

    if [ $USER == root ]
    then
        RH="$RED"
        export PS1="\$(printGitBranchForPS1IfAvail)${GREEN}\u${DEFAULT}@\h:\W\n${RH}\\$> ${DEFAULT}"
    else
        RH="$GREEN"
        export PS1="\$(printGitBranchForPS1IfAvail)${GREEN}\u${DEFAULT}@\h:\W\n${RH}\\$> ${DEFAULT}"
    fi
    # export PROMPT_COMMAND="history -a;log_bash_persistent_history;date +%H:%M-%a_%d;" # Set in .bashrc.env
    logPrint "Finished processing ${GREEN}.bashrc$DEFAULT for user $USER (HOME=$HOME)"
    uptime
fi
