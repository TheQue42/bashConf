#!/usr/bin/env bash

logPrint "${GREEN}Reading ~/.bashrc.functions"

function isSuse()
{
    if [ -s /etc/os-release ]
    then
	grep -qi suse /etc/os-release
    else
	return 1
    fi
}

export -f isSuse

function isBsd()
{
    uname -a | egrep -iq bsd
}
export -f isBsd

function is()
{
    if type $1 | egrep -i --color=auto -iq "function"; then
        type $1;
    else
        ali\as $1;
    fi
}
export -f is

function stripcom()
{
    egrep -v "^(\s*#|$)" $1 
}

function ttr() {
    find . -mount -name "*~" | xargs -t -r rm
}
export -f ttr

function dl()
{
  if ! isBsd 
  then
    journalctl $* | egrep "error|warn|daemon"
  else
    cat /var/log/daemon
  fi
}
export -f dl

function pl()
{
  if ! isBsd 
  then
    journalctl -b $* | egrep -i "postfix|smtp"
  else
    cat /var/log/maillog
  fi
}
export -f pl

function rl()
{
  if ! isBsd 
  then
      if [[ "$1" = [0-9]+ ]]
      then
	  echo "Last $1 lines..."
	  LAST=$1
	  shift
      fi
      journalctl -n $LAST $* 
  else
    cat /var/log/daemon
  fi
}

function hl()
{
    if [[ "$1" = [0-9]+ ]]
    then
	echo "Last $1 lines..."
	LAST=$1
	shift
    fi
    tail -n ${LAST:-100} $HAL $* 
}
export -f rl hl


function eeh()
{
    if [ -z "$1" ]
    then
	emacs -nw $HA/configuration.yaml
    else
	cecho -bold emacs -nw $HA/${1}*yaml
	sleep 0.4
	if [[ $1 =~ auto ]]
	then
	    emacs -nw $HA/auto*yaml
	else
	    emacs -nw $HA/$1*yaml
	fi
    fi
}


function psG()
{
  PS_PARAMS="-elF"  #or alx?
  
  echo -e $YELLOW"Full List:"$DEFAULT
  ps $PS_PARAMS | grep $1 | grep -v grep
  echo ""
  echo -e $GREEN "Filtered:" $DEFAULT
  ps $PS_PARAMS | grep $1 | awk '{print $3"    "$4"    "$17}'

}

function colstrip()
{
    perl -ane "print \$F[$1] . \"\n\""
}


function cecho() 
{ 
    DEFAULT="\e[0m";
    BOLD="\e[1m";
    BLACK="\e[30m";
    NOTBOLD="\e[22m";
    RED="\e[31m";
    GREEN="\e[32m";
    YELLOW="\e[33m";
    BLUE="\e[34m";
    PINK="\e[35m";
    CYAN="\e[36m";
    WHITE="\e[37m";
    UNDERLINE="\e[4m";
    BLINK="\e[5m";
    INVERSE="\e[7m";
    
    if [ -z "$1" ]; then
        echo -en $DEFAULT;
        return;
    fi;
    if [[ $1 =~ bold ]]; then
        SET_BOLD=$BOLD;
        shift;
    else
        SET_BOLD=$NOTBOLD;
    fi;
    if [[ $1 =~ red ]]; then
        COLOR=$RED;
        shift;
    else
        if [[ $1 =~ green ]]; then
            COLOR=$GREEN;
            shift;
        else
            if [[ $1 =~ yellow ]]; then
                COLOR=$YELLOW;
                shift;
            else
                if [[ $1 =~ blue ]]; then
                    COLOR=$BLUE;
                    shift;
                else
                    if [[ $1 =~ white ]]; then
                        COLOR=$WHITE;
                        shift;
                    else
                        if [[ $1 =~ pink ]]; then
                            COLOR=$PINK;
                            shift;
                        else
                            if [[ $1 =~ cyan ]]; then
                                COLOR=$CYAN;
                                shift;
                            else
                                if [[ $1 =~ black ]]; then
                                    COLOR=$BLACK;
                                    shift;
                                else
                                    COLOR=$CYAN;
                                fi;
                            fi;
                        fi;
                    fi;
                fi;
            fi;
        fi;
    fi;
    if test -t 1; then
        echo -e ${SET_BOLD}${COLOR}"$*"$DEFAULT;
    else
        echo -e "$*";
    fi
}
declare -fx cecho



