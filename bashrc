#---------------------------------------------------------------
# Global bashrc File
# $Id$
#---------------------------------------------------------------

# Ensure that we are in a bash shell, otherwise don't source
# this file
if [ ! -n "${BASH_VERSION}" ]; then
	return
fi 

# Gets the cvs version of the bashrc file
BASHRCVERSION="`echo '$Revision$' | awk '{ print $2 }'`"
export BASHRCVERSION


#---------------------------------------------------------------
# Define Default System Paths
#---------------------------------------------------------------

# Determines the machine OS to set PATH, MANPATH and ID
OS="`uname -s`"
case "$OS" in
SunOS)		# Solaris
	case "`uname -r`" in
	"5.10"|"5.11")	# Solaris 10 and Nevada (11)
		_append_adminpath()
		{
			if [ -d "$1" ]; then
				ADMINPATH="$ADMINPATH:$1"
			fi
		}
		_append_path()
		{
			if [ -d "$1" ]; then
				PATH="$PATH:$1"
			fi
		}
		_append_manpath()
		{
			if [ -d "$1" ]; then
				MANPATH="$MANPATH:$1"
			fi
		}

		ADMINPATH=""
		_append_adminpath /opt/local/sbin
		_append_adminpath /usr/gnu/sbin
		_append_adminpath /usr/local/sbin
		_append_adminpath /usr/platform/`uname -i`/sbin
		ADMINPATH="$ADMINPATH:/sbin:/usr/sbin"

		PATH="$ADMINPATH"
		_append_path /opt/local/bin
		_append_path /usr/gnu/bin
		_append_path /usr/local/bin
		PATH="$PATH:/bin:/usr/bin:/usr/ccs/bin"
		_append_path /usr/openwin/bin
		_append_path /usr/dt/bin
		_append_path /opt/sun/bin
		_append_path /opt/SUNWspro/bin
		_append_path /opt/SUNWvts/bin

		MANPATH="$MANPATH"
		_append_manpath /opt/local/share/man
		_append_manpath /usr/gnu/man
		_append_manpath /usr/local/man
		MANPATH="$MANPATH:/usr/man:/usr/share/man"
		_append_manpath /opt/SUNWspro/man
		_append_manpath /opt/SUNWvts/man

		ID=/usr/xpg4/bin/id

		if [ -d "/usr/local/lib/python2.6/site-packages" ]; then
			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.6/site-packages"
		fi
		if [ -d "/usr/local/lib/python2.5/site-packages" ]; then
			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.5/site-packages"
		fi
		if [ -d "/usr/local/lib/python2.4/site-packages" ]; then
			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.4/site-packages"
		fi
		if [ -n "$PYTHONPATH" ]; then
			export PYTHONPATH
		fi

		# Files you make look like rw-r--r--
		umask 022

		# Make less the default pager
		which less > /dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			PAGER="`which less`"
			export PAGER
		fi

		unset ADMINPATH _append_adminpath _append_path _append_manpath
		;;
	esac
	;;

Darwin)		# Mac OS X
	# Set the PATH based on original /etc/profile from 
	# 10.3.6 on 2004/11/22.
	PATH="/bin:/sbin:/usr/local/bin:/usr/bin:/usr/sbin"
	if [ -d "/opt/local/sbin" ]; then
			PATH="/opt/local/sbin:$PATH"
	fi
	if [ -d "/opt/local/bin" ]; then
			PATH="/opt/local/bin:$PATH"
	fi
	MANPATH="$MANPATH"
	if [ -d "/opt/local/man" ]; then
		MANPATH="$MANPATH:/opt/local/man"
	fi

	# if we can determine the version of java as set in java prefs, then export
	# JAVA_HOME to match this
	if [ -f "/usr/libexec/java_home" ]; then
		JAVA_HOME=`/usr/libexec/java_home`
		export JAVA_HOME
	fi

	# if grails is installed via macports, then export GRAILS_HOME
	if [ -f "/opt/local/bin/grails" -a -d "/opt/local/share/java/grails" ]; then
		GRAILS_HOME=/opt/local/share/java/grails
		export GRAILS_HOME
	fi

	ID=/usr/bin/id
	;;

