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

if [ -s ~/.bashrc.$(uname -s) ]
then
    logPrint "Sourcing ~/.bashrc.$(uname -s)"
    source ~/.bashrc.$(uname -s)
fi

# Source the host-specific last, so it can override.
if [ -s ~/.bashrc.$(hostname -s) ]
then
    logPrint "Sourcing ~/.bashrc.$(hostname -s)"
    source ~/.bashrc.$(hostname -s)
else
    logPrint $RED"Hostname-local [~/.bashrc.$(hostname -s)] ${BLACK}NOT$RED found, ${BLUE}skipping"
fi

BASH_PASS="$HOME/.bashrc_private"
if [ -f $BASH_PASS ]
then
    chmod 600 $BASH_PASS
    logPrint $BOLD$RED"Sourcing $BASH_PASS"
    source $BASH_PASS
fi

addToPath ~/bin

if [ -d ~/bin/$(hostname -s) ]
then
    addToPath ~/bin/$(hostname -s)
fi

if [ -d ~/bin/$(uname -s) ]
then
    addToPath ~/bin/$(uname -s)
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

    if [ -s ~/.bashrc.$(hostname -s) ]
    then
	logPrint "ReSourcing ~/.bashrc.$(hostname -s) to ensure local aliases are overridden."
	source ~/.bashrc.$(hostname -s)
    fi
    
    # If you want to disable ssh-agent startup, just set SSH_AGENT_PID to anything, in .bashrc.env or .bashrc.<hostname>
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
                logPrint "Why havent we got accurate ssh_agent info? "
                #$(pgrep -u $USER ssh-agent) AGENT_PID=$"
                logPrint "It seems to be running on PID: $AGENT_PID"
                pgrep -la -u $USER ssh-agent
                cecho -bold blue "pkill -e -u \$USER ssh-agent"
            else
                logPrint "Reading saved ssh-agent info from $AGENT_INFO_FILE"
                eval $INFO >/dev/null
            fi
            echo -e "SSH_AGENT_PID: $SSH_AGENT_PID\n"
        fi
    else
        logPrint "Skipping ssh agent startup. SSH_AGENT_PID: $SSH_AGENT_PID"
    fi
    # There seems to be some issues with $COLORS in the PS1, that causes havok with console settings/cursor location sometimes..
    # Created bash function 'consoleReset' to repair PS1
    if [ $USER == root ]
    then
        RH="$RED"
    else
        RH="$GREEN"
    fi
    export PS1="\$(printGitBranchForPS1IfAvail)$RH$BOLD\u$RST@\h:\W\n\\$> "
    export PS_ORG=${PS1}
    export PS_A="\$(printGitBranchForPS1IfAvail)\u@\h:\W\\$> "

    logPrint "Finished processing ${GREEN}.bashrc$DEFAULT for user $USER (HOME=$HOME)"
    uptime
fi
