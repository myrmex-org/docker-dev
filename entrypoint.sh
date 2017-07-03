#!/bin/bash
set -e

if [ `whoami` = "root" ]; then
    if [ "$HOST_UID" != "" ]; then
        # If the user is root and a HOST_UID environment variable exists,
        # we changer the myrmex user UID and execute the command as the myrmex user
        if [ "$HOST_UID" != `id -u $DEFAULT_USER` ]; then
            echo "Changing $DEFAULT_USER UID to $HOST_UID"
            change-uid $HOST_UID $HOST_GID >/dev/null
        fi
        chown $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER/.zsh_history
        su $DEFAULT_USER -c $@
        exit
    fi
fi

exec "$@"
