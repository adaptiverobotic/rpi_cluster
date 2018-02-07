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
def execute_query(query, fetchall=False):
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
        c.execute(query)
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

        # Table to store temperature data
        query1=("CREATE TABLE IF NOT EXISTS temperature(" +
               "record_time timestamp without time zone NOT NULL," +
               "temperature decimal NOT NULL);")

        # This table holds exactly one record. It will be updated
        # with the most recent date that the server has for this device.
        # That way, when we periodically send data to the main server,
        # we are only sending the newest data that the server does not
        # already have stored for this device
        query2=("CREATE TABLE IF NOT EXISTS last_backup(" +
                "record_time timestamp without time zone NOT NULL);")

        query3=("CREATE UNIQUE INDEX IF NOT EXISTS last_backup_one_row " +
                "ON last_backup((record_time IS NOT NULL));")

        # The last_record_time is a value that we got from the main database. That way
        # next time, we only send data that the main server's database does not have yet.
        # TODO - Perhaps ensure that the value that we are replacing is always less
        # than the current value that's there. That way we cannot 'skip' ahead in
        # time and accidently have 'gaps' in our records
        query4=("REPLACE INTO last_backup VALUES(\'" + last_record_time + "\')")

        # Put the queries in a list that we will
        # execute one by one.
        queries=[query1, query2, query3, query4]

        # Execute each query
        for query in queries:
            # r and s are temporary values
            # for the records and success values
            # that are returned by the execute_query()
            # function. As all of these queries do not
            # request any data back from the database, r
            # is a throwaway variable. We only care about s
            # because it indicated whether or not
            # the query was executed successfully or not.
            r, s = execute_query(query)

            # Keep 'AND-ing' the success
            # of each query that is executed.
            # If one comes back False, then the
            # overall success of this function is False.
            success = success and s

            # If at any point success goes false, then the last
            # query that got executed failed. We should not
            # continue executing subsequent queries if a given
            # query fails. Immediately throw an Exception.
            if not success:
                log.info('Query was not executed successfully')
                raise ValueError('Unsuccessful query: ' + query)

        # If we have gotten this far, then executing each
        # query was successfully executed.
        log.info('Tables \'temperature\' and \'last_backup\' were successfully created')

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
