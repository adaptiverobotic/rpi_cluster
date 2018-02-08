# The main app. We import
# this to get access to the
# config file, so ultimately
# we can get access to the logger
import app

# Access to local filesystem
# for checking if the database file's
# directory is created.
import os

# Exception handling
import sys

# Connection to the local
# sqlite3 database
import sqlite3

# Logging to console
import logging

#-------------------------------------------------------------------------------

# Set up logger for logging to console and / or log file
log = logging.getLogger(app.config['app']['name'])

#-------------------------------------------------------------------------------

# Executes a SQL query. This function supports
# both SELECT and INSERT / UPDATE methods.
# It takes an optional parameter fetchall that
# indicates whether or not the query should be
# interpreted as a SELECT or not. If fetchall is
# False (which it is by default) no records will be
# returned. This is the case when the query is an
# INSERT or UPDATE. If we are retrieving records
# from the database, we must set the fetchall flag to True.
def execute_query(query, fetchall=False, script=False):
    records = None
    success = False

    try:
        # Connect to the sqlite database using the name that
        # is specified in the configuration file
        conn = sqlite3.connect(app.config['database']['name'])

        # Log the query
        log.info(query)

        # Execute it
        c = conn.cursor()

        # Single statement
        if not script:
            c.execute(query)

        # Several statements
        else:
            c.executescript(query)

        # Commit any changes
        conn.commit()

        # If its a SELECT statement
        # fetch the result from the query
        # and store it in the records variable
        if fetchall:
            records = c.fetchall()

        # Close the connection
        conn.close()

        # Query execution was
        # successful
        success = True

    # Catches all unanticipated
    # exceptions thrown during loop
    except:
        log.error('Could not execute query because of unexpected error')
        log.error(str(sys.exc_info()))
        success = False

    # Return any records
    # that were fetched and the
    # boolean flag that indicates whether
    # or not the execution was successful.
    return records, success

#-------------------------------------------------------------------------------

# Executes a .sql file (series of queries)
def execute_script(path, fetchall=False):
    records = None
    success = False

    try:

        # Read the schema file in as a string
        query = open(path, 'r').read()

        # Execute it
        records, success = execute_query(query, fetchall, script=True)

    # Catches all unanticipated
    # exceptions thrown during loop
    # TODO - Implement more specific exception handling
    except:
        log.error('Could not execute script because of unexpected error')
        log.error(str(sys.exc_info()))
        success = False

    return records, success

#-------------------------------------------------------------------------------

# Initializes the temperature database. If the database
# folder is not present, we will create that directory.
# The file will authomatically be created if it does not
# exists. We then check if the database file has the appropriate
# tables. If it does not, we will create them ourselves.
def create_temperature_database(last_record_time):
    success = True

    # TODO - Instead of executing these queries as string, read in
    # the schema.sql file as a string, and execute it like that. That
    # way, if the schema is changed, we do not have to update the code as well.

    try:
        # If the database directory does not exist, make it
        if not os.path.exists(app.config['database']['path']):
            log.info(app.config['database']['path'] + ' does not exits, creating it...')
            os.makedirs(app.config['database']['path'])

        # Connect to database
        log.info('Connecting to sqlite3 databse :' + app.config['database']['name'])
        log.info('Creating tables \'temperature\' and \'last_backup\' if it they do not exist alrdy')

        r, s = execute_script(app.config['database']['schema_file'])

        # We want to start keeping track of the last piece of data the main
        # server has for this device.
        query = "REPLACE INTO last_backup VALUES(\'" + last_record_time + "\')"

        # Execute that query too
        r, s2 = execute_query(query)

        # We were successful if and only if
        # both queries succeeded
        success = s and s2


    # We anticipate this error if
    # a given query in the list
    # fails to execute at the
    # execute_query() function call.
    except ValueError as error:
        log.error(error)
        success = False

    # Catches all unanticipated
    # exceptions thrown during loop
    except:
        log.error('Could not initilize database because of unexpected error')
        log.error(str(sys.exc_info()))
        success = False

    return None, success

#-------------------------------------------------------------------------------

# Write the timestamp to the local database
# that represents the last_record_time that
# the main server has confirmed saved for this device.
# We use this value to know which values to select
# the next time we want to send new values to main server.
def update_last_backup(record_time):

    # Build query
    query="REPLACE INTO last_backup VALUES(\'" + record_time + "\');"

    return execute_query(query)

#-------------------------------------------------------------------------------

# Reads the local database for the timestamp
# that represents the latests record_time that the
# main server has for this device. All records
# with timestamps after this timestamp will be sent
# back to the main server the next time this device phones home.
def get_last_backup():

    # Build query
    query = "SELECT * FROM last_backup LIMIT 1"

    return execute_query(query, fetchall=True)

#-------------------------------------------------------------------------------

# Inserts a temperature recording
# into local sqlite3 database
def insert_temperature(record):

    # Build query
    query=('INSERT INTO temperature(' +
          "record_time," +
          "temperature)" +
          "VALUES(" +
          "\'" + record['record_time'] + '\',' +
          str(record['temperature'])) + ")"

    return execute_query(query)

#-------------------------------------------------------------------------------

# Gets last 500 records from the local database.
# This data will be displayed in the browser.
def get_temperature(record_time=None):

    # Build query
    # TODO - Change this becauase after the database
    # has more than 500 Records, will it continue
    # to return new data? or will it always give
    # back the first 500 records?
    query=("SELECT * FROM " +
           "(SELECT * FROM temperature " +
           "ORDER BY record_time DESC " +
           "LIMIT 500) T1 " +
           "ORDER BY record_time;")

    # We want to only get records newer that
    # this record time
    if record_time:
        query=("SELECT * FROM temperature " +
               "WHERE record_time > Datetime(\'" + record_time + "\') LIMIT 500;")

    return execute_query(query, fetchall=True)
