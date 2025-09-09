# Configuration for bash with restricted prompt
# This profile sets up a bash environment with a custom restricted prompt
# The "~" is processed by bwrapper to give $ENV{HOME}.

executable: /usr/bin/bash
args:
  - --rcfile
  - ~/.config/bwrapper/profiles/bash/bashrc
rw_paths:
  - ~/.config/bwrapper/logs/bash
env_vars: {}
additional_bwrap_args:
  - --setenv
  - BWRAP_RESTRICTED
  - "1"


