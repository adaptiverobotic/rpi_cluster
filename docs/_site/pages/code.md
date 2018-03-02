## The code
Here I will describe the layout of the code from a high level perspective. The application is composed of three layers:

![code structure diagram][diagram]

The directory hierarchy appears as follows:

```
/rpi_cluster
├── /cli
|   └── cli.sh
├── /api
|   ├── cli.py
|   └── api.py
├── /gui
|   ├── api.js
|   └── gui.js
└── setup.sh
```

Starting from the top down:

* `/rpi_cluster` is the root directory, that contains the three main directories `/cli`, `/api`, and `/gui`, along with a `setup.sh` script at the highest level to facilitate the installation process of the entire application.

* `/cli` contains all of the scripts the do the actual deploying. But, from outside of the `/cli` directory, the only accessible script is `cli.sh`. It is the entry point for using the application from the terminal or from the API.

* `/api` is where the REST application lives that calls the CLI. `/api` has two main components. `cli.py`, which acts as a controller with 1:1
python:bash function bindings with `cli.sh` - it acts as a liaison. The other component is `api.py`, which exposes REST endpoints on a specified port for use with HTTP methods. It is the entry point for consuming the API from the GUI.

* `/gui` is the top layer and the most abstract. It also has two major components. `api.js`, which provides 1:1 js:python function bindings with the API. It also has `gui.js`, which is the main JavaScript file that will server an `index.html` for access in the browser.

### CLI
A library of shell (bash v4+) scripts that do all of the heavy lifting. This application can be used directly from the command line without the API or GUI. However, the API provides better error handling and filters out potentially bad data. [Learn more...][cli]

### API
A Flask (python 3.6+) REST API wrapper for easier interaction with the CLI. This layer abstracts bash function calls and script executions to HTTP methods such as POST and GET. It also provides an added layer of defense again bad data such as invalid usernames, passwords, and hostnames when establishing common credentials for our servers. [Learn more...][api]

### GUI
A ReactJS (ECMAScript 6+) based app that drives the API from the browser. The GUI is simply for convenience. It is a wrapper around the API that allows us to interact with the software from an easy to use and intuitive interface. [Learn more...][gui]

### Compatibility
I aimed to write this code to be as platform independent as possible. However,
this does not run on Windows. Currently the code must be developed on a Debian
based version of Linux. The code can be expanded to run on Mac OS X if the
Mac is upgraded to run bash version 4 or greater. The code base also requires
small changes to detect whether or not use `brew` or `apt-get` to install packages
locally. However, I do not have plans to implement this feature as it will not
provide much benefit nor functionality to the end product.

[diagram]: ../assets/img/code/code_structure_diagram.png
[cli]: cli.md
[api]: api.md
[gui]: gui.md
