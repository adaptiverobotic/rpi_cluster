// EXPRESS
var config     = require('./config/config.json');
var controller = require('./controller')
var db         = require('./db');
var bodyParser = require('body-parser');
var express    = require('express');
var path       = require('path');
var app        = express();
var api        = config.api;

// Check that the database is in order
//------------------------------------------------------------------------------

// Make sure that the database is accessible
// and has the appropriate tables that
// are required by this API.
controller.databaseInitialized(() => process.exit(1030));

// Set up REST application to automatically parse HTTP bodies into JSON objects
// and allow cross origin support from any domain name
//------------------------------------------------------------------------------

// Parse application/x-www-form-urlencoded and json
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Serve index.html from the directory named 'static'
app.use(express.static(path.join(__dirname, 'static')), function(req, res, next) {

    // Allow cross origin from any host
    res.setHeader('Access-Control-Allow-Origin', '*');

    next();
});

// Set up routes for REST endpoints
//------------------------------------------------------------------------------

// Set up temperature data endpoints
app.get(api.endpoints.temperature, controller.getAllData);
app.post(api.endpoints.temperature, controller.insertData);

// Set up device endpoints
app.get(api.endpoints.devices, controller.getAllDevices);
app.post(api.endpoints.devices, controller.registerDevice);

// Start the REST application
//------------------------------------------------------------------------------

// Listen on specified port
app.listen(api.port);
