#!/bin/bash

# Start the SSH server in the background
/usr/sbin/sshd

# Run the Flask application as appuser
exec su appuser -c "python /app/app7.py"
