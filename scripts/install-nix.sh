#!/bin/sh

set -e

# disable apt frontend to prevent
# any troublesome questions
export DEBIAN_FRONTEND=noninteractive
file=nix_1.8-1_amd64.deb
url="http://hydra.nixos.org/build/17897583/download/1/$file"
store_dir=/nix/store
bgroup=nixbld
ugroup=nix-users

# Check if Nix is already installed
if ! which nix-env; then


    for group in $bgroup $ugroup; do
        getent group $group > /dev/null || groupadd -r $group
    done

    for n in 1 2 3 4 5 6 7 8 9 10; do
        useradd -c "Nix build user $n" -d /var/empty -g $bgroup -G $bgroup \
            -M -N -r -s `which nologin` $bgroup$n || [ "$?" -eq 9 ]
    done

    mkdir -p /etc/nix
    cat << EOF > /etc/nix/nix.conf
build-users-group = $bgroup
trusted-users = $ugroup
EOF

    wget -q $url -O $file

    apt-get install -y -q --force-yes gdebi-core

    gdebi -n ./$file

    # Start nix daemon
    initctl start nix-daemon


    mkdir -m 1777 $store_dir
    chgrp -R nixbld $store_dir

    mkdir -p -m 1777 /nix/var/nix/profiles/per-user
    mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
    socket="/nix/var/nix/daemon-socket"

    chgrp $ugroup $socket
    chmod ug=rwx,o= $socket
    usermod -a -G $ugroup vagrant

fi

cat << EOF > /etc/profile.d/01nix-user.sh

if id -Gn | egrep -q '(^| )'${ugroup}'( |\$)';
then
    export NIX_PROFILES="/nix/var/nix/profiles/default \$HOME/.nix-profile"
    export NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/\$USER
    export NIX_USER_GCROOTS_DIR=/nix/var/nix/gcroots/per-user/\$USER
    export NIX_REMOTE=daemon

    for i in \$NIX_PROFILES; do
        export PATH=\$i/bin:\$PATH
    done


    if [ ! -e \$NIX_USER_PROFILE_DIR ]; then
        mkdir -m 0755 -p \$NIX_USER_PROFILE_DIR
        chown -R \$USER \$NIX_USER_PROFILE_DIR
    fi
    if test "\$(stat --printf '%u' \$NIX_USER_PROFILE_DIR)" != "\$(id -u)"; then
        echo "WARNING: bad ownership on \$NIX_USER_PROFILE_DIR" >&2
    fi

    #rm -f \$HOME/.nix-profile
    if ! test -L \$HOME/.nix-profile; then
        echo "creating \$HOME/.nix-profile" >&2
        if test "\$USER" != root; then
            ln -s \$NIX_USER_PROFILE_DIR/profile \$HOME/.nix-profile
        else
            # Root installs in the system-wide profile by default.
            ln -s /nix/var/nix/profiles/default \$HOME/.nix-profile
        fi
    fi

    if [ ! -e \$NIX_USER_GCROOTS_DIR ]; then
        mkdir -m 0755 -p \$NIX_USER_GCROOTS_DIR
        chown -R \$USER \$NIX_USER_GCROOTS_DIR
    fi
    if test "\$(stat --printf '%u' \$NIX_USER_GCROOTS_DIR)" != "\$(id -u)"; then
        echo "WARNING: bad ownership on \$NIX_USER_GCROOTS_DIR" >&2
    fi


    if [ ! -e \$HOME/.nix-defexpr -o -L \$HOME/.nix-defexpr ]; then
        echo "creating \$HOME/.nix-defexpr" >&2
        rm -f \$HOME/.nix-defexpr
        mkdir \$HOME/.nix-defexpr
        if [ "\$USER" != root ]; then
            ln -s /nix/var/nix/profiles/per-user/root/channels \
                \$HOME/.nix-defexpr/channels_root
        fi
    fi
fi
EOF
