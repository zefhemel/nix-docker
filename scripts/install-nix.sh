#!/bin/sh

set -e

# Check if Nix is already installed

if [ -d "/nix/store" ]; then
    exit 0
fi

# Install the binary tarball...
apt-get install -y curl
cd /
curl -L http://hydra.nixos.org/job/nix/trunk/binaryTarball.x86_64-linux/latest/download | tar xj
/usr/bin/nix-finish-install
rm /usr/bin/nix-finish-install

# Hack
chmod 777 /nix/var/nix/profiles

# Setup multiuserbu

# Allow all users to create profiles
mkdir -p /nix/var/nix/profiles/per-user
chmod 1777 /nix/var/nix/profiles/per-user

# Add build users
# 9 is the exit code when the group already exists
groupadd -r nixbld || [ "$?" -eq 9 ]
for n in 1 2 3 4 5 6 7 8 9 10; do
    useradd -c "Nix build user $n" -d /var/empty -g nixbld -G nixbld \
        -M -N -r -s `which nologin` nixbld$n || [ "$?" -eq 9 ]
done
chown root:nixbld /nix/store
chmod 1775 /nix/store
mkdir -p /etc/nix
grep -w build-users-group /etc/nix/nix.conf 2>/dev/null || echo "build-users-group = nixbld" >> /etc/nix/nix.conf
grep -w binary-caches /etc/nix/nix.conf 2>/dev/null || echo "binary-caches = http://cache.nixos.org" >> /etc/nix/nix.conf
grep -w trusted-binary-caches /etc/nix/nix.conf 2>/dev/null || echo "trusted-binary-caches = http://hydra.nixos.org http://cache.nixos.org" >> /etc/nix/nix.conf

# Use a multiuser-compatible profile script
unlink /etc/profile.d/nix.sh
cat > /etc/profile.d/nix.sh <<EOF
if test -n "\$HOME"; then
    NIX_LINK="\$HOME/.nix-profile"

    if [ -w /nix/var/nix/db ]; then
        OWNS_STORE=1
    fi

    # Set the default profile.
    if ! [ -L "\$NIX_LINK" ]; then
        echo "creating \$NIX_LINK" >&2
        mkdir -p "/nix/var/nix/profiles/per-user/\$LOGNAME"
        _NIX_PROFILE_LINK="/nix/var/nix/profiles/per-user/\$LOGNAME/profile"
	    ln -s /nix/var/nix/profiles/default \$_NIX_PROFILE_LINK
        ln -s "\$_NIX_PROFILE_LINK" "\$NIX_LINK"
    fi

    # Subscribe the root user to the Nixpkgs channel by default.
    if [ ! -e "\$HOME/.nix-channels" ]; then
        echo "http://nixos.org/channels/nixpkgs-unstable nixpkgs" > "\$HOME/.nix-channels"
    fi

    # Set up nix-defexpr
    NIX_DEFEXPR="\$HOME/.nix-defexpr"
    if ! [ -e "\$NIX_DEFEXPR" ]; then
        echo "creating \$NIX_DEFEXPR" >&2
        mkdir -p "\$NIX_DEFEXPR"
        _NIX_CHANNEL_LINK=/nix/var/nix/profiles/per-user/root/channels
        ln -s "\$_NIX_CHANNEL_LINK" "\$NIX_DEFEXPR/channels"
	#/nix/var/nix/profiles/default/bin/nix-channel --update
    fi

    if [ -z "\$OWNS_STORE" ]; then
        export NIX_REMOTE=daemon
        export PATH="/nix/var/nix/profiles/default/bin:\$PATH"
    fi
    export PATH="\$NIX_LINK/bin:\$PATH"

    # Set up NIX_PATH
    export NIX_PATH="\$NIX_DEFEXPR/channels"
    unset OWNS_STORE
fi
EOF

# Add default nix profile to global path and enable it during sudo
sed -i 's/"$/:\/nix\/var\/nix\/profiles\/default\/bin"/' /etc/environment
sed -i 's/secure_path="/secure_path="\/nix\/var\/nix\/profiles\/default\/bin:/' /etc/sudoers

# Install upstart job
cat > /etc/init/nix-daemon.conf <<EOF
description "Nix Daemon"
start on filesystem
stop on shutdown
respawn
env NIX_CONF_DIR="/etc/nix"
exec $(readlink -f /nix/var/nix/profiles/default/bin/nix-daemon) --daemon
EOF

# Start nix daemon
initctl start nix-daemon

# Update the nix channel
/nix/var/nix/profiles/default/bin/nix-channel --update
