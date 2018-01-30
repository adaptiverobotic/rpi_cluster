
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
 * Provided device_id, corresponding
 * temperature data is returned.
 */
function getTemperatureData(device_id) {
  return (function getConfig() {

   return JSON.parse(
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
  })();

}
