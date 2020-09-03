#---------------------------------------------------------------
# Global bashrc File
#---------------------------------------------------------------

# Skip this config if we aren't in bash
[[ -n "${BASH_VERSION}" ]] || return

# Skip this config if has already loaded
if declare -f __bashrc_reload >/dev/null && [[ ${bashrc_reload_flag:-0} -eq 0 ]]
then
  return
fi

[[ -n "${bashrc_prefix}" ]] && export bashrc_prefix


#---------------------------------------------------------------
# Define Default System Paths
#---------------------------------------------------------------

##
# Removes all instances of paths in a search path.
#
# @param [String] path variable to manipulate (ex: PATH, PYTHONPATH, etc)
# @param [List] space-seperated list of system paths to remove
__remove_from_path() {
  local path_var="$1"
  shift
  local new_path=""

  case "$_os" in
    SunOS)
      local tr_cmd=/usr/gnu/bin/tr
      local grep_cmd=/usr/gnu/bin/grep
      local sed_cmd=/usr/gnu/bin/sed
    ;;
    OpenBSD)
      local tr_cmd=/usr/bin/tr
      local grep_cmd=/usr/bin/grep
      local sed_cmd=/usr/bin/sed
    ;;
    *)
      local tr_cmd=tr
      local grep_cmd=grep
      local sed_cmd=sed
    ;;
  esac

  # remove paths from path_var, working in new_path
  for rp in $@ ; do
    new_path="$(eval "echo \"\$$path_var\"" | $tr_cmd ':' '\n' | \
      $grep_cmd -v "^${rp}$" | $tr_cmd '\n' ':' | $sed_cmd -e 's/:$//')"
  done ; unset rp

  # reassign path_var from new_path
  eval "$path_var='$new_path'"
}

##
# Sets a colon-seperated search path variable, overwriting any previous values.
#
# @param [String] path variable to manipulate (ex: PATH, PYTHONPATH, etc)
# @param [List] space-seperated list of system paths to append, in order
__set_path() {
  local path_var="$1"
  shift

  # set var and overwrite any previous values
  [[ -d "$1" ]] && eval $path_var="$1"
  shift

  for p in $@ ; do
    __remove_from_path "$path_var" "$p"
    [[ -d "$p" ]] && eval $path_var="\$${path_var}:${p}"
  done ; unset p
}

##
# Appends paths to the end of a search path variable list.
#
# @param [String] path variable to manipulate (ex: PATH, PYTHONPATH, etc)
# @param [List] space-seperated list of system paths to append, in order
__append_path() {
  local path_var="$1"
  shift

  # create var if not exists
  if eval "test -z \"\$$path_var\"" ; then
    [[ -d "$1" ]] && eval $path_var="$1"
    shift
  fi

  for p in $@ ; do
    __remove_from_path "$path_var" "$p"
    [[ -d "$p" ]] && eval $path_var="\$${path_var}:${p}"
  done ; unset p
}

##
# Pushes paths to the front of a search path variable list.
#
# @param [String] path variable to manipulate (ex: PATH, PYTHONPATH, etc)
# @param [List] space-seperated list of system paths to push, in reverse order
__push_path() {
  local path_var="$1"
  shift

  # create var if not exists
  if eval "test -z \"\$$path_var\"" ; then
    [[ -d "$1" ]] && eval $path_var="$1"
    shift
  fi

  for p in $@ ; do
    __remove_from_path "$path_var" "$p"
    [[ -d "$p" ]] && eval $path_var="${p}:\$${path_var}"
  done ; unset p
}

# Determines the machine _os to set PATH, MANPATH and _id
_os="$(uname -s)"
case "$_os" in
  Linux)    # Linux
    __push_path PATH /opt/*/current/bin

    _id=/usr/bin/id
    if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
      super_cmd() {
        "$@"
      }
    else
      super_cmd() {
        /usr/bin/sudo -p "[sudo] password for %u@$(hostname): " "$@"
      }
    fi
    if [ -f "/etc/redhat-release" ] ; then
      LINUX_FLAVOR="$(awk '{print $1}' /etc/redhat-release)"
    fi
    if [ -f "/etc/lsb-release" ] ; then
      LINUX_FLAVOR="$(head -n 1 /etc/lsb-release | awk -F= '{print $2}')"
    fi
  ;;
  Darwin)   # Mac OS X
    __push_path PATH /opt/local/sbin /opt/local/bin /opt/*/current/bin \
      /usr/local/share/python "$HOME"/Library/Python/*/bin \
      /usr/local/sbin /usr/local/bin
    __push_path MANPATH /opt/local/man /usr/local/share/man

    # if we can determine the version of java as set in java prefs, then export
    # JAVA_HOME to match this
    [[ -s "/usr/libexec/java_home" ]] && export JAVA_HOME=$(/usr/libexec/java_home)

    _id=/usr/bin/id
    if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
      super_cmd() {
        "$@"
      }
    else
      super_cmd() {
        /usr/bin/sudo -p "[sudo] password for %u@$(hostname): " "$@"
      }
    fi
  ;;
  OpenBSD)  # OpenBSD
    # Set a base PATH based on original /etc/skel/.profile and /root/.profile
    # from 4.6 on 2010-01-01
    __set_path PATH /sbin /usr/sbin /bin /usr/bin /usr/X11R6/bin \
      /usr/local/sbin /usr/local/bin

    # OpenBSD now uses `doas` as the default in favor of sudo
    _id=/usr/bin/id
    if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
      super_cmd() {
        "$@"
      }
    else
      super_cmd() {
        /usr/bin/doas "$@"
      }
    fi
  ;;
  FreeBSD)  # FreeBSD
    _id=/usr/bin/id
    if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
      super_cmd() {
        "$@"
      }
    else
      super_cmd() {
        /usr/local/bin/sudo -p "[sudo] password for %u@$(hostname): " "$@"
      }
    fi
  ;;
  SunOS)    # Solaris
    case "$(uname -r)" in
      "5.11") # OpenSolaris
        __set_path PATH /opt/*/current/bin /opt/local/sbin /opt/local/bin \
          /usr/local/sbin /usr/local/bin /usr/gnu/bin \
          /usr/sbin /sbin /usr/bin /usr/X11/bin

        __set_path MANPATH /usr/gnu/share/man /usr/share/man /usr/X11/share/man

        _id=/usr/bin/id
        if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
          super_cmd() {
            "$@"
          }
        else
          super_cmd() {
            /usr/bin/pfexec "$@"
          }
        fi

        # Files you make look like rw-r--r--
        umask 022

        # Make less the default pager
        export PAGER="/usr/bin/less -ins"
      ;;
      "5.10") # Solaris 10
        # admin path
        __set_path PATH /opt/local/sbin /usr/gnu/sbin /usr/local/sbin \
          /usr/platform/$(uname -i)/sbin /sbin /usr/sbin
        # general path
        __append_path PATH /opt/local/bin /usr/gnu/bin /usr/local/bin \
          /bin /usr/bin /usr/ccs/bin /usr/openwin/bin /usr/dt/bin \
          /opt/sun/bin /opt/SUNWspro/bin /opt/SUNWvts/bin

        __append_path MANPATH /opt/local/share/man /usr/gnu/man \
          /usr/local/man /usr/man /usr/share/man /opt/SUNWspro/man \
          /opt/SUNWvts/man

        _id=/usr/xpg4/bin/id
        if [[ -n "${bashrc_local_install}" ]] || [[ $($_id -u) -eq 0 ]] ; then
          super_cmd() {
            "$@"
          }
        else
          super_cmd() {
            /usr/bin/pfexec "$@"
          }
        fi

        # build python search path, favoring newer pythons over older ones
        for ver in 2.7 2.6 2.5 2.4 ; do
          __append_path PYTHONPATH /usr/local/lib/python${ver}/site-packages
        done ; unset ver
        [[ -n "$PYTHONPATH" ]] && export PYTHONPATH

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
  CYGWIN_*) # Windows running Cygwin
    _id=/usr/bin/id
    super_cmd() {
      "$@"
    }
  ;;
