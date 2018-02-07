
/**
 * Returns list of devices.
 */
function getDevices() {
  // Get all devices
  return (function getConfig() {

   return JSON.parse(
     $.ajax({
       url: window.location.href + "devices",
       type: "get",
       dataType: 'json',
       async: false
     }).responseText
   );
  })();
}

//------------------------------------------------------------------------------

/**
 * Gets temperature data for this device
 */
function getTemperatureData(device_id) {
  return (function getConfig() {

    // Get JSON data from server
    let device = JSON.parse(
      $.ajax({
        url: window.location.href + "temperature",
        type: "get",
        dataType: 'json',
        data : {
          "device_id": device_id,
          "num_records": 500
        },
        async: false
      }).responseText
    );

    let data = [];

    // Convert data to (x, y) format
    for (let i in device.data) {
      let record = {
        "x": device.data[i].record_time,
        "y": device.data[i].temperature
      };

      data.push(record);
    }

    // Replace old array with new one
    delete device.data;
    device.data = data;

    // Return the modified data
    return device;
  })();
}
