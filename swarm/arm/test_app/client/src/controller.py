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

# Set up logger for logging to console and / or log file
log = logging.getLogger(app.config['app']['name'])

#-------------------------------------------------------------------------------

# Makes a REST call to a specified
# URL. Currently only supports POST requests as
# that is all that is required by this application.
def rest_call(url, payload=None, method='POST'):
    success       = False
    response_data = None

    try:
        # A non-null url and payload must be passed to this function
        if url is not None and payload is not None and method is 'POST':
            log.info("HTTP POST to url: " + url)

            # Make REST call to main server
            # and capture the response
            response      = requests.post(url=url, json=payload)
            response_data = json.loads(response.text)

            log.info("Response from server: " + str(response_data))

        # Consider it an invalid HTTP method
        else:
            log.info('Invalid arguments were passed to this function')
            raise ValueError("Only HTTP POST method with a non-None body is currently supported")

        # If we made it this far,
        # the REST call was successful
        success = True

    # Catch exceptions and handle them. If any error was thrown, by convention
    # the response is nullified and we return a None object instead.
    # We can then simply check for None object types in the calling function
    # to verify the success of this function. We also want to catch
    # ConnectionErrors. This happens when there is an issue connecting
    # to the main server. For example, if the domain cannot be resolved
    # or the main server's API is down, a ConnectionError will be throw in this app.
    except (ValueError, requests.exceptions.ConnectionError) as error:
        log.error(error)
        response_data = None

    return response_data

#-------------------------------------------------------------------------------

# Initializes the device
# by setting up the local database. We
# call the function that creates the
# appropriate tables in the sqlite file.
def initialize_database(last_record_time):
    success = False

    try:
        log.info('Initializing sqlite3 database')

        # Records is a throwaway variable that would contain records from
        # the database if we were executing a SELECT statement. However,
        # in this case, there is no return value from creating tables, so
        # all that we care about is whether or not creating the tables was successful.
        records, success = db.create_temperature_database(last_record_time)

        # Throw an Exception if creating
        # the local database was unsuccessful.
        if not success:
            raise ValueError("Could not properly initilize sqlite3 database")

    except ValueError as error:
        log.error(error)

    # Create the database
    return success

#-------------------------------------------------------------------------------

# Registers this device with the main server
# by sending this device's name (MAC address), and obtaining
# a uniqie device_id number. This device will use
# its assigned device_id in the future when sending
# data back to the main server.
def register_device(device_name):
    device_id        = None
    last_record_time = None

    # Make REST call to main server
    try:
        log.info('Registering this device with the name: ' + device_name)

        # Prepare contents of HTTP request
        data     = dict(device_name=device_name)
        endpoint = app.config['server']['endpoints']['devices']
        url      = app.config['server']['url'] + endpoint

        log.info('Registering this device under the name ' + device_name + ' at: ' + url)

        # Make REST call to main server
        # and capture the response
        resp = rest_call(url, data)

        log.info("Response from server: " + str(resp))

        # If we got None back, we consider
        # this a failed registration.
        if not resp:
            raise ValueError("The server did not return proper response, response is None")

        # If something other than None came back,
        # read in the device_id and last_record_time
        # from the response from the HTTP request
        device_id        = resp['device_id']
        last_record_time = resp['last_record_time']

        # If we are at this point, andthe device_id
        # and last_record_time came back from the server
        # successfully, we can consider the registration
        # successful on the client side.
        if device_id:
            log.info('Device successfully assigned id: ' + str(device_id))

        # TODO - Check that last_record_time is not null

    # If any sort of error was thrown
    # consider the registration a
    # failure and that the device
    # was not properly registered with server
    except (TypeError, ValueError) as error:
        log.error(error)
        device_id        = None
        last_record_time = None

    # Return the device_id that was assigned to this
    # device as well as the last_record_time. The
    # last_record_time will be stored into the local
    # database so that the first time this device
    # sends data back to the main server, it will send
    # data newer than the timestamp last_record_time.
    # By convertion, upon new registration the last_record_time
    # is a timestamp that occured in 1970. So, assuming that this
    # device has the correct GMT time, everything in the database
    # will be sent back to the main server. Moving forward, the
    # last_record_time will be constantly updated so that
    # this device does not continuously send data that this device
    # has already sent back to the main server - only new data.
    return device_id, last_record_time