esac # uname -s


# If a $HOME/bin directory exists, add it to the PATH in front
__push_path PATH $HOME/bin

# If a $HOME/.local/bin directory exists, add it to the PATH in front
__push_path PATH $HOME/.local/bin

# If a $HOME/.cargo/bin directory exists, add it to the PATH in front
__push_path PATH $HOME/.cargo/bin

# If a /usr/local/go/bin directory exists, add it to the PATH in front
__push_path PATH /usr/local/go/bin

# If a $HOME/man directory exists, add it to the MANPATH in front
__push_path MANPATH $HOME/man

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

if [[ -r "${bashrc_prefix:-/etc/bash}/bashrc.local" ]] ; then
  source "${bashrc_prefix:-/etc/bash}/bashrc.local"
fi

if [[ -z "$_debug_bashrc" ]] ; then
  unset __set_path __append_path __push_path __remove_from_path
fi


#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------

##
# Unsets any outstanding environment variables and unsets itself.
#
cleanup() {
  unset PROMPT_COLOR REMOTE_PROMPT_COLOR _os _id bashrc_reload_flag
  unset cleanup
}

##
# Takes json on stdin and prints the value of a given path on stdout.
#
# @param [String] json path in the form of ["one"]["two"]
json_val() {
  [[ -z "$1" ]] && printf "Usage: json_val <path>\n" && return 10

  python -c 'import sys; import json; \
    j = json.loads(sys.stdin.read()); \
    print j'$1';'
}

##
# Checks if there any upstream updates.
#
# @param -q  suppress output
# @return 0 if up to date, 1 if there are updates, and 5 if there are errors
__bashrc_check() {
  if [ "$1" == "-q" ] ; then local suppress=1 && shift ; fi

  local prefix="${bashrc_prefix:-/etc/bash}"

  if [ ! -f "${prefix}/tip.date" ] ; then
    printf ">>> File ${prefix}/tip.date does not exist so cannot check.\n"
    return 5
  fi

  local tip_date=$(cat ${prefix}/tip.date)
  local flavor=${tip_date%% *}

  case "$flavor" in
    TARBALL)
      if command -v curl >/dev/null && command -v python >/dev/null ; then
        local last_commit_date="$(curl -sSL \
          http://github.com/api/v2/json/commits/show/fnichol/bashrc/HEAD | \
          json_val '["commit"]["committed_date"]')"
        if [ "${tip_date#* }" == "$last_commit_date" ] ; then
          [[ -z "$suppress" ]] && printf -- "-----> bashrc is up to date.\n"
          return 0
        else
          [[ -z "$suppress" ]] && \
            printf -- "-----> bashrc has updates to download." && \
            printf " Use 'bashrc update' to get current.\n"
          return 1
        fi
      else
        [[ -z "$suppress" ]] && \
          printf ">>>> Can't find curl and/or python commands.\n"
        return 5
      fi
    ;;
    *)
      if command -v git >/dev/null ; then
        (cd $prefix && super_cmd git fetch --quiet 2>&1 >/dev/null)
        (cd $prefix && super_cmd git --no-pager diff --quiet --exit-code \
          --no-color master..origin/master >/dev/null)
        if [[ "$?" -eq 0 ]] ; then
          [[ -z "$suppress" ]] && printf -- "-----> bashrc is up to date.\n"
          return 0
        else
          [[ -z "$suppress" ]] && \
            printf -- "-----> bashrc has updates to download." && \
            printf " Use 'bashrc update' to get current.\n"
          return 1
        fi
      else
        [[ -z "$suppress" ]] && printf ">>>> Can't find git command.\n"
        return 5
      fi
    ;;
  esac
}

