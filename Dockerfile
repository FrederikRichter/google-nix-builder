FROM debian:stable-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y curl openssh-server && \
    apt-get clean

# Download and install Nix
RUN curl -L https://nixos.org/nix/install -o install-nix.sh && \
    sh install-nix.sh --daemon && \
    rm install-nix.sh

# Setup SSH
RUN mkdir /var/run/sshd && \
    mkdir -p /root/.ssh && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config

# Copy public SSH key
COPY my_ssh_key.pub /root/.ssh/authorized_keys

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
