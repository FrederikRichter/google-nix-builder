# Use the official Nix image from Docker Hub
FROM nixos/nix:latest

# Install openssh package
RUN nix-channel --update && nix-env -iA nixpkgs.openssh

# Expose SSH port
EXPOSE 22

# Start the SSH service
CMD ["/nix/store/*-openssh-*/bin/sshd", "-D"]