##
# Initializes bashrc profile
__bashrc_init() {
  local prefix="${bashrc_prefix:-/etc/bash}"

  local egrep_cmd=
  case "$(uname -s)" in
    SunOS)  egrep_cmd=/usr/gnu/bin/egrep  ;;
    *)      egrep_cmd=egrep               ;;
  esac

  if [[ -f "${prefix}/bashrc.local" ]] ; then
    printf "A pre-existing ${prefix}/bashrc.local file was found, using it\n"
  else
    printf -- "-----> Creating ${prefix}/bashrc.local ...\n"
    super_cmd cp "${prefix}/bashrc.local.site" "${prefix}/bashrc.local"

    local color=
    case "$(uname -s)" in
      Darwin)   color="green"   ; local remote_color="yellow" ;;
      Linux)    color="cyan"    ;;
      OpenBSD)  color="red"     ;;
      FreeBSD)  color="magenta" ;;
      CYGWIN*)  color="black"   ;;
      SunOS)
        if /usr/sbin/zoneadm list -pi | $egrep_cmd :global: >/dev/null ; then
          color="magenta" # root zone
        else
          color="cyan"    # non-global zone
        fi
        ;;
    esac

    printf "Setting prompt color to be \"$color\" ...\n"
    super_cmd sed -i"" -e "s|^#\{0,1\}PROMPT_COLOR=.*$|PROMPT_COLOR=$color|g" \
      "${prefix}/bashrc.local"
    unset color

    if [[ -n "$remote_color" ]] ; then
      printf "Setting remote prompt color to be \"$remote_color\" ...\n"
      super_cmd sed -i"" -e \
        "s|^#\{0,1\}REMOTE_PROMPT_COLOR=.*$|REMOTE_PROMPT_COLOR=$remote_color|g" \
        "${prefix}/bashrc.local"
      unset remote_color
    fi
  fi

  if [[ -n "$bashrc_local_install" ]] ; then
    local p="${HOME}/.bash_profile"

    if [[ -r "$p" ]] && $egrep_cmd -q '${HOME}/.bash/bashrc' $p 2>&1 >/dev/null ; then
      printf ">> Mention of \${HOME}/.bash/bashrc found in \"$p\"\n"
      printf ">> You can add the following lines to get sourced:\n"
      printf ">>   if [[ -s \"\${HOME}/.bash/bashrc\" ]] ; then\n"
      printf ">>     bashrc_local_install=1\n"
      printf ">>     bashrc_prefix=\${HOME}/.bash\n"
      printf ">>     export bashrc_local_install bashrc_prefix\n"
      printf ">>     source \"\${bashrc_prefix}/bashrc\"\n"
      printf ">>   fi\n"
    else
      printf -- "-----> Adding source hook into \"$p\" ...\n"
      cat >> $p <<END_OF_PROFILE

if [[ -s "\${HOME}/.bash/bashrc" ]] ; then
  bashrc_local_install=1
  bashrc_prefix="\${HOME}/.bash"
  export bashrc_local_install bashrc_prefix
  source "\${bashrc_prefix}/bashrc"
fi
END_OF_PROFILE
    fi
  else
    local p=
    case "$(uname -s)" in
      Darwin)
        p="/etc/bashrc"
        ;;
      Linux)
        if [[ -f "/etc/SuSE-release" ]] ; then
          p="/etc/bash.bashrc.local"
        else
          p="/etc/profile"
        fi
        ;;
      FreeBSD|SunOS|OpenBSD|CYGWIN*)
        p="/etc/profile"
        ;;
      *)
        printf ">>>> Don't know how to add source hook in this operating system.\n"
        return 4
        ;;
    esac

    if $egrep_cmd -q '/etc/bash/bashrc' $p 2>&1 >/dev/null ; then
      printf ">> Mention of /etc/bash/bashrc found in \"$p\"\n"
      printf ">> You can add the following line to get sourced:\n"
      printf ">>   [[ -s \"/etc/bash/bashrc\" ]] && . \"/etc/bash/bashrc\""
    else
      printf -- "-----> Adding source hook into \"$p\" ...\n"
      cat <<END_OF_PROFILE | super_cmd tee -a $p >/dev/null

[[ -s "/etc/bash/bashrc" ]] && . "/etc/bash/bashrc"
END_OF_PROFILE
    fi
  fi
  unset p

  printf "\n\n"
  printf "    #---------------------------------------------------------------\n"
  printf "    # Installation of bashrc complete. To activate either exit\n"
  printf "    # this shell or type: 'source ${prefix}/bashrc'.\n"
  printf "    #\n"
  printf "    # To check for updates to bashrc, run: 'bashrc check'.\n"
  printf "    #\n"
  printf "    # To keep bashrc up to date, periodically run: 'bashrc update'.\n"
  printf "    #---------------------------------------------------------------\n\n"
}

