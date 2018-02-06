let promise  = require('bluebird');
let options  = {promiseLib: promise};
let pgp      = require('pg-promise')(options);
let config   = require('./config/config.json');
let postgres = config.postgres;
let db       = pgp(connectionString());
let tables   = postgres.database.tables;
let types    = pgp.pg.types;

// Do not format dates, read them as is
types.setTypeParser(1114, str => str);

//------------------------------------------------------------------------------

/**
 * Returns the PostgreSQL connection string.
 */
function connectionString() {
  return 'postgres://' +
          postgres.user + ":" +
          postgres.password + "@" +
          postgres.hostname + ":" +
          postgres.port + "/" +
          postgres.database.name;
}

//------------------------------------------------------------------------------

/**
 * Executes an SQL query.
 */
function executeQuery(query, success, error) {
  db.any(query)
    .then((data) => {
      success(data);
    })
    .catch((err) => {
      error(err);
    });
}

//------------------------------------------------------------------------------

/**
 * Creates a new record in the devices table
 * for a specified unique device_name.
 */
function registerDevice(device_name, success, error) {

  // Insert device name then get the id generated
  let query = "INSERT INTO devices (device_name) " +
              "VALUES " + "(\'" + device_name + "\');" + "\n" +
              "SELECT * FROM devices " +
              "WHERE device_name = '" + device_name +  "';"

  console.log("Registering device by device_name: " + device_name);

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns all records from the devices table.
 */
function getAllDevices(success, error) {
  let query = "SELECT * FROM devices;";

  console.log("Getting all devices");

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns the record from the devices table that is
 * associated with a given device_id.
 */
function getDeviceById(device_id, success, error) {
  let query = "SELECT * FROM devices " +
              "WHERE device_id = " + device_id;

  console.log("Getting device by device_id: " + device_id)

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns the record from the devices table that is
 * associated with a given device_name.
 */
function getDeviceByName(device_name, success, error) {
  let query = "SELECT * FROM devices " +
              "WHERE device_name = '" + device_name + "';";

  console.log("Getting device by device_name: " + device_name);

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns N records associated with a specified device_id.
 */
function getAllData(device_id, num_records, success, error) {

  // TODO - Reverse the order
  var query = 'SELECT * ' +
               'FROM temperature ' +
               'WHERE device_id = ' + device_id + " " +
               'ORDER BY record_time DESC LIMIT ' + num_records;

  console.log("Getting temperature data for device: " + device_id);

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Inserts N temperature recordings into
 * the database.
 */
function insertData(body, success, error) {
  let data      = body.data;
  let device_id = body.device_id;
  let query     = 'INSERT INTO temperature VALUES';

  // Build query
  // Query takes the form:
  //
  // INSERT INTO temperature VALUES
  // VALUES(v0, v1, v2)
  // VALUES(v0, v1, v2)
  // VALUES(v0, v1, v2)
  // ...
  for (let i = 0; i < data.length; i++) {
    query += "(" +
             device_id + ',' +
             data[i].temperature + ',' +
             "\'" + data[i].record_time + "\')";

    // Append commas to all but the last
    if (i != data.length-1) {
      query += ','
    } else {
      query += ';\n'
    }
  }

  query += "SELECT * FROM devices WHERE device_id=" + device_id + " LIMIT 1";

  console.log("Inserting " + data.length + ' record(s) from device_id: ' + device_id);

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Gets the last temperature recording
 * that is associated with a provided device_id.
 */
function getMostRecentRecordData(device_id, success, error) {

  console.log("Getting most recent record for device: " + device_id);

  // Get max record that's associated
  // with the provided device_id
  var query = "SELECT * FROM temperature "+
              "WHERE record_time IN " +
              "(SELECT MAX(record_time) FROM temperature " +
              "WHERE device_id =" + device_id + ") LIMIT 1;"

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

/**
 * Check that the database has the tables that
 * we need for this API to properly function.
 */
function checkForTables(success, error) {

  // We want to select the records that correspond
  // to the tables that  we need for this API.
  let query = "SELECT * FROM pg_tables " +
              "WHERE tablename='devices' " +
              "OR tablename='temperature';";

  console.log("Checking that tables 'temperature' and 'devices' exist");

  executeQuery(query, success, error);
}

//------------------------------------------------------------------------------

// Expose these functions
module.exports = {
  getDeviceByName         : getDeviceByName,
  registerDevice          : registerDevice,
  getAllDevices           : getAllDevices,
  getAllData              : getAllData,
  insertData              : insertData,
  getMostRecentRecordData : getMostRecentRecordData,
  checkForTables          : checkForTables
};
