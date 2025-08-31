#!/usr/bin/env bash
#
# Taisto Qvists bash-util for keeping track of .bashrc* configuration files for multiple hosts.
#
# 

cd ~
if [[ $1 =~ -a$|--all$ ]]
then
    IDENTICAL=YES
    shift
fi

function calc_sha()
{
    if uname -s | grep -iq bsd
    then
        sha1 $*
    else
        sha1sum $*
    fi
}
export -f calc_sha

function isSameContents()
{
    if diff -q $1 $2 >/dev/null 2>&1 
    then
        export DATE_SYNC="NEEDED"
        # TQ-TODO: Will it work to use the calc_sha function in $() ?
        SHA1=$(calc_sha $1 | cut -d" " -f 1)
        SHA2=$(calc_sha $2 | cut -d" " -f 1)
        if ! [ "$SHA1" == "$SHA2" ]
        then
            cecho -bold red "DIFF check OK, but sha dont agreee on $1:$SHA1 and $2:$SHA2 ??"
            return -2
        fi  
        return 0
    fi
    return 1
}

cd ~/bashConf
echo "Fetching latest git updates from repo..."
git fetch
if git status | grep behind
then
    cecho red "You might want to MERGE changes with upstream first?"
    pushd ~/bashConf && git pull --ff-only && git ls -2 && popd
    exit $?
elif git status | grep ahead
then
    echo "Have you forgotten to do:"
    echo "pushd ~/bashConf/; git push; popd"
    exit 1
fi
cd ~

KD3=${DIFFTOOL:-kdiff3}
NODIFFS=TRUE
for GIT_FILE in $HOME/bashConf/.bashrc* 
do
    file=$(basename ${GIT_FILE})
    CURR="$HOME/$file"
    GIT=~/bashConf/$file
    GITFILE="${PINK}~/bashConf/${CYAN}$file"

    if [[ "$1" =~ -v$|--verbose$ ]]
    then
        echo "Checking file: $file"
    fi

    if [ -s $CURR -a -s $GIT ]
    then
        NEWER="${RED}newer$CYAN"
        OLDER="${RED}older$CYAN"
        if isSameContents $CURR $GIT
        then
            if [ $GIT -nt $CURR -o $CURR -nt $GIT ]
            then
                cecho -bold "Timesyncing for $CURR:"
                rsync -a $GIT $CURR
            fi
        elif [ $CURR -nt $GIT ]
        then
            echo ""
            cecho -bold "$CURR is $NEWER than $GITFILE"
            cecho green " diff -ab $CURR $GIT"
            cecho green " $KD3 $CURR $GIT"
            cecho -bold green " rsync -avcu $CURR $GIT"
            echo ""
            NODIFFS=FALSE
        elif [ $GIT -nt $CURR ]
        then
            echo ""
            cecho -bold "$CURR is $OLDER than $GITFILE"
            cecho green " diff -ab $GIT $CURR"
            cecho green " $KD3 $GIT $CURR"
            cecho -bold green " rsync -avcu $GIT $CURR"
            echo ""
            NODIFFS=FALSE
        elif [ "$IDENTICAL" == "YES" ]
        then
            cecho green "File $CURR seems to be ${WHITE}identical$GREEN to $GIT"
        fi
    elif [ -s $CURR -o -s $GIT ]
    then
        if [[ $file =~ private ]] 
        then
            cecho "Ignoring mismatch on private file: $file"
            continue
        fi
        if grep -q CUSTOM_NODE_CONFIG_FILE $CURR 2>/dev/null || grep -q CUSTOM_NODE_CONFIG_FILE $GIT 2>/dev/null
        then
            cecho "Ignoring mismatch on NODE-LOCAL config file: $file"
            continue
        fi
        cecho -bold red "Mismatch for file $file, doesnt exist in $HOME or ~/bashConf/"
        ls -l $CURR $GIT 2>/dev/null
        NODIFFS=FALSE
    fi
done

if [[ "$1" =~ -v$|--verbose$ ]]
then
    shift
fi

COMMIT_MESSAGE="${*:-Misc updates}"
if [ $NODIFFS == "TRUE" ]
then
    cd ~/bashConf
    if git status | grep -E "(Changes to be committed|Changes not staged for commit)"
    then
        cecho "pushd ~/bashConf; git add -u && git commit -m \"$COMMIT_MESSAGE\" && git push; popd"
    fi
fi

if ping -q -c 3 -i 0.005 gollum.disc-world.se >/dev/null
then
    cd $HOME/bin/
    git fetch
    if git status --long | grep -E -q "behind"
    then
        cecho -bold red "$HOME/bin needs syncing as well:"
        pushd $HOME/bin && git pull --ff-only && git ls -2 && popd
    fi
    if git status --long | grep -E -q "ahead|Changes not staged for commit"
    then
        cecho -bold red "$HOME/bin needs syncing as well:"
        echo "--------------"
        git status -s
        echo "=============="
        cecho " pushd $HOME/bin; git add -u && git commit -m \"$COMMIT_MESSAGE\" && git push ; popd"
    fi
else
    echo "Gollums seems shutdown, skipping ~/bin-sync"
fi
