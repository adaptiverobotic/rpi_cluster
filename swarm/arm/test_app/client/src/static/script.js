var options = {
  responsive: true,

  animation: {
        duration: 0
  },

  scales: {
    xAxes: [{
      ticks: {
        autoSkip: true,
        maxTicksLimit: 5
      },
      type:'time',
      time: {
          unit: 'second',
          tooltipFormat: "MMM D, h:mm A",
          displayFormats: {
            second: 'MMM D, h:mm A'
          }
      }
    }],
    yAxes: [{
      ticks: {
        autoSkip: true,
        maxTicksLimit: 5
      },

      scaleLabel: {
        display: true,
        labelString: "Temperature"
      }
    }]
  }
}

//------------------------------------------------------------------------------

/**
 * Draws a new chart
 */
function drawChart() {

  // Get device data from server
  let device      = getTemperatureData();
  let device_id   = device.device_id;
  let device_name = device.device_name;
  let charts      = document.getElementById("charts");
  let container   = document.createElement("div");
  let heading     = document.createElement("h2");
  let chart       = document.createElement("canvas");

  // Set attributes of DOM elements
  chart.id          = device_name + "-" + device_id;
  heading.innerHTML = "Temperature Data for: " + device_name;
  container.classList.add('container');

  // Insert elements into DOM
  container.appendChild(heading);
  container.appendChild(chart);
  charts.appendChild(container);

  var ctx = document.getElementById(chart.id).getContext('2d');

  var myLineChart = new Chart(ctx, {
    type: 'scatter',
    data: {
      datasets: [{
         label: "Temperature vs Date",
         data: device.data,
      }]
   },
   options : options

 });

 return {
   device: device,
   chart: myLineChart
 };
}

//------------------------------------------------------------------------------

/**
 * Gets temperature data for this device
 */
function getTemperatureData() {
  return (function getConfig() {

    // Get JSON data from server
    let device = JSON.parse(
      $.ajax({
        url: window.location.href + "temperature",
        type: "get",
        dataType: 'json',
        data : {
          "num_records": 500
        },
        async: false
      }).responseText
    );

    let data = [];

    // Convert data to (x, y) format
    for (i in device.data) {
     data.push({
       "x": device.data[i].record_time,
       "y": device.data[i].temperature
     });
    }

    // Replace old array with new one
    delete device.data;
    device.data = data;

    // Return the modified data
    return device;
  })();
}

//------------------------------------------------------------------------------

/**
 * Updates the data in a chart
 */
function updateChart(device_chart) {
  let chart = device_chart.chart;

  // Delete old data and replace it
  delete chart.data.datasets[0].data;
  chart.data.datasets[0].data = getTemperatureData().data;
  chart.update();
}

//------------------------------------------------------------------------------

let chart = drawChart();
let failures = 0;

var interval = setInterval(() => {
  try {
    updateChart(chart)

  } catch (err) {
    failures++;
    console.log("Could not update chart after " + failures + " attempts")

    if (failures == 3) {
      console.log("Connection has been lost")
      unregister();
    }
  }

}, 2000);

function unregister() {
  clearInterval(interval)
}