##
# Pulls down new changes to the bashrc via git.
__bashrc_update() {
  local prefix="${bashrc_prefix:-/etc/bash}"
  local repo="github.com/fnichol/bashrc.git"

  # clear out old tarball install or legacy hg cruft
  local stash=
  if [ ! -d "$prefix/.git" ] ; then
    # save a copy of bashrc.local
    if [[ -f "$prefix/bashrc.local" ]] ; then
      stash="/tmp/bashrc.local.$$"
      super_cmd cp -p "$prefix/bashrc.local" "$stash"
    fi
    super_cmd rm -rf "$prefix"
  fi

  if [[ -d "$prefix/.git" ]] ; then
    if command -v git >/dev/null ; then
      ( builtin cd "$prefix" && super_cmd git pull --rebase origin master )
    else
      printf "\n>>>> Command 'git' not found on the path, please install a"
      printf " packge or build git from source and try again.\n\n"
      return 10
    fi
  elif command -v git >/dev/null ; then
    ( builtin cd "$(dirname $prefix)" && \
      super_cmd git clone --depth 1 git://$repo $(basename $prefix) || \
      super_cmd git clone https://$repo $(basename $prefix) )
  elif command -v curl >/dev/null && command -v python >/dev/null; then
    local tarball_install=1
    case "$(uname -s)" in
      SunOS)  local tar_cmd="$(which gtar)"  ;;
      *)      local tar_cmd="$(which tar)"   ;;
    esac
    [[ -z "$tar_cmd" ]] && \
      printf ">>>> tar command not found on path, aborting.\n" && return 13

    printf -- "-----> Git not found, so downloading tarball to $prefix ...\n"
    super_cmd mkdir -p "$prefix"
    curl -LsSf http://github.com/fnichol/bashrc/tarball/master | \
      super_cmd ${tar_cmd} xvz -C${prefix} --strip 1
  else
    printf "\n>>>> Command 'git', 'curl', or 'python' were not found on the path, please install a packge or build these packages from source and try again.\n\n"
    return 16
  fi
  local result="$?"

  # move bashrc.local back
  [[ -n "$stash" ]] && super_cmd mv "$stash" "$prefix/bashrc.local"

  if [ "$result" -ne 0 ]; then
    printf "\n>>>> bashrc could not find an update or has failed.\n\n"
    return 11
  fi

  if [[ -n "$tarball_install" ]] ; then

    printf -- "-----> Determining version date from github api ...\n"
    local tip_date="$(curl -sSL \
      http://github.com/api/v2/json/commits/show/fnichol/bashrc/HEAD | \
      python -c 'import sys; import json; j = json.loads(sys.stdin.read()); print j["commit"]["committed_date"];')"
    if [ "$?" -ne 0 ] ; then tip_date="UNKNOWN" ; fi
    super_cmd bash -c "(printf \"TARBALL $tip_date\" > \"${prefix}/tip.date\")"
    __bashrc_reload
    printf -- "\n\n-----> bashrc was updated and reloaded.\n"
  else

    local old_file="/tmp/bashrc.date.$$"
    if [[ -f "$prefix/tip.date" ]] ; then
      super_cmd mv "$prefix/tip.date" "$old_file"
    else
      touch "$old_file"
    fi

    local git_cmd=$(which git)
    super_cmd bash -c "( builtin cd $prefix && \
      $git_cmd log -1 --pretty=\"format:%h %ci\" > $prefix/tip.date)"

    if ! diff -q "$old_file" "$prefix/tip.date" >/dev/null ; then
      local old_rev=$(awk '{print $1}' $old_file)
      local new_rev=$(awk '{print $1}' $prefix/tip.date)
      printf "\n#### Updates ####\n-----------------\n"
      ( builtin cd $prefix && super_cmd git --no-pager log \
        --pretty=format:'%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset' \
        --abbrev-commit --date=relative $old_rev..$new_rev )
      printf "\n-----------------\n\n"
      __bashrc_reload
      printf -- "\n\n-----> bashrc was updated and reloaded.\n"
    else
      printf -- "\n-----> bashrc is already up to date and current.\n"
    fi

    super_cmd rm -f "$old_file"
  fi

  if [[ -z "$(cat $prefix/tip.date)" ]] ; then
    super_cmd rm -f "$prefix/tip.date"
  fi
}

##
# Reloads bashrc profile
__bashrc_reload() {
  bashrc_reload_flag=1
  printf "\n" # give bashrc source line more prominence
  source "${bashrc_prefix:-/etc/bash}/bashrc"
  printf -- "-----> bashrc was reload at $(date +%F\ %T\ %z).\n"
  unset bashrc_reload_flag
}

##
# Displays the version of the bashrc profile
__bashrc_version() {
  local ver=
  # Echo the version and date of the profile
  if [[ -f "${bashrc_prefix:-/etc/bash}/tip.date" ]] ; then
    ver="$(cat ${bashrc_prefix:-/etc/bash}/tip.date)"
  elif command -v git >/dev/null ; then
    ver="$(cd ${bashrc_prefix:-/etc/bash} && \
      git log -1 --pretty='format:%h %ci')"
  else
    ver="UNKNOWN"
  fi
  printf "bashrc ($ver)\n\n"
}

##
# CLI for the bash profile.
bashrc() {
  local command="$1"
  shift

  case "$command" in
    check)    __bashrc_check $@;;
    init)     __bashrc_init $@;;
    reload)   __bashrc_reload $@;;
    update)   __bashrc_update $@;;
    version)  __bashrc_version $@;;
    *)  printf "usage: bashrc (check|init|reload|update|version)\n" && return 10 ;;
  esac
}

# Skip the rest if this is not an interactive shell
if [ -z "${PS1}" -a "$-" != "*i*" ] ; then  cleanup ; return ; fi

##
# Sources all existing files in a list of files. Every file that is readable
# will get sourced as a shorthand to listing many lines of safe_source.
#
# Thanks to: https://github.com/darkhelmet/dotfiles for inspiration.
#
# @param [List] space-separated list of source files
safe_source() {
  for src ; do
    [[ -r "$src" ]] && source "$src"
  done ; unset src
}

##
# Sources first existing file in a list of files. Only the first match will be
# sourced which emulates as if/elsif/elsif... structure.
#
# Thanks to: https://github.com/darkhelmet/dotfiles for inspiration.
#
# @param [List] space-separated list of source files
safe_source_first() {
  for src ; do
    [[ -r "$src" ]] && source "$src" && unset src && return
  done ; unset src
}

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
# Calculates are truncated pwd. Overriding of the truncation length can be done
# by setting `PROMPT_LEN'.
#
# Thanks to: https://gist.github.com/548242 (@nicksieger)
short_pwd ()
{
  local pwd_length=${PROMPT_LEN-35}
  local cur_pwd=$(echo $(pwd) | sed -e "s,^$HOME,~,")

  if [ $(echo -n $cur_pwd | wc -c | tr -d " ") -gt $pwd_length ]; then
    echo "...$(echo $cur_pwd | sed -e "s/.*\(.\{$pwd_length\}\)/\1/")"
  else
    echo $cur_pwd
  fi
}

