FROM hypriot/rpi-node

# Copy all those code
# into Docker container
ADD . /

# Install dependencies
RUN npm install

# Copy client-side 3rd part JavaScript libraries
COPY node_modules/jquery/dist/jquery.min.js src/static/jquery.min.js
COPY node_modules/moment/moment.js src/static/moment.js
COPY node_modules/chart.js/dist/Chart.min.js src/static/Chart.min.js

# We will access to app
# using port 8085
EXPOSE 8085

# Move into the directory
# where the node app lives
WORKDIR src

CMD node app.js
