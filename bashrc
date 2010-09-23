#---------------------------------------------------------------
# Global bashrc File
#---------------------------------------------------------------

# Skip this config if we aren't in bash
[[ -n "${BASH_VERSION}" ]] || return


#---------------------------------------------------------------
# Define Default System Paths
#---------------------------------------------------------------

_append_path() {
  local path_var="$1"
  shift
  for p in $@ ; do
    [[ -d "$p" ]] && eval $path_var="\$${path_var}:${p}"
  done ; unset p
}

_push_path() {
  local path_var="$1"
  shift
  for p in $@ ; do
    [[ -d "$p" ]] && eval $path_var="${p}:\$${path_var}"
  done ; unset p
}


# Determines the machine _os to set PATH, MANPATH and _id
_os="$(uname -s)"
case "$_os" in
  Linux)		# Linux
  	_push_path /opt/*/current/bin

  	# if grails is installed manually, then export GRAILS_HOME preferentially
  	if [ -f "/opt/grails/current/bin/grails" -a -d "/opt/grails/current" ] ; then
  		export GRAILS_HOME=/opt/grails/current
  	fi

  	# if groovy is installed manually, then export GROOVY_HOME preferentially
  	if [ -f "/opt/groovy/current/bin/groovy" -a -d "/opt/groovy/current" ] ; then
  		export GROOVY_HOME=/opt/groovy/current
  	fi

  	_id=/usr/bin/id
  	super_cmd="/usr/bin/sudo -p \"[sudo] password for %u@$(hostname): \" --"
  	if [ -f "/etc/redhat-release" ] ; then
  		LINUX_FLAVOR="$(awk '{print $1}' /etc/redhat-release)"
  	fi
  	if [ -f "/etc/lsb-release" ] ; then
  		LINUX_FLAVOR="$(head -n 1 /etc/lsb-release | awk -F= '{print $2}')"
  	fi
  	;;

  Darwin)		# Mac OS X
  	_push_path PATH /opt/local/sbin /opt/local/bin /opt/*/current/bin \
  	  /usr/local/Cellar/python/2.?/bin /usr/local/Cellar/python/3.?/bin \
  	  /usr/local/sbin /usr/local/bin
  	_push_path MANPATH /opt/local/man /usr/local/share/man

  	# if we can determine the version of java as set in java prefs, then export
  	# JAVA_HOME to match this
  	[[ -s "/usr/libexec/java_home" ]] && export JAVA_HOME=$(/usr/libexec/java_home)

  	# if grails is installed manually, then export GRAILS_HOME preferentially
  	if [ -f "/opt/grails/current/bin/grails" -a -d "/opt/grails/current" ] ; then
  		export GRAILS_HOME=/opt/grails/current
  	# if grails is installed via macports, then export GRAILS_HOME
  	elif [ -f "/opt/local/bin/grails" -a -d "/opt/local/share/java/grails" ] ; then
  		export GRAILS_HOME=/opt/local/share/java/grails
  	fi

  	# if groovy is installed manually, then export GROOVY_HOME preferentially
  	if [ -f "/opt/groovy/current/bin/groovy" -a -d "/opt/groovy/current" ] ; then
  		export GROOVY_HOME=/opt/groovy/current
  	# if groovy is installed via macports, then export GROOVY_HOME
  	elif [ -f "/opt/local/bin/groovy" -a -d "/opt/local/share/java/groovy" ] ; then
  		export GROOVY_HOME=/opt/local/share/java/groovy
  	fi

  	_id=/usr/bin/id
  	super_cmd="/usr/bin/sudo -p \"[sudo] password for %u@$(hostname): \" --"
  	;;

  OpenBSD)	# OpenBSD
  	# Set a base PATH based on original /etc/skel/.profile and /root/.profile
  	# from 4.6 on 2010-01-01
  	PATH=/sbin
  	_append_path PATH /usr/sbin /bin /usr/bin /usr/X11R6/bin \
  	  /usr/local/sbin /usr/local/bin

  	_id=/usr/bin/id
  	super_cmd="/usr/bin/sudo -p \"[sudo] password for %u@$(hostname): \" --"
  	;;

  SunOS)		# Solaris
  	case "$(uname -r)" in
    	"5.11")	# OpenSolaris
    		PATH=/opt/*/current/bin
    		_append_path PATH /usr/gnu/bin /usr/bin /usr/X11/bin /usr/sbin /sbin

    		MANPATH=/usr/gnu/share/man
    		_append_path MANPATH /usr/share/man /usr/X11/share/man

    		_id=/usr/bin/id
    		super_cmd=/usr/bin/pfexec

    		# Files you make look like rw-r--r--
    		umask 022

    		# Make less the default pager
    		export PAGER="/usr/bin/less -ins"
    		;;

    	"5.10")	# Solaris 10
    	  PATH=/opt/local/sbin
    	  # admin path
    	  _append_path PATH /usr/gnu/sbin /usr/local/sbin \
    	    /usr/platform/$(uname -i)/sbin /sbin /usr/sbin
    	  # general path
    	  _append_path PATH /opt/local/bin /usr/gnu/bin /usr/local/bin \
    	    /bin /usr/bin /usr/ccs/bin /usr/openwin/bin /usr/dt/bin /opt/sun/bin \
    	    /opt/SUNWspro/bin /opt/SUNWvts/bin

        _append_path MANPATH /opt/local/share/man /usr/gnu/man /usr/local/man \
          /usr/man /usr/share/man /opt/SUNWspro/man /opt/SUNWvts/man

    		_id=/usr/xpg4/bin/id
    		super_cmd=/usr/bin/pfexec

    		if [ -d "/usr/local/lib/python2.6/site-packages" ] ; then
    			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.6/site-packages"
    		fi
    		if [ -d "/usr/local/lib/python2.5/site-packages" ] ; then
    			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.5/site-packages"
    		fi
    		if [ -d "/usr/local/lib/python2.4/site-packages" ] ; then
    			PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.4/site-packages"
    		fi
    		if [ -n "$PYTHONPATH" ] ; then
    			export PYTHONPATH
    		fi

    		# Files you make look like rw-r--r--
    		umask 022

    		# Make less the default pager
    		if command -v less >/dev/null ; then
    			export PAGER="$(command -v less)"
    		fi

    		unset ADMINPATH
    		;;
  	esac
  	;;

  CYGWIN_*)	# Windows running Cygwin
  	_id=/usr/bin/id
  	super_cmd=
  	;;
esac # uname -s


# If a $HOME/bin directory exists, add it to the PATH
_append_path PATH $HOME/bin

# If a $HOME/man directory exists, add it to the MANPATH
_append_path MANPATH $HOME/man

case "$_os" in
  OpenBSD)
  	# make sure MANPATH isn't set
  	unset MANPATH
  	;;

  *)
  	export MANPATH
  	;;
esac # uname -s

export PATH super_cmd

[[ -r "/etc/bash/bashrc.local" ]] &&  source /etc/bash/bashrc.local

unset _append_path _push_path


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------

##
# Unsets any outstanding environment variables and unsets itself.
#
cleanup() {
	unset PROMPT_COLOR _os _id
	unset cleanup
}

##
# Pulls down new changes to the bashrc via git.
#
update_bashrc()	{
  if ! command -v git >/dev/null; then
    printf "\n>>>> Command 'git' not found on the path, please install and try again.\n\n"
    return 10
  fi

  # save a copy of bashrc.local and clear out old hg cruft
  local stash=
  if [[ -d "/etc/bash/.hg" && -f "/etc/bash/bashrc.local" ]] ; then
    stash="/tmp/bashrc.local.$$"
    $super_cmd cp -p "/etc/bash/bashrc.local" "$stash"
    $super_cmd rm -rf /etc/bash
  fi

  if [[ -d "/etc/bash/.git" ]] ; then
    ( builtin cd "/etc/bash" && $super_cmd git pull origin master )
  else
    builtin cd "/etc" && \
      ( $super_cmd git clone --depth 1 git://github.com/fnichol/bashrc.git bash || \
      $super_cmd git clone http://github.com/fnichol/bashrc.git bash )
  fi
  local result="$?"

  # move bashrc.local back
  [[ -n "$stash" ]] && $super_cmd mv "$stash" "/etc/bash/bashrc.local"

	if [ "$result" -eq 0 ]; then
		${super_cmd} rm -f /etc/bash/tip.date
		$super_cmd bash -c "( builtin cd /etc/bash && \
		  git log -1 --pretty=\"format:%h %ci\" > /etc/bash/tip.date)"
		printf "\n===> bashrc is current ($(cat /etc/bash/tip.date)).\n"
		printf "===> Either logout and open a new shell, or type: source /etc/bash/bashrc\n\n"
	else
		printf "\n>>>> bashrc could not find an update or has failed.\n\n"
		return 11
	fi
}

# Skip the rest if this is not an interactive shell
if [ -z "${PS1}" -a "$-" != "*i*" ] ; then	cleanup ; return ; fi

##
# Prints terminal codes.
#
# Thanks to: http://github.com/wayneeseguin/rvm/blob/master/scripts/color
#
# @param [String] terminal code keyword (usually a color)
bput() {
  case "$1" in
    # regular colors
    black)    tput setaf 0 ;;
    red)      tput setaf 1 ;;
    green)    tput setaf 2 ;;
    yellow)   tput setaf 3 ;;
    blue)     tput setaf 4 ;;
    magenta)  tput setaf 5 ;;
    cyan)     tput setaf 6 ;;
    white)    tput setaf 7 ;;

    # emphasized (bolded) colors
    eblack)   tput bold ; tput setaf 0 ;;
    ered)     tput bold ; tput setaf 1 ;;
    egreen)   tput bold ; tput setaf 2 ;;
    eyellow)  tput bold ; tput setaf 3 ;;
    eblue)    tput bold ; tput setaf 4 ;;
    emagenta) tput bold ; tput setaf 5 ;;
    ecyan)    tput bold ; tput setaf 6 ;;
    ewhite)   tput bold ; tput setaf 7 ;;

    # underlined colors
    ublack)   set smul unset rmul ; tput setaf 0 ;;
    ured)     set smul unset rmul ; tput setaf 1 ;;
    ugreen)   set smul unset rmul ; tput setaf 2 ;;
    uyellow)  set smul unset rmul ; tput setaf 3 ;;
    ublue)    set smul unset rmul ; tput setaf 4 ;;
    umagenta) set smul unset rmul ; tput setaf 5 ;;
    ucyan)    set smul unset rmul ; tput setaf 6 ;;
    uwhite)   set smul unset rmul ; tput setaf 7 ;;

    # background colors
    bblack)   tput setab 0 ;;
    bred)     tput setab 1 ;;
    bgreen)   tput setab 2 ;;
    byellow)  tput setab 3 ;;
    bblue)    tput setab 4 ;;
    bmagenta) tput setab 5 ;;
    bcyan)    tput setab 6 ;;
    bwhite)   tput setab 7 ;;

    # Defaults
    default)  tput setaf 9 ;;
    bdefault) tput setab 9 ;;
    none)     tput sgr0    ;;
    *)        tput sgr0    # Reset
  esac
}

##
# Sets a shell prompt. Uses a set variable of `PROMPT_COLOR' to determine
# the main color of the prompt, if it exists. This is generally set in
# bashrc.local.
#
bash_prompt() {
  [[ -z "$PROMPT_COLOR" ]] && PROMPT_COLOR="default"
  
  if [ "$($_id -ur)" -eq "0" ] ; then  # am I root?
    local user_c="#" ; local tb=$user_c ; local color="${root_red}"
  else
    local user_c=">" ; local tb=""      ; local color="$PROMPT_COLOR"
  fi
  local prompt="\u@\h:\w"

  case "$TERM" in
    *term | rxvt)
      local titlebar="\[\033]0;${tb}${prompt}${tb}\007\]"
      PS1="${titlebar}\[$(bput $color)\]${prompt}${user_c} \[$(bput rst)\]"
      PS2="\[$(bput $color)\]${user_c} \[$(bput rst)\]"
      ;;

    *)
      PS1="${prompt}${user_c} "
      PS2="${user_c} "
      ;;
  esac
}

##
# Determines the primary hostname of another domain name. Often used to
# resolve a website url (like `www.example.com') to a server hostname
# (like `webserver1.domainhosting.com').
#
# @params [String] domainname to look up
if command -v dig >/dev/null ; then
	hostfromdomain() {
	  [[ -z "$1" ]] && printf "usage: hostfromdomain <domainname>\n" && return 10
		dig -x $(dig $1 +short) +short
	}
fi

##
# Places a given public ssh key on a remote host for key-based authentication.
# The host can optionally contain the username (like `jdoe@ssh.example.com')
# and a non-standard port number (like `ssh.example.com:666').
#
# @param [String] remote ssh host in for form of [<user>@]host[:<port>]
# @param [String] public key, using $HOME/.ssh/id_dsa.pub by default
authme() {
	[[ -z "$1" ]] && printf "Usage: authme <ssh_host> [<pub_key>]\n" && return 10

	local host="$1"
	shift
  if [[ -z "$1" ]] ; then
    local key="${HOME}/.ssh/id_dsa.pub"
  else
    local key="$1"
  fi
  shift

	[[ ! -f "$key" ]] && echo "SSH key: $key does not exist." && return 11

	if echo "$host" | grep -q ':' ; then
		local ssh_cmd="$(echo $host | awk -F':' '{print \"ssh -p \" $2 \" \" $1}')"
	else
  	local ssh_cmd="ssh $host"
	fi

	$ssh_cmd '(if [ ! -d "${HOME}/.ssh" ]; then \
		mkdir -m 0700 -p ${HOME}/.ssh; fi; \
		cat - >> .ssh/authorized_keys)' < $key
}

##
# Activates a maven settings profile. A profile lives under $HOME/.m2 and is
# of the form `settings-myprofile.xml'. Calling this function with the profile
# `myprofile' will symlink `settings-myprofile.xml' to `settings.xml' in
# maven home.
#
# @param [String] profile name to activate
maven_set_settings() {
	if [ ! -h "${HOME}/.m2/settings.xml" ] ; then
		if [ ! -f "${HOME}/.m2/settings-default.xml" ] ; then
			printf ">> Moving existing settings.xml to settings-default.xml...\n"
			mv ${HOME}/.m2/settings.xml ${HOME}/.m2/settings-default.xml
		fi
	fi

	if [ -z "$1" ] ; then
		printf '>> No settings explictly asked for, so using "default".\n'
  	local ext="default"
	else
		local ext="$1"
	fi
	shift

	if [ ! -f "${HOME}/.m2/settings-${ext}.xml" ] ; then
		printf "Maven settings $_ext (at: ${HOME}/.m2/settings-${ext}.xml) does not exist\n"
		return 10
	fi

	(cd ${HOME}/.m2 && ln -sf ./settings-${ext}.xml settings.xml)
	printf "===> Activating maven settings file: ${HOME}/.m2/settings-${ext}.xml\n"
}


#
# Performs an egrep on the process list. Use any arguments that egrep accetps.
#
# @param [Array] egrep arguments
case "$_os" in
  Darwin|OpenBSD) psg() { ps wwwaux | egrep $@  ; } ;;
  SunOS|Linux)    psg() { ps -ef | egrep $@     ; } ;;
  CYGWIN_*)       psg() { ps -efW | egrep $@    ; } ;;
esac

#
# zoneinfo: displays a list of zones and their comments. For Solaris 10/11 only.
#
case "$_os" in
SunOS)
	# only define the function if this is a global zone
	if zoneadm list -pi | grep :global: >/dev/null ; then
		zoneinfo() {
			printf "%-5s  %-10s  %-16s  %-10s  %s\n" \
				"ISC" "DOMAIN" "NAME" "STATUS" "COMMENT"
			for zoneline in $(zoneadm list -pi | grep -v ':global:' | sort) ; do
				local zone="$(echo $zoneline | nawk -F':' '{ print $2 }')"
				local status="$(echo $zoneline | nawk -F':' '{ print $3 }')"

				local isc_num="$(zonecfg -z $zone info zonepath | \
					nawk '{print $2}' | sed 's|^.*/\(isc[0-9][0-9]*\)/.*$|\1|')"
				if [ "$isc_num" == "" ]; then domain="N/A" ; fi

				local domain="$(zonecfg -z $zone info attr name=domain | \
					egrep 'value: ' |  nawk '{print $2}')"
				if [ "$domain" == "" ]; then domain="NOT SET" ; fi

				local comment="$(zonecfg -z $zone info attr name=comment | \
					egrep 'value: ' |  sed 's|^[^\"]*\"\([^\"]*\)\".*$|\1|')"
				if [ "$comment" == "" ]; then comment="NOT SET" ; fi

				printf "%-5s  %-10s  %-16s  %-10s  %s\n" \
					"$isc_num" "$domain" "$zone" "$status" "$comment"
			done | sort
		}
	fi
	;;
