# Use a base image with Nix installed
FROM nixos/nix

# Install SSH server
RUN nix-env -iA nixpkgs.openssh

# Install any additional tools you need for building
RUN nix-env -iA nixpkgs.git \
    && nix-env -iA nixpkgs.gcc

# Enable SSH service
RUN mkdir /var/run/sshd

# Allow root login and disable authentication
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Set root password to be empty (not recommended for production environments)
RUN passwd -d root

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["sshd", "-D"]

# Add Nix configuration to allow the container to act as a remote builder
RUN mkdir -p /etc/nix
