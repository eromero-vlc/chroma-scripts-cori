#!/bin/bash

source ensembles.sh

read -r -d '' ssh_config_text << EOF
Host scilogin.jlab.org
  ControlMaster auto
  ControlPath ~/.ssh/scilogin.sock
  ControlPersist yes
  User $jlab_user
Host qcdi1402.jlab.org
  ControlMaster auto
  ControlPath ~/.ssh/qcdi1402.sock
  ControlPersist yes
  ProxyJump scilogin.jlab.org
  User $jlab_user
EOF

# Check that scilogin in setup
if ! grep -q scilogin ~/.ssh/config 2>&1 > /dev/null; then
	read -r -d '' question_msg << EOF
Proper ssh configuration isn't detected. The following text
will be appended to ~/.ssh/config:

$ssh_config_text

Do you like to continue? (y/n):
EOF
	read -p "$question_msg" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	echo "$ssh_config_text" >> ~/.ssh/config
	chmod 600 ~/.ssh/config
fi

if $jlab_ssh ls $jlab_local > /dev/null; then
	echo succesful ssh conection
	exit 0
else
	echo something wrong happened
	exit 1
fi
