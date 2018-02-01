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

# Set up logger
log = logging.getLogger(app.config['app']['name'])

#-------------------------------------------------------------------------------

# Executes a SQL query. This function supports
# both SELECT and INSERT / UPDATE methods.
def execute_query(query, fetchall=False):
    records = None

    # TODO - Exception handling, perhaps also
    # return a boolean to indicate if the query
    # was successfully executed or not

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
    # fetch the result from query
    # and store it in records variable
    if fetchall:
        records = c.fetchall()

    # Close the collection
    conn.close()

    # Return any records
    # that were fetched
    return records

#-------------------------------------------------------------------------------

# Initializes the temperature database. If the database
# folder is not present, we will create that directory.
# The file will authomatically be created if it does not
# exists. We then check if the database file has the appropriate
# tables. If it does not, we will create them ourselves.
def create_temperature_database(last_record_time):
    success = False

    try:
        # If the database directory does not exist, make it
        if not os.path.exists(app.config['database']['path']):

            log.info(app.config['database']['path'] + ' does not exits, creating it...')
            os.makedirs(app.config['database']['path'])

        # Connect to database
        log.info('Connecting to sqlite3 databse :' + app.config['database']['name'])
        log.info('Creating tables if it they do not exist alrdy')

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

        # Put the queries in a list
        queries=[query1, query2, query3, query4]

        # Execute each query
        for query in queries:
            execute_query(query)

        log.info('Tables successfully created')

        success = True

    except:
        log.error('Could not initilize database')
        log.error(str(sys.exc_info()))

    return success

#-------------------------------------------------------------------------------

# Write the timestamp to the local database
# that represents the last_record_time that
# the main server has confirmed saved for this device.
def update_last_backup(record_time):
    query = "REPLACE INTO last_backup VALUES(\'" + record_time + "\');"

    execute_query(query)

    return True

#-------------------------------------------------------------------------------

# Reads the local database for the timestamp
# that represents the latests record_time that the
# main server has for this device. All records
# that occur after this timestamp will be sent
# back to the main server the next time this device phones home.
def get_last_backup():
    records = []

    query = "SELECT * FROM last_backup LIMIT 1"

    records = execute_query(query, fetchall=True)

    return records

#-------------------------------------------------------------------------------

# Inserts a temperature recording
# into local sqlite3 database
def insert_temperature(record):

    # Build query
    query=('INSERT ' + 'INTO temperature(' +
          "record_time," +
          "temperature)" +
          "VALUES(" +
          "\'" + record['record_time'] + '\',' +
          str(record['temperature'])) + ")"

    execute_query(query)

    return True

#-------------------------------------------------------------------------------

# Gets last 500 records from the local database.
# This data will be displayed in the browser.
def get_temperature(record_time=None):

    # Build query
    query=("SELECT * FROM " +
           "(SELECT * FROM temperature " +
           "ORDER BY record_time DESC " +
           "LIMIT 500) T1 " +
           "ORDER BY record_time;")

    # We want to only get records newer that
    # this record time
    if record_time:
        query=("SELECT * FROM temperature " +
               "WHERE record_time > Datetime(\'" + record_time + "\');")

    return execute_query(query, fetchall=True)