##
# Prints out contextual rvm/git state for the command prompt.
#
# Thanks to https://github.com/darkhelmet/dotfiles for the inspiration.
__prompt_state() {
  local git_status=
  local git_status_exit=255
  local hg_status=
  local hg_status_exit=255

  git_status=$(git -c color.status=false status --short --branch 2>/dev/null)
  git_status_exit=$?

  if [ $git_status_exit -eq 0 ] ; then
    local bits=''
    printf "$git_status" | egrep -q '^ ?M'      && bits="${bits}±"  # modified files
    printf "$git_status" | egrep -q '^ ?\?'     && bits="${bits}?"  # untracked files
    printf "$git_status" | egrep -q '^ ?A'      && bits="${bits}*"  # new/added files
    printf "$git_status" | egrep -q '^ ?R'      && bits="${bits}>"  # renamed files
    printf "$git_status" | egrep -q '^ ?D'      && bits="${bits}⚡"  # deleted files
    printf "$git_status" | egrep -q ' \[ahead ' && bits="${bits}+"  # ahead of origin

    local branch="$(printf "$git_status" | egrep '^## ' | \
      awk '{print $2}' | sed 's/\.\.\..*$//')"
    [[ "$branch" == "Initial commit on master" ]] && branch="nobranch"

    local last_commit=$(git log --pretty=format:'%at' -1 2>/dev/null)
    local age="-1"
    if [[ -n "$last_commit" ]] ; then
      age="$(($(($(date +%s)-last_commit))/60))" # zomg nesting
    fi

    local age_color="green"
    if [[ "$age" -lt 0 ]] ; then
      age_color="cyan"
    elif [[ "$age" -gt 60 ]] ; then
      age_color="red"
    elif [[ "$age" -gt 30 ]] ; then
      age_color="yellow"
    fi

    # if age is more than 7 days, show in days otherwise minutes
    if [[ "$age" -gt 10080 ]] ; then
      age="$((age/1440))d"
    else
      age="${age}m"
    fi

    case "$TERM" in
      *term | xterm-* | rxvt | screen | screen-*)
        age="$(bput $age_color)$age$(bput rst)"
        bits="$(bput cyan)$bits$(bput rst)"
      ;;
    esac

    printf "%b" " $(bput magenta)git(${age}$(bput magenta)|$(bput rst)${branch}${bits}$(bput magenta))$(bput rst)"
  else

    # only attempt hg repo checks if git fails (no need to compute both every time)
    hg_status=$(hg status --config 'extensions.color=!' 2>/dev/null)
    hg_status_exit=$?
  fi

  if [ $hg_status_exit -eq 0 ] ; then
    local bits=''
    printf "$hg_status" | egrep -q '^M '   && bits="${bits}±"  # modified files
    printf "$hg_status" | egrep -q '^\? '  && bits="${bits}?"  # untracked files
    printf "$hg_status" | egrep -q '^A '   && bits="${bits}*"  # new files
    printf "$hg_status" | egrep -q '^! '   && bits="${bits}!"  # deleted files
    printf "$hg_status" | egrep -q '^R '   && bits="${bits}⚡"  # removed files

    local branch="$(hg branch)"
    [[ -z "$branch" ]] && branch="nobranch"

    local last_commit=$(hg log -l 1 --template '{date|hgdate}' 2>/dev/null | \
      awk '{print $1}')
    local age="-1"
    if [[ -n "$last_commit" ]] ; then
      age="$(($(($(date +%s)-last_commit))/60))" # zomg nesting
    fi

    local age_color="green"
    if [[ "$age" -lt 0 ]] ; then
      age_color="cyan"
    elif [[ "$age" -gt 60 ]] ; then
      age_color="red"
    elif [[ "$age" -gt 30 ]] ; then
      age_color="yellow"
    fi

    # if age is more than 7 days, show in days otherwise minutes
    if [[ "$age" -gt 10080 ]] ; then
      age="$((age/1440))d"
    else
      age="${age}m"
    fi

    case "$TERM" in
      *term | xterm-* | rxvt | screen | screen-*)
        age="$(bput $age_color)$age$(bput rst)"
        bits="$(bput cyan)$bits$(bput rst)"
      ;;
    esac

    printf "%b" " $(bput magenta)hg(${age}$(bput magenta)|$(bput rst)${branch}${bits}$(bput magenta))$(bput rst)"
  fi

  if command -v chruby >/dev/null && [[ -n "$RUBY_ROOT" ]] ; then
    printf "%b" " {$(basename $RUBY_ROOT)}"
  elif command -v rvm-prompt >/dev/null ; then
    printf "%b" " {$(rvm-prompt)}"
  fi
}

##
# Sets a shell prompt. Uses a set variable of `PROMPT_COLOR' to determine
# the main color of the prompt, if it exists. This is generally set in
# bashrc.local. If a variable of `REMOTE_PROMPT_COLOR' is given, then this
# color will be used for all remote SSH sessions.
#
bash_prompt() {
  [[ -z "$PROMPT_COLOR" ]] && PROMPT_COLOR="default"

  # change prompt color if remotely logged in and alt color is given
  if [ -n "$SSH_CLIENT" -a -n "$REMOTE_PROMPT_COLOR" ] ; then
    PROMPT_COLOR="$REMOTE_PROMPT_COLOR"
  fi

  if [ "$($_id -ur)" -eq "0" ] ; then  # am I root?
    local user_c="#" ; local tb=$user_c ; local color="red"
  else
    local user_c=">" ; local tb=""      ; local color="$PROMPT_COLOR"
  fi

  case "$TERM" in
    *term | xterm-* | rxvt | screen | screen-*)
      local cyan="\[$(bput cyan)\]"
      if [[ -z "$bashrc_light_bg" ]] ; then
        local white="\[$(bput white)\]"
      else
        local white="\[$(bput black)\]"
      fi
      local nocolor="\[$(bput rst)\]"
      local custom="\[$(bput $color)\]"
      local titlebar="\[\033]0;${tb}\u@\h:\w${tb}\007\]"
    ;;
    *)
      local cyan=""
      local white=""
      local nocolor=""
      local custom=""
      local titlebar=""
    ;;
  esac

  local prompt_core=""
  if [ -n "$SSH_TTY" -o "$($_id -ur)" -eq "0" ] ; then
    local prompt_core="\u@\h"
  fi

  PS1="${titlebar}${cyan}[${custom}\$(short_pwd)${white}\$(__prompt_state)${cyan}]${nocolor}\n${custom}${prompt_core}${user_c} ${nocolor}"
  PS2="${custom}${user_c} ${nocolor}"
}