esac

#
# whatsmy_primary_ip: returns the primary IP address of the system
#
case "$_os" in
  Darwin)
  	whatsmy_primary_ip() {
  		local _if="$(netstat -nr | grep ^default | \
  			grep -v 'link#' | awk '{print $6}')"
  		local _ip="$(ifconfig $_if | \
  			grep '^[[:space:]]*inet ' | awk '{print $2}')"

  		if [ -z "$_ip" -o "$_ip" == "" ]; then
  			echo "Could not determine primary IP address"
  			return 10
  		else
  			echo $_ip
  		fi
  	}
  	;;

  OpenBSD)
  	whatsmy_primary_ip() {
  		local _if="$(netstat -nr | grep ^default | awk '{print $8}')"
  		local _ip="$(ifconfig $_if | \
  			grep '^[[:space:]]*inet ' | awk '{print $2}')"

  		if [ -z "$_ip" -o "$_ip" == "" ]; then
  			echo "Could not determine primary IP address"
  			return 10
  		else
  			echo $_ip
  		fi
  	}
  	;;

  Linux)
    whatsmy_primary_ip() {
    	local _if="$(netstat -nr | grep ^0\.0\.0\.0 | awk '{print $8}')"
    	local _ip="$(/sbin/ifconfig $_if | \
    		grep '^[[:space:]]*inet ' | awk '{print $2}' | \
    		awk -F':' '{print $2}')"

    	if [ -z "$_ip" -o "$_ip" == "" ]; then
    		echo "Could not determine primary IP address"
    		return 10
    	else
    		echo $_ip
    	fi
    }
    ;;

  SunOS)
    whatsmy_primary_ip() {
    	local _def_gateway="$(netstat -nr | grep ^default | \
    		awk '{print $2}')"
    	local _if="$(route get $_def_gateway | \
    		grep '^[ ]*interface:' | awk '{print $2}')"
    	local _ip="$(ifconfig $_if | \
    		grep '^	*inet ' | awk '{print $2}')"

    	if [ -z "$_ip" -o "$_ip" == "" ]; then
    		echo "Could not determine primary IP address"
    		return 10
    	else
    		echo $_ip
    	fi
    }
    ;;
