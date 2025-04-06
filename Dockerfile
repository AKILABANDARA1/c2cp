FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install OpenSSH and generate host keys
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    ssh-keygen -A && \
    apt-get clean

# Copy the rest of the application
COPY . .

# Create non-root user with UID 10001
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /bin/sh -m appuser && \
    echo 'appuser:password' | chpasswd

# Configure SSH
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers appuser" >> /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config

# Expose ports
EXPOSE 8080 2222

# Environment variables for Flask
ENV FLASK_APP=app7.py
ENV FLASK_ENV=production

# Set the container to run as non-root (required by Choreo)
USER 10001

# Entrypoint script to start SSHD (as root via sudo) and Flask (as appuser)
CMD ["/bin/sh", "-c", "sudo /usr/sbin/sshd && python app7.py"]
