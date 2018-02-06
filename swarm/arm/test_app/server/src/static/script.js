var devices = getDevices();
var failures = 0;

//------------------------------------------------------------------------------

let device_charts = (function() {
  let array = [];

  // Draw a chart for each device
  for (i in devices) {
    array.push(drawChart(devices[i]));
  }

  return array;
})();

//------------------------------------------------------------------------------

var interval = setInterval(() => {
  try {
    updateCharts(device_charts)

  } catch (err) {
    failures++;
    console.error("Could not update chart after " + failures + " attempts");
    console.error(err);

    if (failures == 3) {
      console.error("Connection has been lost");
      unregister();
    }
  }

}, 5000);

//------------------------------------------------------------------------------

function unregister() {
  clearInterval(interval)
}
