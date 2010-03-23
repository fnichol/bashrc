#---------------------------------------------------------------
# Global bashrc File
# $Id$
#---------------------------------------------------------------

# Ensure that we are in a bash shell, otherwise don't source
# this file
if [ ! -n "${BASH_VERSION}" ]; then
	return
fi 


#---------------------------------------------------------------
# Define Default System Paths
#---------------------------------------------------------------

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

_prepend_path()
{
	if [ -d "$1" ]; then
		PATH="$1:$PATH"
	fi
}

_append_manpath()
{
	if [ -d "$1" ]; then
		MANPATH="$MANPATH:$1"
	fi
}

_prepend_manpath()
{
	if [ -d "$1" ]; then
		MANPATH="$1:$MANPATH"
	fi
}

# Determines the machine OS to set PATH, MANPATH and ID
OS="`uname -s`"
case "$OS" in
SunOS)		# Solaris
	case "`uname -r`" in
	"5.11")	# OpenSolaris
		PATH=/usr/gnu/bin
		_append_path /usr/bin
		_append_path /usr/X11/bin
		_append_path /usr/sbin
		_append_path /sbin

		MANPATH=/usr/gnu/share/man
		_append_manpath /usr/share/man
		_append_manpath /usr/X11/share/man

		ID=/usr/bin/id
		SUPER_CMD=/usr/bin/pfexec

		# Files you make look like rw-r--r--
		umask 022

		# Make less the default pager
		PAGER="/usr/bin/less -ins"
		export PAGER
		;;

	"5.10")	# Solaris 10
		ADMINPATH=/opt/local/sbin
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
		SUPER_CMD=/usr/bin/pfexec

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

		unset ADMINPATH
		;;
	esac
	;;

Darwin)		# Mac OS X
	# Set the PATH based on original /etc/profile from 
	# 10.3.6 on 2004/11/22.
	PATH="/bin:/sbin:/usr/local/bin:/usr/bin:/usr/sbin"
	_prepend_path /opt/local/sbin
	_prepend_path /opt/local/bin
	_prepend_path /opt/maven/current/bin
	_prepend_path /opt/ant/current/bin
	_prepend_path /opt/grails/current/bin

	MANPATH="$MANPATH"
	_prepend_manpath /opt/local/man

	# if we can determine the version of java as set in java prefs, then export
	# JAVA_HOME to match this
	if [ -f "/usr/libexec/java_home" ]; then
		JAVA_HOME=`/usr/libexec/java_home`
		export JAVA_HOME
	fi

	# if grails is installed manually, then export GRAILS_HOME preferentially
	if [ -f "/opt/grails/current/bin/grails" -a -d "/opt/grails/current" ]
	then
		GRAILS_HOME=/opt/grails/current
		export GRAILS_HOME
	# if grails is installed via macports, then export GRAILS_HOME
	elif [ -f "/opt/local/bin/grails" -a -d "/opt/local/share/java/grails" ]
	then
		GRAILS_HOME=/opt/local/share/java/grails
		export GRAILS_HOME
	fi

	ID=/usr/bin/id
	SUPER_CMD=/usr/bin/sudo
	;;

OpenBSD)	# OpenBSD
	# Set a base PATH based on original /etc/skel/.profile and /root/.profile
	# from 4.6 on 2010-01-01
	PATH=/sbin
	_append_path /usr/sbin
	_append_path /bin
	_append_path /usr/bin
	_append_path /usr/X11R6/bin
	_append_path /usr/local/sbin
	_append_path /usr/local/bin

	ID=/usr/bin/id
	SUPER_CMD=/usr/bin/sudo
	;;

Linux)		# Linux
	ID=/usr/bin/id
	SUPER_CMD=/usr/bin/sudo
	if [ -f "/etc/redhat-release" ]; then
		LINUX_FLAVOR="`awk '{print $1}' /etc/redhat-release`"
	fi
	if [ -f "/etc/lsb-release" ]; then
		LINUX_FLAVOR="`head -n 1 /etc/lsb-release | awk -F= '{print $2}'`"
	fi
	;;

