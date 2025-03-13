FROM alpine:latest

# Install inotify-tools for watching files, coreutils for chown/chmod
RUN apk add --no-cache inotify-tools bash coreutils

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh

# Make sure the script is executable
RUN chmod +x /entrypoint.sh

# Run the script when the container starts
CMD ["/entrypoint.sh"]