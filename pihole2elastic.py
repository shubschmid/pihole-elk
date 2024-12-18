import sqlite3
from elasticsearch import Elasticsearch
import json
import os
import urllib3
from datetime import datetime
import time
import logging
from logging.handlers import RotatingFileHandler

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configure logging
log_file = "/var/log/pihole_elasticsearch_service.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        RotatingFileHandler(log_file, maxBytes=5 * 1024 * 1024, backupCount=5)
    ]
)

# Configuration for Elasticsearch (with authentication and HTTPS)
# Replace the host, port, username, and password with the appropriate values for your Elasticsearch instance.
es = Elasticsearch(
    [{'host': '123.123.123.123', 'port': 9200}],
    http_auth=('fake_user', 'fake_password'),
    scheme="https",  # If Elasticsearch is running with HTTPS
    verify_certs=False  # If a self-signed certificate is being used
)

# Path to the Pi-hole SQLite database
sqlite_db_path = "/etc/pihole/pihole-FTL.db"

# Path to the file that stores the last timestamp
id_file = "/var/lib/pihole-elasticsearch/last_processed_id.txt"

# Path to the configuration file containing sleep interval
config_file = "/etc/pihole-elasticsearch/config.json"

# Function to retrieve the last processed timestamp
def get_last_processed_id():
    if os.path.exists(id_file):
        with open(id_file, 'r') as f:
            return f.read().strip()
    else:
        return "0"  # If no file exists

# Function to update the last processed timestamp
def update_last_processed_id(id):
    with open(id_file, 'w') as f:
        f.write(str(id))

# Function to read sleep interval from the configuration file
def get_sleep_interval():
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            try:
                config = json.load(f)
                return config.get("sleep_interval", 3600)  # Default to 3600 seconds if not specified
            except json.JSONDecodeError:
                logging.error("Error decoding configuration file. Using default sleep interval.")
                return 3600
    else:
        logging.warning("Configuration file not found. Using default sleep interval.")
        return 3600

# Main function to process and send data to Elasticsearch
def process_data():
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect(sqlite_db_path)
        logging.info("Connected to SQLite!")
    except sqlite3.Error as e:
        logging.error(f"Error: {e}")
        return

    cursor = conn.cursor()

    # Retrieve the last processed timestamp
    last_id = get_last_processed_id()
    logging.info(f"ID {last_id}")

    # SQL query to retrieve only entries after the last timestamp
    sql_query = f"SELECT id, domain, client, datetime(timestamp, 'unixepoch', 'localtime'), timestamp from queries WHERE id > '{last_id}'"

    # Execute the SQL query
    try:
        cursor.execute(sql_query)
        logging.info("SQL query successfully executed")
    except sqlite3.Error as e:
        logging.error(f"SQL query NOT successfully executed: {e}")
        conn.close()
        return

    # Processing and sending to Elasticsearch
    row_count = 0
    for row in cursor:
        # Extract the record's date (in the format "yyyy-MM-dd HH:mm:ss")
        datetime_str = row[3]
        
        # Convert the date to ISO 8601 format "yyyy-MM-dd'T'HH:mm:ss"
        iso_datetime = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M:%S").isoformat()

        # Create a document for Elasticsearch
        doc = {
            "id": row[0],
            "domain": row[1],
            "client": row[2],
            "datetime": iso_datetime,  # The datetime field is now in ISO 8601 format
            "timestamp": row[4],
        }

        # Create Elasticsearch index per date
        # Extract only the year and month in the format "yyyy-MM"
        date_part = "-".join(iso_datetime.split("T")[0].split("-")[:2])  
        index_name = f"pihole-dns-logs-{date_part}"

        # Add index and document to Elasticsearch
        response = es.index(index=index_name, document=doc)
        logging.info(f"Elasticsearch response: {response}")

        # Update the last processed timestamp
        update_last_processed_id(row[0])
        row_count += 1

    # Close the connection to the SQLite database
    conn.close()
    logging.info(f"New data successfully sent to Elasticsearch. Rows: {row_count}")

# Run the script as a service with configurable execution interval
if __name__ == "__main__":
    while True:
        logging.info("Starting data processing...")
        process_data()
        sleep_interval = get_sleep_interval()
        logging.info(f"Data processing complete. Sleeping for {sleep_interval} seconds.")
        time.sleep(sleep_interval)