#-------------------------------------------------------------------------------

# Records temperature to
# local sqlite3 database
def record_temperature():
    success=False

    try:
        log.info("Recording current temperature")

        # Poll the 'temperature sensor'
        temperature = sensor.get_temperature()

        # Create record
        record = {
            "record_time": strftime("%Y-%m-%d %H:%M:%S", gmtime()),
            "temperature": temperature
        }

        log.info('Inserting record: ' + str(record))

        # Insert record into SQLite3 database
        db.insert_temperature(record)

        log.info('Record successfully written')

        success = True

    # TODO - Catch specific type of errors?
    except:
        log.error('Record was not successfully written to database')
        log.error(str(sys.exc_info()))

    return success

#-------------------------------------------------------------------------------

# Sends temperature data back to main server
def send_temperature(device_id):
    success=False
    records=[]

    # Make REST call to main server
    try:
        log.info('Preparing to send data back to main server')
        log.info('Getting last_record_time from local databse')

        # Convert from tuple to string
        # TODO - Get this data from the server, don't store
        # it locally. Because if the database goes down
        # all of the data older than the record on this
        # device will never be send back to the main server
        # But for now this works.
        #  NOTE - Maybe it is better to keep updating the
        # local database because if we store this value at
        # runtime, we may run to issues since this value is
        # being written on a different thread than the thread
        # that is reading it.
        records, success = db.get_last_backup()

        # If that step did not succeed,
        # then we should not continue.
        if not success:
            raise ValueError("Retrieving last_record_time from local database failed")

        # Get the first value from first record
        # (whic is the last_record_time)
        last_record_time = records[0][0]

        log.info("Getting all records recorded after last_record_time: " + last_record_time)

        # Get all records from the database that occur
        # after the last record_time in the sqlite database
        records, s = get_temperature(last_record_time)

        # The success of this function depends
        # on the success of the intermediate
        # steps' success 's'.
        success = success and s

        # If that step did not succeed,
        # then we should not continue.
        if not success:
            raise ValueError("Retrieving records from local database failed")

        # Build the payload
        payload = {
            'device_id': device_id,
            'data': records
        }

        log.info("Sending " + str(len(records)) + " record(s) to server")

        # Build connection string
        endpoint = app.config['server']['endpoints']['temperature']
        url      = app.config['server']['url'] + endpoint

        log.info("Sending temperature data to url:" + url)

        # Make REST call and store the device_id
        resp = rest_call(url, payload)

        # Make sure that resp is not a None object
        if not resp:
            raise ValueError("REST call returned None, it is likely the server is not reachable")

        # Store the the most recent record_time that the server
        # has for this device. That way, the next time we send,
        # we only send records newer than this one.
        r, success = db.update_last_backup(resp['last_record_time'])

        # If we made it this far
        # sending data back to the
        # main server was successful
        if success:
            log.info("Successfully sent " + str(len(records)) + " record(s) to server")
            success = True

        # If for whatever reason the response from
        # the update_last_backup() call was false,
        # but an Exception wasn't thrown, we consider
        # this to be a failure. TODO - Should we raise
        # a ValueError?
        else:
            log.info("Failed to sent " + str(len(records)) + " record(s) to server")

    # We anticipate these types of errors
    except (ValueError, TypeError) as error:
        log.error(error)

    # This catches any other type of error
    # that we did not anticipate
    except:
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
    success = False

    # TODO - Exception handling
    rows, success = db.get_temperature(record_time)

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

    return records, success