OpenBSD)	# OpenBSD
	# Set a base PATH for all users
	PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin"
	ID=/usr/bin/id

	# If user is not root (uid=0), then expand the PATH
	if [ "`$ID -ur`" -ne "0" -a -d "/usr/X11R6/bin" ]; then
		PATH="$PATH:/usr/X11R6/bin"
	fi
	;;

Linux)		# Linux
	ID=/usr/bin/id
	if [ -f "/etc/redhat-release" ]; then
		LINUX_FLAVOR="`awk '{print $1}' /etc/redhat-release`"
	fi
	if [ -f "/etc/lsb-release" ]; then
		LINUX_FLAVOR="`head -n 1 /etc/lsb-release | awk -F= '{print $2}'`"
	fi

	# check for ls --color alias and toast it
	alias | grep -q '^alias ls=' && unalias ls
	;;

CYGWIN_*)	# Windows running Cygwin
	ID=/usr/bin/id
	;;
esac # uname -s

# If a $HOME/bin directory exists, add it to the PATH
if [ -d "$HOME/bin" ]; then
	PATH="$PATH:$HOME/bin"
fi

# If a $HOME/man directory exists, add it to the MANPATH
if [ -d "$HOME/man" ]; then
	MANPATH="$MANPATH:$HOME/man"
fi

case "$OS" in 
OpenBSD)
	# make sure MANPATH isn't set
	unset MANPATH
	;;
*)
	export MANPATH
	;;
esac # uname -s

export PATH


#---------------------------------------------------------------
# Set Global Environment Variables
#---------------------------------------------------------------

if [ -r "/etc/bash/bashrc.local" ]; then
	. /etc/bash/bashrc.local
fi

# Set CVS variables
if [ -z "${CVS_HOSTPATH}" ]; then
	# If CVS_HOSTPATH was not set, then set a default value
	CVS_HOSTPATH=/cvs
	CVSROOT="${CVS_HOSTPATH}"
else
	CVSROOT=":ext:${LOGNAME}@${CVS_HOSTPATH}"
fi

# Make less the default pager
which ssh > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
	CVS_RSH=`which ssh`
else
	CVS_RSH=
fi

export CVS_RSH CVSROOT
unset CVS_HOSTPATH


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------

#
# cleanup: unsets any outstanding environment variables and
#     unsets itself
#
cleanup()
{
	unset PROMPT_STRING PROMPT_COLOR OS ID
	unset prompthost
	unset cleanup
}


# Skip the rest if this is not an interactive shell
if [ -z "${PS1}" -a "$-" != "*i*" ]; then
	cleanup; return
fi


#
# hostfromdomain:
#
hostfromdomain()
{
	if [ -z "$1" ]; then
		return 10
	fi
	dig -x `dig $1 +short` +short
}


#
# authme:
#
authme()
{
	local _usage="Usage: authme <ssh_host> [<pub_key>]"
	if [ -z "$1" ]; then
		echo $_usage
		return 10
	fi

	local _host="$1"
	local _key="${HOME}/.ssh/id_dsa.pub"

	if [ -n "$2" ]; then
		_key="$2"
	fi

	local _ssh_cmd="ssh $_host"
	echo "$_host" | grep -q ':'
	if [ "$?" -eq "0" ]; then
		_ssh_cmd="`echo $_host | awk -F':' '{print \"ssh -p \" $2 \" \" $1}'`"
	fi

	if [ ! -f "$_key" ]; then
		echo "SSH key: $_key does not exist."
		return 11
	fi

	$_ssh_cmd $_host '(cat - >> .ssh/authorized_keys)' < $_key
}