CYGWIN_*)	# Windows running Cygwin
	ID=/usr/bin/id
	SUPER_CMD=
	;;
esac # uname -s


# If a $HOME/bin directory exists, add it to the PATH
_append_path $HOME/bin

# If a $HOME/man directory exists, add it to the MANPATH
_append_manpath $HOME/man

case "$OS" in 
OpenBSD)
	# make sure MANPATH isn't set
	unset MANPATH
	;;
*)
	export MANPATH
	;;
esac # uname -s

export PATH SUPER_CMD

unset _append_adminpath _append_path _prepend_path _append_manpath _prepend_manpath

#---------------------------------------------------------------
# Set Global Environment Variables
#---------------------------------------------------------------

if [ -r "/etc/bash/bashrc.local" ]; then
	. /etc/bash/bashrc.local
fi


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
	unset get_color_code
	unset cleanup
}


# Skip the rest if this is not an interactive shell
if [ -z "${PS1}" -a "$-" != "*i*" ]; then
	cleanup; return
fi


#
# hostfromdomain:
#
if which dig &> /dev/null; then
	hostfromdomain()
	{
		if [ -z "$1" ]; then
			return 10
		fi
		dig -x `dig $1 +short` +short
	}
fi # which dig


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

	$_ssh_cmd '(if [ ! -d "${HOME}/.ssh" ]; then \
		mkdir -m 0700 -p ${HOME}/.ssh; fi; \
		cat - >> .ssh/authorized_keys)' < $_key
}


#
# maven_set_settings:
#
maven_set_settings()
{
	if [ ! -h "${HOME}/.m2/settings.xml" ]; then
		if [ ! -f "${HOME}/.m2/settings-default.xml" ]; then
			echo ">> Moving existing settings.xml to settings-default.xml..."
			mv ${HOME}/.m2/settings.xml ${HOME}/.m2/settings-default.xml
		fi
	fi

	local _ext="default"
	if [ -n "$1" ]; then
		_ext="$1"
	else
		echo '>> No settings explictly asked for, so using "default".'
	fi

	if [ ! -f "${HOME}/.m2/settings-${_ext}.xml" ]; then
		echo "Maven settings $_ext (at: ${HOME}/.m2/settings-${_ext}.xml) does not exist"
		return 1
	fi

	(cd ${HOME}/.m2 && ln -sf ./settings-${_ext}.xml settings.xml)
	echo "===> Activating maven settings file: ${HOME}/.m2/settings-${_ext}.xml"
}


