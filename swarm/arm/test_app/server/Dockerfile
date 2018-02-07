FROM hypriot/rpi-node

# Copy all those code
# into Docker container
ADD . /

# Install dependencies
RUN npm install

# We will access to app
# using port 8085
EXPOSE 8085

# Move into the directory
# where the node app lives
WORKDIR src

CMD node app.js --DB_PASSWORD_FILE=${DB_PASSWORD_FILE}
