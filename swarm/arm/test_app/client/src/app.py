# Task scheduling
from apscheduler.schedulers.background import BackgroundScheduler

# Exception handling
import sys

# REST API and serving files / webpage to browser
from flask import Flask, jsonify, request
import redis

# Logging
import logging
from logging.handlers import RotatingFileHandler

# Interfacing with the local database
import controller

# Reading in the config file
# and command line arguments
import json
import argparse

#-------------------------------------------------------------------------------

# Dictionary of exit codes for exiting the
# program on different errors. If the program
# had more potential exit conditions, expanding
# this dictionary may be useful.
exit_codes = {
    'success'           : 0,
    'no_config'         : 1,
    'not_registered'    : 2,
    'no_local_database' : 3
}

# We will set the config object to null
# by default. If we read the config file
# in correctly, it should not be null after
# the following code block.
config = None

# Read in config file
try:
    with open('config/config.json') as json_data:
        config = json.load(json_data)
except:
    # Print error message to console
    # and exit with the appropriate exit code
    print(str(sys.exc_info()))
    sys.exit(exit_codes['no_config'])

# If its still null, exit
if (not config):
    print("Could not read config file")
    sys.exit(exit_codes['no_config'])

# The device_id will be a numeric value that will
# be assigned to this device by the main
# server. By default it is null. If the device_id
# is not properly recieved from the main server,
# execution will terminate.
device_id = None

# We only continue if we successfully read in the config file.
# Read in the intervals for recording temperature
# and sending it back to the main server (in seconds)
# This is how frequently the device will poll its sensor
# and how frequently it will send data back to the main server.
# These are separate intervals, and the send_interval
# should be less than the record interval. Otherwise there
# will be unnecesarily large number of outgoing requests
# with little to zero data.
record_interval = config['app']['record_interval']
send_interval   = config['app']['send_interval']

# Initialize the Flask application
# This is the main app that will be
# listening to request on this device
# and hosting the main web page.
app   = Flask(config['app']['name'])
cache = redis.Redis(host='redis', port=6379)

#-------------------------------------------------------------------------------

# We are routing the root path
# to the index.html file. So if the ip
# address of this device is entered into
# the browser, the index.html file will be served.
@app.route('/')
def root():
    return app.send_static_file('index.html')

#-------------------------------------------------------------------------------

# Sends any static file from the
# folder /static. This is so that
# when the index.html gets rendered,
# the scripts and stylesheets can also
# be loaded in the browser.
# We do this by simply matching the path
# that the client requested in the browser
# with a path in the /static directory
@app.route('/<path:path>')
def static_proxy(path):

  # send_static_file will guess the correct MIME type.
  # This is useful because .css will be recieved as .css
  # and .js will be recieved as .js. We should not have
  # an issue rendering the index.html file.
  return app.send_static_file(path)

#-------------------------------------------------------------------------------

# This is a REST endpoint that will send
# the most recent temperature sensor
# readings. This will be used to display
# in a chart in the index.html file.
@app.route('/temperature')
def temperature():

    return jsonify(
        device_id   = device_id,
        device_name = device_name,
        data        = controller.get_temperature()
    )

# PROGRAM STARTS HERE
#-------------------------------------------------------------------------------

