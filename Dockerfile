FROM debian:stable-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y curl openssh-server xz-utils && \
    apt-get clean

# Install Nix
RUN sh <(curl -L https://nixos.org/nix/install) --daemon

# Setup SSH
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'root:password' | chpasswd

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
