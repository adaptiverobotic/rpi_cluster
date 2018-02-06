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
function drawChart(device) {
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
         data: getTemperatureData(device_id).data,
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
 * Updates the data in a chart
 */
function updateChart(device_chart) {
  let device_id   = device_chart.device.device_id;
  let device_name = device_chart.device.device_name;
  let chart       = device_chart.chart;

  // Delete old data and replace it
  delete chart.data.datasets[0].data;
  chart.data.datasets[0].data = getTemperatureData(device_id);
  chart.update();
}

//------------------------------------------------------------------------------

/**
 * Updates a list of charts
 */
function updateCharts(device_charts) {
  for (i in device_charts) {
    updateChart(device_charts[i]);
  }
}