#
# get_color_code: 
#
get_color_code()
{
	local choice
	if [ -z "${1}" ]; then
		choice="default"
	else
		choice="$1"
	fi

	case "$choice" in
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
# prompthost:
#
prompthost()
{
	if [ -z "${PROMPT_COLOR}" ]; then
		PROMPT_COLOR="default"
	fi

	get_color_code $PROMPT_COLOR
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
	# only define the function if this is a global zone
	if zoneadm list -pi | grep :global: &> /dev/null; then
		zoneinfo()
		{
			printf "%-5s  %-10s  %-16s  %-10s  %s\n" \
				"ISC" "DOMAIN" "NAME" "STATUS" "COMMENT"
			for zoneline in `zoneadm list -pi | grep -v ':global:' | sort`; do
				local zone="`echo $zoneline | nawk -F':' '{ print $2 }'`"
				local status="`echo $zoneline | nawk -F':' '{ print $3 }'`"

				local isc_num="`zonecfg -z $zone info zonepath | \
					nawk '{print $2}' | sed 's|^.*/\(isc[0-9][0-9]*\)/.*$|\1|'`"
				if [ "$isc_num" == "" ]; then domain="N/A"; fi

				local domain="`zonecfg -z $zone info attr name=domain | \
					egrep 'value: ' |  nawk '{print $2}'`"
				if [ "$domain" == "" ]; then domain="NOT SET"; fi

				local comment="`zonecfg -z $zone info attr name=comment | \
					egrep 'value: ' |  sed 's|^[^\"]*\"\([^\"]*\)\".*$|\1|'`"
				if [ "$comment" == "" ]; then comment="NOT SET"; fi

				printf "%-5s  %-10s  %-16s  %-10s  %s\n" \
					"$isc_num" "$domain" "$zone" "$status" "$comment"
			done | sort
		}
	fi
	;;
esac


#
# update_bashrc: pulls down new changes to the bashrc via mercurial.
#
which hg &> /dev/null
if [ "$?" -eq 0 -a -d "/etc/bash/.hg" ]; then
	update_bashrc()
	{
		(cd /etc/bash && ${SUPER_CMD} hg pull -u)
		if [ "$?" -eq 0 ]; then
			echo "===> bashrc has been updated to current."
			${SUPER_CMD} rm -f /etc/bash/tip.date
			${SUPER_CMD} bash -c "(cd /etc/bash; hg tip \
				--template '{date|isodate}\n' > \
				/etc/bash/tip.date)"
		else
			echo ">>>> bashrc could not find an update or has failed."
		fi
	}
fi


#
# whatsmy_primary_ip: returns the primary IP address of the system
#
case "$OS" in
Darwin)
	whatsmy_primary_ip()
	{
		local _if="`netstat -nr | grep ^default | \
			grep -v 'link#' | awk '{print $6}'`"
		local _ip="`ifconfig $_if | \
			grep '^[[:space:]]*inet ' | awk '{print $2}'`"

		if [ -z "$_ip" -o "$_ip" == "" ]; then
			echo "Could not determine primary IP address"
			return 10
		else
			echo $_ip
		fi
	}
	;;
OpenBSD)
	whatsmy_primary_ip()
	{
		local _if="`netstat -nr | grep ^default | awk '{print $8}'`"
		local _ip="`ifconfig $_if | \
			grep '^[[:space:]]*inet ' | awk '{print $2}'`"

		if [ -z "$_ip" -o "$_ip" == "" ]; then
			echo "Could not determine primary IP address"
			return 10
		else
			echo $_ip
		fi
	}
	;;
Linux)
	whatsmy_primary_ip()
	{
		local _if="`netstat -nr | grep ^0\.0\.0\.0 | awk '{print $8}'`"
		local _ip="`/sbin/ifconfig $_if | \
			grep '^[[:space:]]*inet ' | awk '{print $2}' | \
			awk -F':' '{print $2}'`"

		if [ -z "$_ip" -o "$_ip" == "" ]; then
			echo "Could not determine primary IP address"
			return 10
		else
			echo $_ip
		fi
	}
	;;
SunOS)
		whatsmy_primary_ip()
		{
			local _def_gateway="`netstat -nr | grep ^default | \
				awk '{print $2}'`"
			local _if="`route get $_def_gateway | \
				grep '^[ ]*interface:' | awk '{print $2}'`"
			local _ip="`ifconfig $_if | \
				grep '^	*inet ' | awk '{print $2}'`"

			if [ -z "$_ip" -o "$_ip" == "" ]; then
				echo "Could not determine primary IP address"
				return 10
			else
				echo $_ip
			fi
		}
		;;
esac # case $OS


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

# Set default visual tabstop to 4 characters, rather than 8
EXINIT="set tabstop=4 bg=dark"

export EDITOR VISUAL EXINIT

# Conditional support for Ruby Version Manager (RVM)
if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
	source "${HOME}/.rvm/scripts/rvm"
fi

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
if [ -f "/etc/bash/tip.date" ]; then
	BASHRCVERSION="`cat /etc/bash/tip.date`"