###
# GIT STUFF
###
function printGitBranchForPS1IfAvail
{
    GIT_BRANCH=`parse_git_branch`
    if ! [ -z $GIT_BRANCH ]
    then
        echo -e $BOLD[${UNBOLD}${BLACK}git:$BLUE${GIT_BRANCH}$BLACK$BOLD]$UNBOLD
    else
	echo -e $DEFAULT
    fi
}

function parse_git_branch() 
{ 
    ref=$(git-symbolic-ref HEAD 2> /dev/null) || return;
    echo ${ref#refs/heads/}
}
declare -fx parse_git_branch

function getBranchPoint()
{
    full_ref=$(git-symbolic-ref HEAD 2> /dev/null)
    local_branch=${full_ref#refs/heads/}
    diff --old-line-format='' --new-line-format='' <(git rev-list --first-parent "${1:-origin/sv}") <(git rev-list --first-parent "${local_branch:-bugfix}") | head -1
}
declare -fx getBranchPoint


function reMatch {
    typeset ec
    unset -v reMatch # initialize output variable
    cecho "String is: [$GREEN$1$CYAN] - Regexp: [$DEFAULT$BOLD$2$CYAN]"
    [[ $1 =~ $2 ]] # perform the regex test
    ec=$? # save exit code
    if [[ $ec -eq 0 ]]; then # copy result to output variable
	echo -e "1=${BASH_REMATCH[1]}, 2=${BASH_REMATCH[2]}, 3=${BASH_REMATCH[3]}, $BOLD${BLUE}ALL=$GREEN${BASH_REMATCH[@]}$DEFAULT"
	[[ -n $BASH_VERSION ]] && reMatch=( "${BASH_REMATCH[@]}" )
	[[ -n $KSH_VERSION ]]  && reMatch=( "${.sh.match[@]}" )
	[[ -n $ZSH_VERSION ]]  && reMatch=( "$MATCH" "${match[@]}" )
    else
	echo NoMatch 1>&2
    fi
    return $ec
}

################################################################################
#                              HISTORY STUFF
################################################################################
function log_bash_persistent_history() 
{ 
    local HISTTIMEFORMAT="[%Y] - %a, %d %b, %H:%M - ";
#    HISTTIMEFORMAT_REQ="$HISTTIMEFORMAT"
#    if [ "$HISTTIMEFORMAT" != "$HISTTIMEFORMAT_REQ" ]; then
#        echo -e $RED"HISTTIMEFORMAT is not valid for log_bash_persistent_history() $HISTTIMEFORMAT != $HISTTIMEFORMAT_REQ"$DEFAULT;
#        return;
#    fi;
    LAST_CMD="$(history 1)"

    #NR  [YEAR] - DATE_AND_TIME - COMMAND
    #local regexp="^[0-9]{1,6}[ ]+\[[0-9]+\][ ]+-[ ]+(.*)[ ]+-[ ]+(.*)$"
    
    #[[ $(history 1) =~ ^[0-9]{1,6}\ \[.+\]\ -\ (.*)\ -\ +(.*)$ ]];
    #[[ $(history 1) =~ ^.*\[(.*?)\]\ -\ (.*?)\ -\ (.*)$ ]];
    #[[ $LAST_CMD =~ ^.*\[[0-9]+\]\ -\ (.*)\ -\ +(.*)$ ]];
    regexp=".*\[(.*)\][ ]+-\ (.*)[ ]+-(.*)"
    [[ $LAST_CMD =~ $regexp ]]
    eq=$?
    local year_part="${BASH_REMATCH[1]}";
    local date_part="${BASH_REMATCH[2]}";
    local command_part="${BASH_REMATCH[3]}";
    if [[ $command_part =~ ^cliGrep ]]; then
        return;
    fi;
    if [ -z "$command_part" ]
    then
	cecho red "Failed to log_bash_persistent_history($?) cmdpart=[$1] last_cmd=$LAST_CMD"
	return
    fi
    
    if [ "$command_part" != "$PERSISTENT_HISTORY_LAST" ]; then
        echo $date_part "|" "$command_part" >> ~/.persistent_history.$year_part;
        export PERSISTENT_HISTORY_LAST="$command_part";
    else
        if [ "$HIST_DEBUG" != "" ]; then
            cecho "Not logging ($PERSISTENT_HISTORY_LAST == $command_part)";
        fi;
    fi
}
declare -fx log_bash_persistent_history


function cliGrep()
{
    PERM_HIST=~/.persistent_history.20`date +%y`;
    if [[ $1 =~ ^-a ]]
    then
        shift
        if ! [ -z "$*" ]
        then
            # echo "Running [egrep "$*" $PERM_HIST]"
            egrep "$*" $PERM_HIST;
            return
        fi
    elif [[ $1 =~ ^-m ]]
    then
        INTERVAL=${1#-m};
        INTERVAL=$((INTERVAL*100))
        shift
        cecho "interval = $INTERVAL"
        egrep "$@" $PERM_HIST | tail -$INTERVAL;
        return
    elif ! [ -z $* ]
    then
        DAY_NAME=`date +%a`;
        DAY_NR=`date +%d`; # 0-Indexed
        cecho "Date-based ($*) [grep \"^$DAY_NAME, $DAY_NR\" $PERM_HIST]"
        egrep  "^$DAY_NAME, $DAY_NR" $PERM_HIST | egrep "$*"
        return
    fi
    cecho -bold red "What do you want to grep for??"
}
declare -fx cliGrep


function doneDate() 
{ 
    PERM_HIST=~/.persistent_history.20`date +%y`;
    if [[ $1 =~ -m ]]; then
        MONTH=$2;
        shift;
        shift;
    else
        MONTH=`date +%h`;
    fi;
    if [ -z $1 ]; then
        DAY_NR=`date +%d`;
    else
        DAY_NR="$1";
        shift;
    fi;
    if ! [ "$DAY_NR" -ge 1 -a "$DAY_NR" -le 31 ]; then
        cecho red "Invalid Day_nr($DAY_NR), using today:  $DAY_NR";
    fi;
    if [[ $1 =~ all ]]; then
        ALL=yes;
        shift;
    else
        ALL="";
    fi;
#    if [ $DAY_NR -lt 10 ]; then
#        DAY_NR="$DAY_NR";
#    fi;
    if [ -z $MONTH ]; then
        MONTH=`date +%b`;
    fi;
    YEAR=`date +%Y`;
    ALL_DAY="/tmp/doneDate.$DAY_NR.$MONTH.all";
    egrep --color=never "^[a-zA-Z]{3,3}, $DAY_NR $MONTH," $PERM_HIST | sort -n > $ALL_DAY;
    head -15 $ALL_DAY;
    tail -15 $ALL_DAY;
    if [ -z $ALL ]; then
        echo "cat $ALL_DAY";
        wc -l $ALL_DAY;
        echo "";
    else
        echo ====================;
        cat $ALL_DAY;
    fi
}
declare -fx doneDate

############################
#    Docker stuff
#######################
function dps()
{
    TABLE="table {{.ID}}\t{{.Names}}\t{{.Status}}"
#    echo table=$TABLE
    if [ -z $1 ]
    then
        docker ps --format "$TABLE"
    else
        docker ps --format "$TABLE" | egrep "(CONTAINER ID|$*)"
    fi
}


#ml()
#{
#    LIST=`find  /var/lib/docker/volumes/kolla_logs/_data/ | grep $1`
#    for i in $LIST
#    do
#        echo cat $i
#    done
#}

function dshell()
{
    if [ $# -lt 2 ]
    then
        CMD_RUN=bash
        CONTAINER=$1
    else
        CONTAINER=$1
        shift
        CMD_RUN="$*"
    fi
    echo "docker exec -it $CONTAINER $CMD_RUN"
    docker exec -it $CONTAINER $CMD_RUN
}



function dll()
{
    local TABLE="table {{.ID}}\t{{.Names}}\t{{.Status}"
    if [ -z $1 ]; then
        echo "Which container?";
        dps
        return 1;
    fi;
    echo "Searching for containers matching [$1]...";
    FOUND="";
    FILTER=$1;
    shift;
    for c in `docker ps --format "{{.Names}}"`;
    do
        if [[ $c =~ $FILTER ]]; then
            echo -e "=========== Found container: $CYAN$BOLD$c$DEFAULT ==============";
            sleep 1;
            docker logs $c $*;
            echo "---------------- End -------------------------";
            FOUND="TRUE";
        fi;
    done;
    if [ -z $FOUND ]; then
        echo "Container matching [$FILTER] NOT found";
        docker ps --all --format  $TABLE
    fi
}


function dDump()
{
   local TABLE="table {{.ID}}\t{{.Names}}\t{{.Status}}"
   if [ -z $1 ]
   then
       echo "Which container?"
       dps
       return 1
   fi
   echo "Searching for containers matching [$1]..."
   FOUND=""
   for c in `docker ps --format "{{.Names}}"`
   do
       if [[ $c =~ $1 ]]
       then
           echo "=========== Found container: $c =============="
           sleep 1
           docker inspect $c
           echo "---------------- End -------------------------"
           FOUND="TRUE"
       fi
   done
   if [ -z $FOUND ]
   then
       echo "Container($1) NOT found"
       docker ps --all --format $TABLE
   fi
}

function cdLL()
{
   if [ -z $1 ]
   then
       echo "Listing logs in /var/lib/docker/volumes/kolla_logs/_data"
       echo ""
       find /var/lib/docker/volumes/kolla_logs/_data -name "*.log"
   else
       echo "Will search for logfiles matching name [$1]..."
       FILE=`find /var/lib/docker/volumes/kolla_logs/_data -name "*.log" | grep $1`
       if [ -s "$FILE" ]
       then
           echo more $FILE
       elif [ -s "$FILE.log" ]
       then
           echo more $FILE
       else
           for i in $FILE
           do
               echo more $i
           done
       fi
       echo "------end-----"
   fi
}


##################################################################################################################
#                                             ERICSSON CMCO STUFF
##################################################################################################################
function _tq_cmco_comp() 
{ 
    local cur=${COMP_WORDS[COMP_CWORD]};
    LIST="carsel dns http icmp netmon numana numnorm parsers sigcomp sip";
    COMPREPLY=($(compgen -W "$LIST" -- $cur))
}
declare -fx _tq_cmco_comp

function _tq_cmco_start() 
{ 
    local cur=${COMP_WORDS[COMP_CWORD]};
    LIST="";
    for i in `ls -ld /local/scratch/git/* | egrep "^d" | perl -ane 'print $F[8] . "\n" '`;
    do
        NEW=`basename $i`;
        LIST="$LIST $NEW";
    done;
    COMPREPLY=($(compgen -W "$LIST" -- $cur))
}
declare -fx _tq_cmco_start
function parse_git_root()
{
    GIT_DIR=${PWD##/local/scratch/git/}
    GIT_ROOT=${GIT_DIR%%/*}
    echo $GIT_ROOT
}