##
# Determines the primary hostname of another domain name. Often used to
# resolve a website url (like `www.example.com') to a server hostname
# (like `webserver1.domainhosting.com').
#
# @params [String] domainname to look up
if command -v dig >/dev/null ; then
  hostfromdomain() {
    [[ -z "$1" ]] && printf "usage: hostfromdomain <domainname>\n" && return 11
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
    if [[ -f "${HOME}/.ssh/id_rsa.pub" ]] ; then
      local key="${HOME}/.ssh/id_rsa.pub"
    else
      local key="${HOME}/.ssh/id_dsa.pub"
    fi
  else
    local key="$1"
  fi
  shift

  [[ ! -f "$key" ]] && echo "SSH key: $key does not exist." && return 11

  if echo "$host" | egrep -q ':' ; then
    local ssh_cmd="$(echo $host | awk -F':' '{print \"ssh -p \" $2 \" \" $1}')"
  else
    local ssh_cmd="ssh $host"
  fi

  $ssh_cmd '(if [ ! -d "${HOME}/.ssh" ]; then \
    mkdir -m 0700 -p ${HOME}/.ssh; fi; \
    cat - >> .ssh/authorized_keys)' < $key
}

##
# Returns the remote user's public SSH key on STDOUT. The host can optionally
# contain the username (like `jdoe@ssh.example.com') and a non-standard port
# number (like `ssh.example.com:666').
#
# @param [String] remote ssh host in for form of [<user>@]host[:<port>]
# @param [String] remote public key, using id_dsa.pub by default
mysshkey() {
  [[ -z "$1" ]] && printf "Usage: mysshkey <ssh_host> [<pub_key>]\n" && return 10

  local host="$1"
  shift
  if [[ -z "$1" ]] ; then
    local key="id_dsa.pub"
  else
    local key="$1"
  fi
  shift

  if echo "$host" | egrep -q ':' ; then
    local ssh_cmd="$(echo $host | awk -F':' '{print \"ssh -p \" $2 \" \" $1}')"
  else
    local ssh_cmd="ssh $host"
  fi

  $ssh_cmd "(cat .ssh/$key)"
}

##
# Quickly starts a webserver from the current directory.
#
# Thanks to:
# http://superuser.com/questions/52483/terminal-tips-and-tricks-for-mac-os-x
#
# @param [optional, Integer] bind port number, default 8000
web_serve() {
  local p="${1:-8000}"
  if command -v ruby >/dev/null; then
    ruby -rwebrick \
      -e"WEBrick::HTTPServer.new(:Port => $p, :DocumentRoot => Dir.pwd).start"
  elif command -v python >/dev/null; then
    python -m SimpleHTTPServer $p
  else
    printf ">>>> Could not find ruby or python on PATH. Install and retry.\n"
    return 9
  fi
}

##
# Launch view using input from STDIN initialized with a desired filetype.
#
# @param [String] vim/view filetype, such as `json`, `yaml`, etc.
viewin() {
  vim -R -c "set ft=$1" -
}

#
# Performs an egrep on the process list. Use any arguments that egrep accetps.
#
# @param [Array] egrep arguments
case "$_os" in
  Darwin|OpenBSD|FreeBSD) psg() { ps wwwaux | egrep "($@|\bPID\b)" | egrep -v "grep"; } ;;
  SunOS|Linux)    psg() { ps -ef | egrep "($@|\bPID\b)" | egrep -v "grep"; } ;;
  CYGWIN_*)       psg() { ps -efW | egrep "($@|\bPID\b)" | egrep -v "grep"; } ;;
esac

case "$_os" in
Darwin)
  ##
  # Logs out another logged in macOS user, or the current user by default.
  #
  # Thanks to:
  # https://superuser.com/questions/40061/what-is-the-mac-os-x-terminal-command-to-log-out-the-current-user#answer-1368015
  #
  # @param [optional, String] macOS username, defaulting to current user
  logout-gui() {
    sudo launchctl bootout "user/$(id -u "${1:-$USER}")"
  }

  ##
  # Quits OS X applications from the command line.
  #
  # Thanks to:
  # http://superuser.com/questions/52483/terminal-tips-and-tricks-for-mac-os-x
  #
  # @param [List] list of applications
  quit() {
    for app in $* ; do
      osascript -e 'quit app "'$app'"'
    done ; unset app
  }

  ##
  # Relaunches OS X applications from the command line.
  #
  # Thanks to:
  # http://superuser.com/questions/52483/terminal-tips-and-tricks-for-mac-os-x
  #
  # @param [List] list of applications
  relaunch() {
    for app in $* ; do
      osascript -e 'quit app "'$app'"'
      sleep 2
      open -a $app
    done ; unset app
  }

  ##
  # Opens a man page in Preview.app
  #
  # Thanks to:
  # http://superuser.com/questions/52483/terminal-tips-and-tricks-for-mac-os-x
  #
  # @param [String] man page
  # @param [optional, String] man section
  pman() {
    man -t $@ | open -f -a /Applications/Preview.app
  }

  ##
  # Updates the firewall rules to allow `mosh-server` after upgrades.
  #
  # Thanks to:
  # https://github.com/mobile-shell/mosh/issues/898#issuecomment-368566044
  mosh-server-fw-update() {
    local fw=/usr/libexec/ApplicationFirewall/socketfilterfw
    local bin_symlink bin_path
    bin_symlink="$(command -v mosh-server)"
    bin_path="$(greadlink -f "$bin_symlink")"

    sudo "$fw" --setglobalstate off
    sudo "$fw" --add "$bin_symlink"
    sudo "$fw" --unblockapp "$bin_symlink"
    sudo "$fw" --add "$bin_path"
    sudo "$fw" --unblockapp "$bin_path"
    sudo "$fw" --setglobalstate on
  }
;;
OpenBSD)
  ##
  # Fixes calls to `tput setaf <INT>` when `TERM` is set to a value ending in
  # `-256color`. This only appears to affect modern OpenBSD releases and as
  # the last two interger values seem to do nothing, we'll add `0 0` to the
  # end of the call. This fixes the prompt coloring on OpenBSD without
  # affecting the otherwise portable logic.
  #
  # See:
  # http://openbsd-archive.7691.n7.nabble.com/tput-1-setaf-capability-and-256color-terminals-td283296.html
  tput() {
    if [[ "$1" == "setaf" ]]; then
      case "$TERM" in
      *-256color) /usr/bin/tput $* 0 0 ;;
      *) /usr/bin/tput $* ;;
      esac
    else
      /usr/bin/tput $*
    fi
  }
