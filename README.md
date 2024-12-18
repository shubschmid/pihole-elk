# Pi-hole Elasticsearch Sync Service

This repository contains a Python script and installation script to sync Pi-hole DNS logs to an Elasticsearch instance. The service runs continuously, processing data and sending it to Elasticsearch at regular intervals.

## Features
- Syncs Pi-hole DNS logs from an SQLite database to Elasticsearch.
- Configurable connection details (host, port, username, password) via a configuration file.
- Runs as a systemd service for continuous operation.
- Handles log rotation for efficient disk usage.

## Installation

Follow the steps below to set up the service.

### Prerequisites
- Python 3.x installed on your system.
- `sqlite3` and `Elasticsearch` Python packages installed.
- Elasticsearch instance set up and accessible.

### Steps
1. Clone the repository and navigate to its directory:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. Run the installation script as root:
   ```bash
   sudo ./install_service.sh
   ```

### What the Installation Script Does
- Copies the Python script to `/opt/pihole-elasticsearch/`.
- Creates necessary directories for logs (`/var/log/pihole-elasticsearch`), data (`/var/lib/pihole-elasticsearch`), and configuration (`/etc/pihole-elasticsearch`).
- Generates a default configuration file at `/etc/pihole-elasticsearch/config.json`.
- Sets up a systemd service to manage the Python script.
- Configures log rotation for the service logs.
- Starts the service and enables it to start on boot.

## Configuration

The configuration file is located at:
```
/etc/pihole-elasticsearch/config.json
```

### Example Configuration
```json
{
    "host": "localhost",
    "port": 9200,
    "username": "user",
    "password": "password",
    "sleep_interval": 3600
}
```

- **host**: IP address or hostname of the Elasticsearch server.
- **port**: Port number for the Elasticsearch server.
- **username**: Username for Elasticsearch authentication.
- **password**: Password for Elasticsearch authentication.
- **sleep_interval**: Interval (in seconds) between data processing runs.

## Logs

Logs for the service are located at:
```
/var/log/pihole-elasticsearch/pihole_elasticsearch_service.log
```

Logs are rotated automatically, ensuring disk space is managed efficiently. The rotation policy keeps logs up to 5 MB in size and retains the last 5 logs.

## Service Management

The service is managed by `systemd`. Use the following commands to control the service:

- Start the service:
  ```bash
  sudo systemctl start pihole-elasticsearch
  ```

- Stop the service:
  ```bash
  sudo systemctl stop pihole-elasticsearch
  ```

- Check the status of the service:
  ```bash
  sudo systemctl status pihole-elasticsearch
  ```

- View service logs:
  ```bash
  sudo journalctl -u pihole-elasticsearch
  ```

- Enable the service to start at boot:
  ```bash
  sudo systemctl enable pihole-elasticsearch
  ```

## Troubleshooting
If the service does not work as expected:
- Check the service logs:
  ```bash
  sudo journalctl -u pihole-elasticsearch
  ```
- Verify the configuration file is correct and accessible.
- Ensure the Elasticsearch server is reachable.

## License
This project is licensed under the MIT License.

