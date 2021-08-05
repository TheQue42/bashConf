#!/usr/bin/env bash
cd ~
if [[ $1 =~ -a$|--all$ ]]
then
    IDENTICAL=YES
    shift
fi

function isSameContents()
{
	if diff -q $1 $2 >/dev/null 2>&1 
	then
		#cecho "$1 diff's the same as $2"
		export DATE_SYNC="NEEDED"
		SHA1=$(sha1sum $1 | cut -d" " -f 1)
		SHA2=$(sha1sum $2 | cut -d" " -f 1)
		if ! [ "$SHA1" == "$SHA2" ]
		then
			cecho -bold red "diff-check and sha dont agreee on $1:$SHA1 and $2:$SHA2"
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
    cecho -red "You might want to MERGE changes with upstream first?"
    echo "cd ~/bashConf; git pull --ff-only; git ls -2 ;cd -"
    exit
fi
cd ~

NODIFFS=TRUE
for file in .bashrc .bashrc.alias .bashrc.$(hostname -s) bashrc.$(uname -s) .bashrc.complete .bashrc.env .bashrc.functions .bashrc.git .bashrc.init
do
    CURR=$file
    GIT=~/bashConf/$file
    GITFILE="${PINK}~/bashConf/${CYAN}$file"
    if [ -s $CURR -a -s $GIT ]
    then
        NEWER="${RED}newer$CYAN"
        OLDER="${RED}older$CYAN"
        if isSameContents $CURR $GIT
        then
			if [ $GIT -nt $CURR -o $CURR -nt $GIT ]
			then
				cecho -bold "We need timesync for $CURR:"
				rsync -a $GIT $CURR
			fi
        elif [ $CURR -nt $GIT ]
        then
            echo ""
            cecho -bold "$CURR is $NEWER than $GITFILE"
            cecho green "diff -ab $CURR $GIT"
            cecho green "kdiff3 $CURR $GIT"
            cecho -bold green "rsync -avcu $CURR $GIT"
            echo ""
            NODIFFS=FALSE
            
        elif [ $GIT -nt $CURR ]
        then
            echo ""
            cecho -bold "$CURR is $OLDER than $GITFILE"
            cecho green "diff -ab $GIT $CURR"
            cecho green "kdiff3 $GIT $CURR"
            cecho -bold green "rsync -avcu $GIT $CURR"
            echo ""
            NODIFFS=FALSE
        elif [ "$IDENTICAL" == "YES" ]
        then
            ### TQ_TODO: Bugg in CLI param
            cecho green "File $CURR seems to be ${WHITE}identical$GREEN to $GIT"
        fi
    elif [ -s $CURR -o -s GIT ]
    then
        cecho -bold red "Mismatch for file $CURR, doesnt exist in both places"
        ls -l $CURR $GIT
        NODIFFS=FALSE
    fi
done

if [ $NODIFFS == "TRUE" ]
then
    cd ~/bashConf
    COMMIT_MESSAGE="${*:-Misc updates}"
    if git status | egrep "(Changes to be committed|Changes not staged for commit)"
    then
        cecho "cd ~/bashConf; git add -u ; git commit -m \"$COMMIT_MESSAGE\"; git push"
    fi
fi