if __name__ == "__main__":

    # This is the object that will parse
    # the arguments entered via command line
    parser = argparse.ArgumentParser()

    # A MAC Address must be provided for this app to run. It will be
    # used as the unique identifier for each device when the data is
    # compiled into one central location on the main server
    # NOTE - MAC address is not read in dynamically by python because when this application
    # is deployed in a docker container (virtual environment), the MAC address will be null
    # because it is not a physical device. If we were to use hostname, then
    # we cannot insure uniqueness between the clients running this app. Furthermore,
    # running this app in Docker makes the hostname come back different for every new container,
    # even though it is running on the same physical device. For this purpose,
    # MAC address is a required command line argument that will be read in from the host machine.
    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument('--mac-address', help='MAC Address of the device', required=True)

    # Parse the command line arguments. Right now
    # we are only expecting the mac-address.
    args = parser.parse_args()

    # Set the device name equal to the
    # MAC address of this device. We will use
    # this as as a unique identifier between
    # different devices that are sending data
    # to the same main server.
    device_name = args.mac_address

    # Initialize the log handler
    # Set the log handler level
    # TODO - Fix logging to file to make it
    # stop making two different log files

    # logHandler = RotatingFileHandler('info.log', maxBytes=1000, backupCount=1)
    # logHandler.setLevel(logging.INFO)
    # app.logger.addHandler(logHandler)

    # Set the app logger level and format. We want datetime,
    # as well as the filename and line of code that the error
    # message is printed on. This makes debugging easier.
    formatter = logging.Formatter(
        "[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s"
    )

    # Set up the logHandler to log to standard output
    logHandler = logging.StreamHandler(sys.stdout)
    logHandler.setLevel(logging.INFO)
    logHandler.setFormatter(formatter)

    # Add log handled to Flask app
    app.logger.setLevel(logging.INFO)
    app.logger.addHandler(logHandler)

    # Initialize this device by registering
    # it and creating a local database.
    # Exit the program if either step fails. We do not want
    # to start recording data if we are
    # not registered with the main server or our local database
    # is not properly accesible.
    device_id, last_record_time = controller.register_device(device_name)

    # Make sure we got a device_id and
    # last_record_time time from the main server.
    # If not, exit the program because if we do
    # not have a device_id, there is no way for the
    # main server to associate records with this
    # device. If we did not get a last_record_time
    # back, then this device has no idea as to how
    # much data it should send to main server.
    # We need both, otherwise immediately terminate execution.
    if not device_id or not last_record_time:
        app.logger.error('Could not register device with main server')
        sys.exit(exit_codes['not_registered'])

    # Once we know that we have a place in the main server,
    # we will initialize our local database. If this fails,
    # we must immediately terminate execution because we have
    # no way of properly keeping data before it is sent to main server.
    if not controller.initialize_database(last_record_time):
        app.logger.error('Could not initialize local database')
        sys.exit(exit_codes['no_local_database'])

    # Once we are properly setup with a local
    # database and are registered with the main server,
    # set up scheduled function calls
    # to periodically record data locally and
    # a separate interval to send it back to main server.
    # NOTE - These functions are called on
    # different threads of execution than the main thread. So, for
    # objects such as sqlite3 objects, a new
    # database connection must be made per function call
    # because sqlite3 objects can only be used by the thread
    # that created it. For small intervals (milliseconds),
    # this may be expensive as there is an overhead
    # associated with each database connection.
    # After all, sqlite3 opens the file each time. However, for
    # large intervals (seconds), the overhead is not noticeable.
    scheduler = BackgroundScheduler(timezone='America/New_York')
    scheduler.add_job(controller.record_temperature, 'interval', seconds=record_interval)
    scheduler.add_job(controller.send_temperature, 'interval', kwargs={"device_id":device_id}, seconds=send_interval)
    scheduler.start()

    # Now that our local database has been created
    # and we have successfully registered this device with
    # the main server and we are polling data locally, launch the REST application. This will
    # allow clients to consume the local API running on this device, as well
    # as the Flask application will server a webpage that allows visualitation.
    # NOTE - The next line will keep running until the python process has been killed.
    # So the line of code that follows it will not be executed until the flask app stops running.
    # By default the API will be running on port 5000.
    app.run(host="0.0.0.0", debug=True, use_reloader=False)

    # If the main flask application has been killed, we want
    # to kill the scheduler. This is a multithreaded
    # application and we want to destroy all residual threads
    # so that they do not continue to be triggered in the background
    scheduler.shutdown()

    # Close the program with the
    # success exit code.
    sys.exit(exit_codes['success'])
