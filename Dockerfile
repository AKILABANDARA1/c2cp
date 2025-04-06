FROM python:3.9-slim

WORKDIR /app

# Copy only the required files first to leverage Docker caching
COPY requirements.txt .

# Install dependencies and OpenSSH
RUN apt-get update && \
    apt-get install -y openssh-server && \
    pip install --no-cache-dir -r requirements.txt && \
    mkdir /var/run/sshd && \
    ssh-keygen -A && \  # Ensure SSH host keys are generated
    apt-get clean

# Copy the rest of the application files
COPY . .

# Create a non-root user (for Checkov compliance)
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /bin/sh -m appuser && \
    echo 'appuser:password' | chpasswd

# SSH config to allow the appuser and set port 2222
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers appuser" >> /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config

# Expose port 8080 for the Flask app and port 2222 for SSH
EXPOSE 8080 2222

# Set environment variable for Flask
ENV FLASK_APP=app7.py
ENV FLASK_ENV=production

# Create an entrypoint script to start SSH and Flask app
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to root user temporarily to run SSH
USER root

# Use entrypoint script to run both SSH and Flask as the appuser
ENTRYPOINT ["/entrypoint.sh"]

# Ensure the final user is non-root (Checkov requirement)
USER 10001
