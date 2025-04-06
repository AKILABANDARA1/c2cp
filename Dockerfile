# Use an official lightweight Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy only the required files first to leverage Docker caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install OpenSSH server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd

# Copy the rest of the application files
COPY . .

# Create a non-root user with UID 10001 (valid for Choreo checks)
RUN groupadd -g 10001 appuser && useradd -u 10001 -g appuser -s /bin/sh -m appuser

# Set a password for appuser (you can change 'password' to a more secure one)
RUN echo 'appuser:password' | chpasswd

# Configure SSH to allow the appuser and change the port to 2222
RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers appuser" >> /etc/ssh/sshd_config && \
    echo "Port 2222" >> /etc/ssh/sshd_config

# Set the user to be used for the container
USER 10001

# Expose port 8080 for the Flask app and port 2222 for SSH
EXPOSE 8080 2222

# Set the environment variable for Flask
ENV FLASK_APP=app7.py
ENV FLASK_ENV=production

# Start both Flask app and SSH server
CMD /usr/sbin/sshd -D & python app7.py