#
# maven_set_settings:
#
maven_set_settings()
{
	if [ ! -h "${HOME}/.m2/settings.xml" ]; then
		if [ ! -f "${HOME}/.m2/settings.xml.default" ]; then
			echo ">> Moving existing settings.xml to settings.xml.default..."
			mv ${HOME}/.m2/settings.xml ${HOME}/.m2/settings.xml.default
		fi
	fi

	local _ext="default"
	if [ -n "$1" ]; then
		_ext="$1"
	else
		echo ">> No settings explictly asked for, so using "default"."
	fi

	if [ ! -f "${HOME}/.m2/settings.xml.$_ext" ]; then
		echo "Maven settings $_ext (at: ${HOME}/.m2/settings.xml.$_ext) does not exist"
		return 1
	fi

	(cd ${HOME}/.m2 && ln -sf ./settings.xml.$_ext settings.xml)
	echo "===> Activating maven settings file: ${HOME}/.m2/settings.xml.$_ext"
}


#
# prompthost: 
#
prompthost()
{
	if [ -z "${PROMPT_COLOR}" ]; then
		PROMPT_COLOR="default"
	fi

	case "${PROMPT_COLOR}" in
		black)       local color="0;30m" ;;
		red)         local color="0;31m" ;;
		green)       local color="0;32m" ;;
		brown)       local color="0;33m" ;;
		blue)        local color="0;34m" ;;
		purple)      local color="0;35m" ;;
		cyan)        local color="0;36m" ;;
		lightgray)   local color="0;37m" ;;
		darkgray)    local color="1;30m" ;;
		lightred)    local color="1;31m" ;;
		lightgreen)  local color="1;32m" ;;
		yellow)      local color="1;33m" ;;
		lightblue)   local color="1;34m" ;;
		lightpurple) local color="1;35m" ;;
		lightcyan)   local color="1;36m" ;;
		white)       local color="1;37m" ;;
		default)     local color="m" ;;
		*)           local color="m" ;;
	esac

	echo -n "$color"
}


#
# psg: performs an egrep on the process list
#
case "$OS" in
Darwin|OpenBSD)
	psg()
	{
		ps wwwaux | egrep $@
	}
	;;

SunOS|Linux)
	psg()
	{
		ps -ef | egrep $@
	}
	;;
CYGWIN_*)
	psg()
	{
		ps -efW | egrep $@
	}
	;;
esac


#
# zoneinfo: displays a list of zones and their comments. For Solaris 10/11 only.
#
case "$OS" in
SunOS)
	zoneinfo()
	{
		echo "NAME		STATUS		COMMENT"
		for zoneline in `zoneadm list -pi | grep -v ':global:' | sort`; do
			zone="`echo $zoneline | nawk -F':' '{ print $2 }'`"
			zonestatus="`echo $zoneline | nawk -F':' '{ print $3 }'`"
			zonecfg -z $zone info attr name=comment | egrep 'value: ' | \
				nawk 'BEGIN { FS = ": " } \
				{ printf "%s\t%s\t%s\n", zone, zonestatus, $2 }' \
				zone=$zone zonestatus=$zonestatus
		done
	}
	;;
esac


#
# update_bashrc: pulls down new changes to the bashrc via mercurial.
#
which hg > /dev/null
if [ "$?" -eq 0 -a -d "/etc/bash/.hg" ]; then
	case "$OS" in
	SunOS)
		update_bashrc()
		{
			(cd /etc/bash && pfexec hg pull -u)
			if [ "$?" -eq 0 ]; then
				echo "bashrc has been updated to current."
			else
				echo "bashrc could not find an update or has failed."
			fi
		}
		;;
	CYGWIN_*)
		update_bashrc()
		{
			(cd /etc/bash && hg pull -u)
			if [ "$?" -eq 0 ]; then
				echo "bashrc has been updated to current."
			else
				echo "bashrc could not find an update or has failed."
			fi
		}
		;;
	*)
		update_bashrc()
		{
			(cd /etc/bash && sudo hg pull -u)
			if [ "$?" -eq 0 ]; then
				echo "bashrc has been updated to current."
			else
				echo "bashrc could not find an update or has failed."
			fi
		}
		;;
	esac
