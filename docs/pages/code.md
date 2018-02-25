## The code
The application is composed of three layers - a CLI, an API, and a GUI.
I aimed to write this code to be as platform independent as possible. However,
this does not run on Windows. Currently the code must be developed on a Debian
based version of linux. The code can be expanded to run on Mac OS X if the
mac is upgraded to run bash version 4 or greater. The code base also requires
small changes to detec whether or not use `brew` or `apt-get` to install packages
locally. I currently do not have plans to implement this feature.

### CLI
A Shell (bash v4+) based application that does all of the heavy lifting. [Learn more...][cli]

### API
A Flask (python 3.6+) REST API wrapper for easier interaction with the CLI. [Learn more...][api]

### GUI
A ReactJS (ECMAScript 6+) based app that drives the API from the browser. [Learn more...][gui]

[cli]: cli.md
[api]: api.md
[gui]: gui.md
