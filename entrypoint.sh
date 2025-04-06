#!/bin/bash

# Ensure SSH host keys are generated and the SSH service is started
/usr/sbin/sshd -D &

# Run the Flask application as appuser
exec su appuser -c "python /app/app7.py"