else
	BASHRCVERSION="`(cd /etc/bash && hg tip \
		--template '{date|isodate}\n' 2> /dev/null)`"
fi
echo "bashrc ($BASHRCVERSION)"
echo
unset BASHRCVERSION


#---------------------------------------------------------------
# Set Aliases (Commonly Used Shortcuts)
#---------------------------------------------------------------

alias ll='ls -l'
alias la='ls -al'
alias lm='ll | less'

# Colorize maven output, courtesy of:
# http://blog.blindgaenger.net/colorize_maven_output.html
if which mvn &> /dev/null; then
	color_maven()
	{
		local e=$(echo -e "\x1b")[
		local highlight="1;32m"
		local info="0;36m"
		local warn="1;33m"
		local error="1;31m"

		`which mvn` $* | sed -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/${e}${highlight}Tests run: \1${e}0m, Failures: ${e}${error}\2${e}0m, Errors: ${e}${warn}\3${e}0m, Skipped: ${e}${info}\4${e}0m/g" \
			-e "s/\(\[WARN\].*\)/${e}${warn}\1${e}0m/g" \
			-e "s/\(\[INFO\].*\)/${e}${info}\1${e}0m/g" \
			-e "s/\(\[ERROR\].*\)/${e}${error}\1${e}0m/g"
	}
	alias mvn=color_maven
fi

# If pine is installed, eliminated the .pine-debugX files
if [ -e "/usr/local/bin/pine" ]; then
	alias pine="pine -d 0"
fi

# OS-specific aliases
case "$OS" in
Darwin)
	# Add the super alias to properly become root with bash and
	# environment settings
	alias super="sudo -s -H"

	# Default color scheme except directories are yellow
	LSCOLORS="Dxfxcxdxbxegedabagacad"
	export LSCOLORS

	# Colorize ls by default
	alias ls="ls -G"

	# Colorize grep/egrep/fgrep by default
	alias grep='grep --color=auto'
	alias egrep='egrep --color=auto'
	alias fgrep='fgrep --color=auto'

	# If mysql is installed via macports, then provide a startup and shutdown alias
	if [ -f "/opt/local/share/mysql5/mysql/mysql.server" ]; then
		alias mysqld_start='sudo /opt/local/share/mysql5/mysql/mysql.server start'
		alias mysqld_stop='sudo /opt/local/share/mysql5/mysql/mysql.server stop'
	fi
	;;

SunOS)
	# Colorize ls by default, courtesy of:
	# http://blogs.sun.com/observatory/entry/ls_colors
	if [ "`which ls`" == "/usr/gnu/bin/ls" -a -x "/usr/bin/dircolors" ]; then
		eval "`/usr/bin/dircolors -b`"
		alias ls='ls --color=auto'
	fi

	# Colorize grep/egrep/fgrep by default
	if [ "`which grep`" == "/usr/gnu/bin/grep" ]; then
		alias grep='grep --color=auto'
	fi
	if [ "`which egrep`" == "/usr/gnu/bin/egrep" ]; then
		alias egrep='egrep --color=auto'
	fi
	if [ "`which fgrep`" == "/usr/gnu/bin/fgrep" ]; then
		alias fgrep='fgrep --color=auto'
	fi
	;;

Linux)
	# Colorize ls by default
	if which dircolors &> /dev/null; then
		test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || \
			eval "$(dircolors -b)"
	fi
	alias ls='ls --color=auto'

	# Colorize grep/egrep/fgrep by default
	alias grep='grep --color=auto'
	alias egrep='egrep --color=auto'
	alias fgrep='fgrep --color=auto'
	;;
esac

# If colors are declared for ls, etc. change blue directories into yellow
if [ -n "${LS_COLORS}" ]; then
	LS_COLORS="`echo $LS_COLORS | sed 's|di=01;34|di=01;33|'`"
	export LS_COLORS
fi

cleanup