esac # case $_os


#---------------------------------------------------------------
# Interactive shell (prompt,history) settings
#---------------------------------------------------------------

# Set the default editor
if [ -z "$SSH_CLIENT" ] && command -v mvim >/dev/null ; then
  export EDITOR="$(command -v mvim) -f"
elif [ -z "$SSH_CLIENT" ] && command -v gvim >/dev/null ; then
  export EDITOR="$(command -v gvim) -f"
elif [ -z "$SSH_CLIENT" ] && command -v mate >/dev/null ; then
  export EDITOR="$(command -v mate) -w"
else
  export EDITOR="$(command -v vi)"
fi
export VISUAL="$EDITOR"

# Set default visual tabstop to 2 characters, rather than 8
export EXINIT="set tabstop=2 bg=dark"

# Conditional support for Ruby Version Manager (RVM)
if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
	source "${HOME}/.rvm/scripts/rvm"
elif [[ -s "/usr/local/lib/rvm" ]]; then
	source "/usr/local/lib/rvm"
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

bash_prompt ; unset bash_prompt

export IGNOREEOF=10

shopt -s checkwinsize
shopt -s histappend

# Echo the version and date of the profile
if [[ -f "/etc/bash/tip.date" ]] ; then
	ver="$(cat /etc/bash/tip.date)"