fi

#---------------------------------------------------------------
# Interactive shell (prompt,history) settings
#---------------------------------------------------------------

# Set the default editor
if [ "$OS" == "Linux" -a "$LINUX_FLAVOR" == "CentOS" ]; then
	EDITOR=/bin/vi
	VISUAL=/bin/vi
else
	EDITOR=/usr/bin/vi
	VISUAL=/usr/bin/vi
fi

# Set default visual tabstop to 2 characters, rather than 8
EXINIT="set tabstop=4"

export EDITOR VISUAL EXINIT

# Number of commands to remember in the command history
export HISTSIZE=10000

# The number of lines contained in the history file
export HISTFILESIZE=999999

# Prepend a timestamp on each history event
export HISTTIMEFORMAT="%Y-%m-%dT%H:%M:%S "

# Ignore commands starting with a space, duplicates,
# and a few others.
export HISTIGNORE="[ ]*:&:bg:fg:ls -l:ls -al:ls -la:ll:la"

# Sets a default prompt. The \[..\] strings are to bold the
# prompt text.
PROMPT_STRING="\u@\h:\w"
if [ "`$ID -ur`" -eq "0" ]; then
	# If the user is root, display a # in the shell
	case "$TERM" in
	*term | rxvt)
		# show the prompt in red
		PS1="\[\033[41;1m\]${PROMPT_STRING}#\[\033[0m\] "
		PS2="\[\033[41;1m\]#\[\033[0m\] "
		# if TERM supports it, add info in the titlebar
		PROMPT_COMMAND='echo -n -e \
			"\033]0;#${LOGNAME}@${HOSTNAME%%.*}:${PWD//$HOME/~}#\007"'
		;;

	*)
		PS1="${PROMPT_STRING}# "
		PS2="# "
		;;
	esac # TERM
else
	# Display a normal prompt for non-root users
	case "$TERM" in
	*term | rxvt)
		PS1="\[\033[`prompthost`\]${PROMPT_STRING}>\[\033[0m\] "
		PS2="\[\033[`prompthost`\]>\[\033[0m\] "
		# if TERM supports it, add info in the titlebar
		PROMPT_COMMAND='echo -n -e \
			"\033]0;${LOGNAME}@${HOSTNAME%%.*}:${PWD//$HOME/~}\007"'
		;;

	*)
		PS1="${PROMPT_STRING}> "
		PS2="> "
		;;
	esac # TERM
fi

export IGNOREEOF=10

shopt -s checkwinsize
shopt -s histappend

# Echo the version and date of the profile
echo "bashrc v${BASHRCVERSION} (`
	echo '$Date$' | \
	awk '{ print $2\" \"$3 }'
	`)"
echo


#---------------------------------------------------------------
# Set Aliases (Commonly Used Shortcuts)
#---------------------------------------------------------------

alias ll='ls -l'
alias la='ls -al'
alias lm='ll | less'

# If pine is installed, eliminated the .pine-debugX files
if [ -e "/usr/local/bin/pine" ]; then
	alias pine="pine -d 0"
fi

# If system is Darwin (Mac), add the super alias to properly
# become root with bash and environment settings
if [ "$OS" = "Darwin" ]; then
	alias super="sudo -s -H"
fi

# If mysql is installed via macports, then provide a startup and shutdown alias
if [ "$OS" = "Darwin" -a -f "/opt/local/share/mysql5/mysql/mysql.server" ]; then
	alias mysqld_start='sudo /opt/local/share/mysql5/mysql/mysql.server start'
	alias mysqld_stop='sudo /opt/local/share/mysql5/mysql/mysql.server stop'
fi

cleanup
