FROM python:3.4-alpine

# Copy this folder
ADD . /client

WORKDIR /client

# Install dependencies
RUN pip install -r dependencies.txt

# Run the app
WORKDIR src
CMD ["python", "app.py", "--mac-address=10301995"]
