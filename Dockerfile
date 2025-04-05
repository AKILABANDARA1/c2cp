# Use an official lightweight Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy only the required files first to leverage Docker caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application files
COPY . .

# Create a non-root user with UID 10014 (valid for Choreo checks)
RUN groupadd -g 10001 appuser && useradd -u 10001 -g appuser -s /bin/sh appuser

# Set the user to be used for the container
USER 10001

# Expose port 80 for the Flask app
EXPOSE 8080

# Set the environment variable for Flask
ENV FLASK_APP=app7.py
ENV FLASK_ENV=production

# Run the C2 server
CMD ["python", "app7.py"]

