import app
import db
import sys
import sensor
import configparser
import logging
import json
import requests
from time import gmtime, strftime

#-------------------------------------------------------------------------------

# Set up logger
log = logging.getLogger(app.config['app']['name'])

#-------------------------------------------------------------------------------

# Initializes the device
# by setting up the database
# and registering with the server
def initialize_database(last_record_time):
    log.info('Initializing device')

    # TODO - Exception handling

    # Create the datbase, and register with main server
    return db.create_temperature_database(last_record_time)

#-------------------------------------------------------------------------------

# Registers this device with the main server
def register_device(device_name):
    device_id = None

    log.info('Registering device: ' + device_name)

    # Make REST call to main server
    try:
        data     = dict(device_name=device_name)
        endpoint = app.config['server']['endpoints']['devices']
        url      = app.config['server']['url'] + endpoint

        log.info('Registering at: ' + url)

        # Make REST call and store the device_id
        resp = requests.post(url=url, json=data)
        data = json.loads(resp.text)

        log.info("response: " + str(data))

        device_id = data['device_id']

    except:
        log.error(str(sys.exc_info()))
        device_id = None

    # REST call to API
    # to register the device
    # with the main server
    if device_id:
        log.info('Device successfully assign id: ' + str(device_id))

    return device_id, data['last_record_time']

#-------------------------------------------------------------------------------

# Records temperature to
# local database
def record_temperature():
    success = False

    try:
        # Create record
        record = {
            "record_time": strftime("%Y-%m-%d %H:%M:%S", gmtime()),
            "temperature": sensor.get_temperature()
        }

        log.info('Inserting record')
        db.insert_temperature(record)

        success = True
    except:
        log.error('Error: ' + str(sys.exc_info()))

    return success

#-------------------------------------------------------------------------------

# Sends temperature back to main server
def send_temperature(device_id):
    success = False

    # Build connection string
    url      = app.config['server']['url']
    endpoint = app.config['server']['endpoints']['temperature']
    url      = url + endpoint

    log.info("Sending temperature to " + url)

    # Convert from tuple to string
    # TODO - Get this data from the server, don't store
    # it locally. Because if the database goes down
    # all of the data older than the record on this
    # device will never be send back to the main server
    # But for now this works.
    record_time = db.get_last_backup()[0][0]

    payload = {
        'device_id': device_id,
        'data': get_temperature(record_time)
    }

    # Make REST call to main server
    try:
        endpoint = app.config['server']['endpoints']['temperature']
        url      = app.config['server']['url'] + endpoint

        # Make REST call and store the device_id
        resp = requests.post(url=url, json=payload)
        data = json.loads(resp.text)

        log.info(data)

        # Store the the most recent record_time that the server
        # has for this device. That way, the next time we send,
        # we only send records newer than this one.
        success = db.update_last_backup(data['last_record_time'])

    except:
        log.error(str(sys.exc_info()))

    return success;

#-------------------------------------------------------------------------------

# Get's the most recent temperature
# data for displaying in web page
def get_temperature(record_time=None):
    records = []
    rows = db.get_temperature(record_time)

    # Create dictionaries from the rows
    for r in rows:
        records.append({
            "record_time":r[0],
            "temperature":r[1]
        })

    return records
