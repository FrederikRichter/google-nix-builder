FROM nixos/nix

# Install openssh package
RUN nix-env -iA nixpkgs.openssh

# Setup SSH
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'root:yourpassword' | chpasswd

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/nix/store/$(basename $(readlink /nix/var/nix/profiles/default))/bin/sshd", "-D"]
