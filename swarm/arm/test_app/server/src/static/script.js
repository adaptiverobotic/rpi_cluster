var devices = getDevices();
var device_charts = [];

// Draw a chart for each device
for (i in devices) {
  device_charts.push(drawChart(devices[i]));
}

setInterval(() => {updateCharts(device_charts)}, 5000);