;;
esac

##
# Returns the primary IP address of the system.
case "$_os" in
  Darwin)
    whatsmy_primary_ip() {
      local _if="$(route -n get default | grep 'interface: ' | awk '{print $2}')"
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
  OpenBSD|FreeBSD)
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
        awk '/^\t*inet / {print $2}')"

      if [ -z "$_ip" -o "$_ip" == "" ]; then
        echo "Could not determine primary IP address"
        return 10
      else
        echo $_ip
      fi
    }
  ;;
esac # case $_os

##
# Returns the public/internet visible IP address of the system.
#
# Thanks to @mojombo's baddass tweet:
# https://twitter.com/#!/mojombo/status/48948402955882496
#
whatsmy_public_ip() {
  curl --silent 'https://jsonip.com/' | json_val '["ip"]'
}

##
# Calculates diskusage (with du) and reports back sorted and human readable.
#
# Thanks to https://github.com/lucapette/dotfiles/blob/master/bash/aliases
# for the inspiration
#
# @param [Array] list of files or directories to report on (file args to du)
diskusage() {
  du -ks "$@" | sort -nr | \
    awk '{ \
      if ($1 > 1048576) printf("%8.2fG", $1/1048576) ; \
      else if ($1 > 1024) printf("%8.2fM", $1/1024) ; \
      else printf("%8.2fK", $1) ; \
      sub($1, "") ; print \
    }'
}

if [[ ! -f "$HOME/.homesick/repos/homeshick/homeshick.sh" ]]; then
  homeshick_install() {
    if command -v git >/dev/null ; then
      git clone git://github.com/andsens/homeshick.git \
        "$HOME/.homesick/repos/homeshick"
      safe_source "$HOME/.homesick/repos/homeshick/homeshick.sh"
      unset homeshick_install
      printf -- "-----> homeshick installed and loaded.\n"
    else
      printf ">>>> Could not find git command on PATH. Install and retry.\n"
      return 70
    fi
  }
fi

if command -v fd >/dev/null && command -v fzf >/dev/null; then
  ##
  # Changes directory based on a fuzzy finder list of directories
  #
  # @param [optional, String] directory path to search under, default `.`
  cf() {
    cd "$(fd --hidden --no-ignore --type d . "${1:-.}" | fzf)"
  }
fi


#---------------------------------------------------------------
# Interactive shell (prompt,history) settings
#---------------------------------------------------------------

# Set the default editor
if [ -z "$SSH_CLIENT" ] ; then          # for local/console sessions
  case "$TERM" in
  screen*|xterm-256color)               # we're in screen or tmux
    if command -v vim >/dev/null ; then
      export EDITOR="$(which vim)"
      export BUNDLER_EDITOR="$EDITOR"
    else
      export EDITOR="$(which vi)"
      export BUNDLER_EDITOR="$EDITOR"
    fi
  ;;
  *)                                      # we're on a normal term console
    if command -v mvim >/dev/null ; then
      case "$TERM_PROGRAM" in
        Apple_Terminal) _terminal="Terminal"  ;;
        iTerm.app)      _terminal="iTerm"     ;;
      esac
      export EDITOR="$(which mvim) -f -c \"au VimLeave * !open -a ${_terminal}\""
      export BUNDLER_EDITOR="$(which mvim)"
      unset _terminal
    elif command -v gvim >/dev/null ; then
      export EDITOR="$(which gvim) -f"
      export BUNDLER_EDITOR="$(which gvim)"
    elif command -v mate >/dev/null ; then
      export EDITOR="mate -w"
      export EDITOR="mate"
    elif command -v vim >/dev/null ; then
      export EDITOR="$(which vim)"
      export BUNDLER_EDITOR="$EDITOR"
    else
      export EDITOR="$(which vi)"
      export BUNDLER_EDITOR="$EDITOR"
    fi
  ;;
  esac
else                                    # for remote/ssh sessions
  if command -v vim >/dev/null ; then
    export EDITOR="$(which vim)"
  else
    export EDITOR="$(which vi)"
  fi
  export BUNDLER_EDITOR="$EDITOR"
fi
export VISUAL="$EDITOR"
export GEM_EDITOR="$BUNDLER_EDITOR"

# Set default visual tabstop to 2 characters, rather than 8
export EXINIT="set tabstop=2 bg=dark"

# Number of commands to remember in the command history
export HISTSIZE=10000

# The number of lines contained in the history file
export HISTFILESIZE=999999

# Prepend a timestamp on each history event
export HISTTIMEFORMAT="%Y-%m-%dT%H:%M:%S "

# Ignore commands starting with a space, duplicates,
# and a few others.
export HISTIGNORE="[ ]*:&:bg:fg:ls -l:ls -al:ls -la:ll:la"

# Set the default command for fzf, if it's installed. Prefer `fd` for finding
# if present, and fall back to `rg` (ripgrep) if present (it's still crazy fast
# for finding files, even though that's not it's self-declared sweet spot)
if command -v fzf >/dev/null; then
  if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git"
  elif command -v rg >/dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --no-ignore --hidden --follow -g '!.git/*'"
  fi
fi

bash_prompt ; unset bash_prompt

export IGNOREEOF=10

shopt -s checkwinsize
shopt -s histappend

# Echo the version and date of the profile
__bashrc_version


#---------------------------------------------------------------
# Completions
#---------------------------------------------------------------

complete -W "check init reload update version" bashrc

# load in rvm completions, if rvm is loaded
safe_source "${rvm_path}/scripts/completion"

safe_source_first /usr/local/git/contrib/completion/git-completion.bash \
  /usr/share/git/completion/git-completion.bash

