# The main app. We import
# this to get access to the
# config file, so ultimately
# we can get access to the logger
import app

# Connection to the
# local database
import db

# Mock class for reading the
# temperature from the sensor
import sensor

# Exception handling
import sys

# Logging to console
import logging

# Parsing JSON response
# when making REST
# calls to the main server
import json

# Making REST calls / HTTP requests
# to the main server
import requests

# We use these to get the date when
# we read in the temperature
from time import gmtime, strftime

#-------------------------------------------------------------------------------

# Set up logger
log = logging.getLogger(app.config['app']['name'])

#-------------------------------------------------------------------------------

# Makes a REST call to a specified
# URL. Currently only supports POST requests.
def rest_call(url, method='POST', payload=None):
    response_data=None

    try:

        # If a payload was passed, consider
        # it a POST method
        if payload and method is 'POST':
            log.info("HTTP POST to url: " + url)

            # Make REST call to main server
            # and capture the response
            response      = requests.post(url=url, json=response_data)
            response_data = json.loads(response.text)

            log.info("Response from server: " + str(response_data))

        # Consider it a GET method
        else:
            raise ValueError("Only POST method is current supported")

    except:
        log.error("ERROR")

    return response_data

#-------------------------------------------------------------------------------

# Initializes the device
# by setting up the local database
def initialize_database(last_record_time):
    log.info('Initializing sqlite3 database')

    # Create the database
    return db.create_temperature_database(last_record_time)

#-------------------------------------------------------------------------------

# Registers this device with the main server
# by sending this device's name, and obtaining
# a uniqie device_id number.
def register_device(device_name):
    device_id        = None
    last_record_time = None

    log.info('Registering this device with the name: ' + device_name)

    # Make REST call to main server
    try:

        # Prepare contents of HTTP request
        data     = dict(device_name=device_name)
        endpoint = app.config['server']['endpoints']['devices']
        url      = app.config['server']['url'] + endpoint

        log.info('Registering at: ' + url)

        # Make REST call to main server
        # and capture the response
        data = rest_call(url, data)

        log.info("Response from server: " + str(data))

        # Read in the device_id and last_record_time
        # from the response from the HTTP request
        device_id        = data['device_id']
        last_record_time = data['last_record_time']

    # If any sort of error was thrown
    # consider the registration a
    # failure and that the device
    # was not properly registered with server
    except:
        log.error(str(sys.exc_info()))
        device_id        = None
        last_record_time = None

    if device_id:
        log.info('Device successfully assigned id: ' + str(device_id))

    # TODO - Check that last_record_time is not null

    return device_id, last_record_time

#-------------------------------------------------------------------------------

# Records temperature to
# local sqlite3 database
def record_temperature():
    success = False

    log.info("Recording current temperature")

    try:
        # Create record
        record = {
            "record_time": strftime("%Y-%m-%d %H:%M:%S", gmtime()),
            "temperature": sensor.get_temperature()
        }

        log.info('Inserting record: ' + str(record))

        # Insert record into SQLite3 database
        db.insert_temperature(record)

        success = True

        log.info('Record successfully written')
    except:
        log.error('Record was not successfully written to database')
        log.error(str(sys.exc_info()))

    return success

#-------------------------------------------------------------------------------

# Sends temperature data back to main server
def send_temperature(device_id):
    success = False

    log.info('Preparing to send data back to main server')

    # Convert from tuple to string
    # TODO - Get this data from the server, don't store
    # it locally. Because if the database goes down
    # all of the data older than the record on this
    # device will never be send back to the main server
    # But for now this works.
    last_record_time = db.get_last_backup()[0][0]

    # Get all records from the database that occur
    # after the last record_time in the sqlite database
    records = get_temperature(last_record_time)

    # Build the payload
    payload = {
        'device_id': device_id,
        'data': records
    }

    log.info("Sending " + str(len(records)) + " record(s) to server")

    # Make REST call to main server
    try:
        # Build connection string
        endpoint = app.config['server']['endpoints']['temperature']
        url      = app.config['server']['url'] + endpoint

        log.info("Sending temperature data to url:" + url)

        # Make REST call and store the device_id
        data = rest_call(url, data)

        # Store the the most recent record_time that the server
        # has for this device. That way, the next time we send,
        # we only send records newer than this one.
        success = db.update_last_backup(data['last_record_time'])

        if success:
            log.info("Successfully send " + str(len(records)) + " record(s) to server")

    except:
        log.info("Failed to send " + str(len(records)) + " record(s) to server")
        log.error(str(sys.exc_info()))

    return success;

#-------------------------------------------------------------------------------

# By default returns the 500 most recent
# temperature recordings. An optional parameted
# record_time will limit the records to all records
# newer than a specified record_time. This function
# is for data to be send back to the browser to be
# plotted in a graph / chart.
def get_temperature(record_time=None):
    records = []

    # TODO - Exception handling
    rows = db.get_temperature(record_time)

    # For each row (which will be a tuple)
    # create a dictionary (JSON object) with
    # the appropriate data field. This JSON
    # data will eventually be sent back to the
    # client over an HTTP connection.
    for r in rows:
        records.append({
            "record_time":r[0],
            "temperature":r[1]
        })

    return records
