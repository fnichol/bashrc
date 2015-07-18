## Installation

### System-Wide Deployment

```sh
curl -L https://raw.githubusercontent.com/fnichol/bashrc/master/contrib/install-system-wide | sudo bash
```

### Local (User) Deployment

```sh
curl -L https://raw.githubusercontent.com/fnichol/bashrc/master/contrib/install-local | bash
```

### Delay Loading Your Local Deployment
Simply wrap the code in your {{{${HOME}/.bash_profile}}} with a function, like so:

```sh
bl() {
  if [[ -s "${HOME}/.bash/bashrc" ]] ; then
    bashrc_local_install=1
    bashrc_prefix="${HOME}/.bash"
    export bashrc_local_install bashrc_prefix
    source "${bashrc_prefix}/bashrc"
  fi
}
```
