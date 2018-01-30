var db = require('./db');

//------------------------------------------------------------------------------

/**
 * Registers a device in database.
 */
function registerDevice(req, res, next) {

  // Get the device's name to send to database
  var device_name = req.body.device_name;

  // Function that is called upon success
  let success = function (data) {
    console.log("Device " + device_name + " was assigned id " + data[0].device_id);

    res.status(201).send(data[0]);
  }

  // Function that is called upon error
  let error = function(err) {

    // If it already exists in database
    // then get it's associated record
    if (err.code === '23505') {
      console.error("Device already registered");

      // Go get the record that is associated
      // with this device name
      db.getDeviceByName(device_name, success, error);

    // Otherwise, send back
    // an error message
    } else {
      let message = "Could not register device: " +
                      req.body.device_name + "\n"
                      err.detail;

      let response = {
        message : message
      }

      console.error(err);

      res.status(400).send(response);
    }
  }

  // Register the device by name
  db.registerDevice(device_name, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns all device records.
 */
function getAllDevices(req, res, next) {

  // Function that's called upon success
  var success = function(data) {
    console.log("Success: " + data);

    res.status(200).send(data);
  }

  // If the user requested
  // a specifiec device
  if (req.query.device_id) {

    // Function that's called upon error
    let error = function(err) {
      var message = "Device: " + req.query.device_id +" not found\n" + err.detail;

      res.status(400).send({message:message});
    }

    db.getDeviceById(success, error);

  // Otherwise, return
  // all of the devices
  } else {

    // Function that's called upon error
    let error = function(err) {
      console.error("Could not get devices, an error occured");
      console.error(err.detail);

      res.status(200).send([]);
    }

    db.getAllDevices(success, error);
  }
}

//------------------------------------------------------------------------------

/**
 * Returns the record associated with a device_name.
 */
function getDeviceByName(req, res, next) {
  var device_name = "";

  // Can get device via POST or GET
  if (req.method === 'POST') {
    device_name = req.body.device_name;
  } else {
    device_name = req.query.device_name;
  }

  // Function that's called upon success
  let success = function (data) {
    res.status(200).send(data);
  }

  // Function that's called upon error
  let error = function (err) {
    var message = "Device: " + device_name + " not found\n" + err.detail;

    res.status(404).send({message:message});
  }

  db.getDeviceByName(device_name, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns all data from database in data table.
 */
function getAllData(req, res, next) {
  // If we only want the most recent
  // use a different query
  if (req.query.num_records == 1) {
    return db.getMostRecentRecordData(req, res, next);
  }

  let success = function (data) {

    // NOTE - Temporary fix
    data.reverse();

    let response = {
      message: "message",
      device_id: req.query.device_id,
      data: data
    }

    res.status(200).send(response);
  }

  let error = function (err) {
    let message = "Could not get data for device: " + req.query.device_id;
    console.error(message);
    console.error(err);

    let response = {
      message: message,
      device_id: req.query.device_id,
      data: []
    }

    res.status(200).send(response);
  }

  db.getAllData(req.query.device_id,
                req.query.num_records,
                success,
                error
  );
}

//------------------------------------------------------------------------------

/**
 * Insert a random number between some range into database.
 */
function insertData(req, res, next) {

  if (req.body.data.length < 1) {
    res.status(400).send({
      "message": "Must send at least one record"
    })

    return;
  }

  let success = function(data) {
    let message = "Successfully inserted " + req.body.data.length + ' record(s)';

    res.status(200).send(data[0]);
  }

  let error = function(err) {
    let sql_message = '';
    let message = "Failed to insert data";

    if (err.detail) {
      sql_message = err.detail;
    }

    let response = {
      message : message,
      sql_message : sql_message,
      hint: "Make sure your data is in the form: [{" +
            "temperature: %Y-%m-%d %H:%M:%S, " +
            "record_time: 123}]"
    }

    console.error("Failed to insert records");
    console.error(err)

    res.status(400).send(response);
  }

  db.insertData(req.body, success, error);
}

//------------------------------------------------------------------------------

/**
 * Returns the last record data of a given
 * device. This is used so that the client
 * knows that it only needs to send data after
 * this data the next time it phones home to this server.
 */
function getMostRecentRecordData(req, res, next) {

  let success = function (data) {
    console.log("Success: " + JSON.stringify(data));

    res.status(200).send({"record_data":data});
  }

  let error = function (err) {
    var message = err.detail

    res.status(404).send({message:message});
  }

  getMostRecentRecordData(req.query.device_id, success, error);
}

//------------------------------------------------------------------------------

/**
 * Ensures that the API can communicate with
 * the PostgreSQL database. We use this function
 * before we start trying to insert and get data.
 */
function databaseInitialized(error) {

  db.checkForTables(function(data) {
    var valid = false;

    // We should get exactly 2 records back.
    // Make sure that one corresponds to the 'devices'
    // table, and the other corresponds to the
    // 'temperature table.'
    if (data.length == 2) {
      let devices     = data[0].tablename == 'devices' || data[0].tablename == 'devices' ||
                        data[0].tablename == 'temperature' || data[0].tablename == 'temperature';

      let temperature = data[1].tablename == 'devices' || data[1].tablename == 'devices' ||
                        data[1].tablename == 'temperature' || data[1].tablename ==' temperature';

      if (!devices) {
        console.error("Table 'devices' not found");
      }

      if (!temperature) {
        console.error("Table 'temperature' not found");
      }

      // Both should have come back true
      valid = devices && temperature;
    }

    // If the tables that we need are not
    // present. We will exit the process.
    // We will not accept data to write to
    // a database that does not exist.
    if (!valid) {
      console.log("Database does not have the proper schema");
      error();
    }

    // If we got this far, then we are in good shape.
    // Print to console that we are good. Nothing else to do.
    console.log("Success: Database has tables 'devices' and 'temperature'");

  // If an error occured, we exit. This means
  // we could not verify that the database is
  // in the state that we need it for the API.
  }, function(err) {

    console.error("Could not verify that database has the proper schema");
    console.error(err)
    error();
  });
}

//------------------------------------------------------------------------------

// Expose these functions
module.exports = {
  registerDevice          : registerDevice,
  getAllDevices           : getAllDevices,
  getDeviceByName         : getDeviceByName,
  getAllData              : getAllData,
  insertData              : insertData,
  databaseInitialized     : databaseInitialized,
  getMostRecentRecordData : getMostRecentRecordData
};