# load in some choice completions from homebrew if installed
if command -v brew >/dev/null ; then
  if [ -f "$(brew --prefix)/etc/bash_completion" ] ; then
    # bash-completion is installed
    safe_source $(brew --prefix)/etc/bash_completion
  else
    safe_source "$(brew --prefix)/Library/Contributions/brew_bash_completion.sh"
    safe_source $(brew --prefix)/etc/bash_completion.d/*
  fi
fi

case "$_os" in
  Linux)
    if [ -f "/etc/bash_completion" ] && ! shopt -oq posix; then
      safe_source "/etc/bash_completion"
    fi
  ;;
  FreeBSD)
    safe_source "/usr/local/share/bash-completion/bash_completion"
  ;;
esac

if command -v rustup >/dev/null ; then
  eval "$(rustup completions bash rustup)"
  eval "$(rustup completions bash cargo)"
fi

if command -v kubectl >/dev/null ; then
  eval "$(kubectl completion bash)"
fi

if command -v helm >/dev/null ; then
  eval "$(helm completion bash)"
fi

if command -v kind >/dev/null ; then
  eval "$(kind completion bash)"
fi

if command -v minikube >/dev/null ; then
  eval "$(minikube completion bash)"
fi


#---------------------------------------------------------------
# Post-environment initialization
#---------------------------------------------------------------

# load homeshick if installed
safe_source "$HOME/.homesick/repos/homeshick/homeshick.sh"

if command -v zoxide >/dev/null ; then
  eval "$(zoxide init bash)"
fi

if command -v direnv >/dev/null ; then
  eval "$(direnv hook $SHELL)"
fi


#---------------------------------------------------------------
# Set Aliases (Commonly Used Shortcuts)
#---------------------------------------------------------------

alias ll='ls -l'
alias la='ls -al'
alias lm='ll | less'

alias bu='bashrc update'

alias tf='tail -f'

# Strip out ANSI color and escape characters on STDIN, thanks to:
# http://unix.stackexchange.com/questions/4527/program-that-passes-stdin-to-stdout-with-color-codes-stripped
alias strip-ansi="perl -pe 's/\e\[?.*?[\@-~]//g'"

if command -v homesick >/dev/null ; then
  __homesick_update() {
    local castles="$(homesick list | awk '{print $2}' | \
      sed -e 's|^\([a-zA-Z0-9_ -]\{1,\}\).*$|\1|' | xargs)"

    for c in $castles ; do
      printf -- "-----> Updating $c castle ...\n"
      $(which homesick) pull "$c" --force
      $(which homesick) symlink "$c" --force
    done ; unset c

    printf -- "-----> homesick castles [$castles] are up to date.\n"
  }
  alias hsu=__homesick_update
fi

if command -v vagrant >/dev/null ; then
  alias vsh='vagrant ssh'
  alias vst='vagrant status'
  vup() { time (vagrant up $*) ; }
  vpr() { time (vagrant provision $*) ; }
  vre() { time (vagrant reload $*) ; }
  alias vsu='vagrant suspend'
  alias vde='vagrant destroy'
fi

alias be='bundle exec'

# If pine is installed, eliminated the .pine-debugX files
[[ -s "/usr/local/bin/pine" ]] && alias pine="pine -d 0"

# OS-specific aliases
case "$_os" in
  Darwin)
    # Add the super alias to properly become root with bash and
    # environment settings
    alias super="sudo -s -H"

    if [[ -z "$bashrc_light_bg" ]] ; then
      # Default color scheme
      export LSCOLORS="exfxcxdxbxegedabagacad"
    fi

    # Colorize ls by default
    alias ls="ls -G"

    # Colorize grep/egrep/fgrep by default
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias fgrep='fgrep --color=auto'

    # Lowercase uuids
    alias uuidlower="uuidgen | tr '[[:upper:]]' '[[:lower:]]'"

    # List TCP port that are listening
    # Thanks to:
    # https://github.com/jqr/dotfiles/blob/master/bash_profile.d/mac.sh
    alias openports='sudo lsof -iTCP -sTCP:LISTEN -P'

    # Update /etc/hosts
    alias update_hosts='dscacheutil -flushcache'

    # Performs a fast logout (user switching) to lock your screen
    alias lockscreen='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

    # Puts the mac to sleep and exists shell session. Shell history gets preserved.
    alias gotosleep='history -a && sudo shutdown -s now && exit'

    # set TMPDIR to /tmp for tmux commands. see:
    # http://stackoverflow.com/questions/9039256/tmux-not-re-attaching
    # also, force tmux to assume the terminal supports 256 colors
    if [[ -n "$TMPDIR" ]] ; then
      alias tmux='TMPDIR=/tmp tmux -2'
    fi

    # Set the path to the X11 library (in Mountain Lion) for compiling
    # 1.8.7 MRI. See:
    # http://stackoverflow.com/questions/11664835/mountain-lion-rvm-install-1-8-7-x11-error#answer-11666019
    if [[ -d "/opt/X11/include" ]] ; then
      export CPPFLAGS="-I/opt/X11/include $CPPFLAGS"
    fi

    if [[ -d "/etc/profile.d" ]] && [[ -n "$(find /etc/profile.d -name '*.sh')" ]] ; then
      safe_source $(ls -1 /etc/profile.d/*.sh | sort | xargs)
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

    # Force tmux to assume the terminal supports 256 colors.
    alias tmux='tmux -2'

    # Add macOS style `pbcopy` and `pbpaste` aliases using `xsel`, thanks to:
    # https://gist.github.com/aarnone/83ce3b053ace037ada850d13133317f2
    if command -v xsel >/dev/null ; then
      alias pbcopy='xsel --clipboard --input'
      alias pbpaste='xsel --clipboard --output'
    fi

    # If the shell is interactive and not a login shell (i.e. the first
    # character of argument zero is a `-`), then `/etc/profile` won't be
    # sourced so we'll source any items under `/etc/profile.d` directly.
    if [[ ! "$0" =~ ^- ]] && [[ -d "/etc/profile.d" ]] \
      && [[ -n "$(find /etc/profile.d -name '*.sh')" ]] ; then
      safe_source $(ls -1 /etc/profile.d/*.sh | sort | xargs)
    fi
  ;;
  FreeBSD)
    # Colorize ls by default
    alias ls="ls -G"

    # Colorize grep/egrep/fgrep by default
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias fgrep='fgrep --color=auto'
  ;;
esac

safe_source "${bashrc_prefix:-/etc/bash}/bashrc.local" "${HOME}/.bash_aliases"

cleanup
