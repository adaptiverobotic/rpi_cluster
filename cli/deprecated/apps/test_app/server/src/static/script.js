
// Get the array of device objects (JSON)
// so that we can later use their device_ids
// to get their associated data for
// populating the charts.
let devices = getDevices();

// This variable keeps track of
// failed attempts to update the charts.
// If failures reaches 3, we stop trying
// and consider our connection to the main
// server lost / down.
let failures = 0;

//------------------------------------------------------------------------------

let device_charts = (function() {
  let array = [];

  // Draw a chart for each device
  for (let i in devices) {
    array.push(drawChart(devices[i]));
  }

  return array;
})();

//------------------------------------------------------------------------------

// Set an interval to periodically
// update the charts every 5 seconds.
let interval = setInterval(() => {
  try {
    updateCharts(device_charts);

    // Reset failure count
    //  after a successful update
    failures = 0;

  } catch (err) {

    // Increment the number of failed
    //  attempts.
    failures++;
    console.error("Could not update chart after " + failures + " attempts");
    console.error(err);

    // If we failed to update the charts
    //  three consecutive times, then we
    //  should consider our connection to
    //  to API as lost, an unregister the
    //  interval so that we do not continue
    //  attempting to connect to the API.
    if (failures === 3) {
      console.error("Connection has been lost");
      unregister();
    }
  }

}, 5000);

//------------------------------------------------------------------------------

/**
 *  Unregisters the interval that periodically
 *  refreshes the data that populates the charts.
 *  This function will be called if the API cannot
 *  be reached after three attempts.
 */
function unregister() {
  clearInterval(interval);
}
