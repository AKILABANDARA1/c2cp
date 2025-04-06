FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install Python and system dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    ssh-keygen -A && \
    apt-get clean

# Copy application code
COPY . .

# Create non-root user with UID 10001
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /bin/sh -m appuser && \
    echo 'appuser:password' | chpasswd

# SSH configuration
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers appuser" >> /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config

# Expose Flask and SSH ports
EXPOSE 8080 2222

# Set environment for Flask
ENV FLASK_APP=app7.py
ENV FLASK_ENV=production

# declares default container user
USER 10001

# But we need to run sshd as root, so use a root shell to start it
CMD ["/bin/sh", "-c", "su -s /bin/sh root -c '/usr/sbin/sshd' && python app7.py"]