else
	ver="$(cd '/etc/bash' && git log -1 --pretty=\"format:%h %ci\")"
fi
printf "bashrc ($ver)\n\n" ; unset ver


#---------------------------------------------------------------
# Set Aliases (Commonly Used Shortcuts)
#---------------------------------------------------------------

alias ll='ls -l'
alias la='ls -al'
alias lm='ll | less'

# Colorize maven output, courtesy of:
# http://blog.blindgaenger.net/colorize_maven_output.html
if command -v mvn >/dev/null ; then
	color_maven()	{
		local e=$(echo -e "\x1b")[
		local highlight="1;32m"
		local info="0;36m"
		local warn="1;33m"
		local error="1;31m"

		$(command -v mvn) $* | sed -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/${e}${highlight}Tests run: \1${e}0m, Failures: ${e}${error}\2${e}0m, Errors: ${e}${warn}\3${e}0m, Skipped: ${e}${info}\4${e}0m/g" \
			-e "s/\(\[WARN\].*\)/${e}${warn}\1${e}0m/g" \
			-e "s/\(\[INFO\].*\)/${e}${info}\1${e}0m/g" \
			-e "s/\(\[ERROR\].*\)/${e}${error}\1${e}0m/g"
	}
	alias mvn=color_maven
fi

# If pine is installed, eliminated the .pine-debugX files
[[ -s "/usr/local/bin/pine" ]] && alias pine="pine -d 0"

# OS-specific aliases
case "$_os" in
  Darwin)
  	# Add the super alias to properly become root with bash and
  	# environment settings
  	alias super="sudo -s -H"

  	# Default color scheme except directories are yellow
  	export LSCOLORS="Dxfxcxdxbxegedabagacad"

  	# Colorize ls by default
  	alias ls="ls -G"

  	# Colorize grep/egrep/fgrep by default
  	alias grep='grep --color=auto'
  	alias egrep='egrep --color=auto'
  	alias fgrep='fgrep --color=auto'

  	# If mysql is installed via macports, then provide a startup and shutdown alias
  	if [ -f "/opt/local/share/mysql5/mysql/mysql.server" ] ; then
  		alias mysqld_start='sudo /opt/local/share/mysql5/mysql/mysql.server start'
  		alias mysqld_stop='sudo /opt/local/share/mysql5/mysql/mysql.server stop'
  	fi

		# Lowercase uuids
		alias uuidlower="uuidgen | tr '[[:upper:]]' '[[:lower:]]'"

		# MacVim is found, use it for vim on the commandline
		if [[ -f "/Applications/MacVim.app/Contents/MacOS/Vim" ]] ; then
			alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"
		fi
  	;;

  SunOS)
  	# Colorize ls by default, courtesy of:
  	# http://blogs.sun.com/observatory/entry/ls_colors
  	if [ "$(command -v ls)" == "/usr/gnu/bin/ls" -a -x "/usr/bin/dircolors" ] ; then
  		eval "$(/usr/bin/dircolors -b)"
  		alias ls='ls --color=auto'
  	fi

  	# Colorize grep/egrep/fgrep by default
  	if [ "$(command -v grep)" == "/usr/gnu/bin/grep" ] ; then
  		alias grep='grep --color=auto'
  	fi
  	if [ "$(command -v egrep)" == "/usr/gnu/bin/egrep" ] ; then
  		alias egrep='egrep --color=auto'
  	fi
  	if [ "$(command -v fgrep)" == "/usr/gnu/bin/fgrep" ] ; then
  		alias fgrep='fgrep --color=auto'
  	fi
  	;;

  Linux)
  	# Colorize ls by default
  	if command -v dircolors >/dev/null ; then
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
if [[ -n "${LS_COLORS}" ]] ; then
	export LS_COLORS="$(echo $LS_COLORS | sed 's|di=01;34|di=01;33|')"
fi

[[ -r "/etc/bash/bashrc.local" ]] &&  source /etc/bash/bashrc.local

cleanup
