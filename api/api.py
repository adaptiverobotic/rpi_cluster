# REST API and serving files / webpage to browser
from flask import Flask, Response
import redis

# Interfacing with  cli
import cli

# -------------------------------------------------------------------------------

# Initialize the Flask application
# This is the main app that will be
# listening to request on this device
# and hosting the main web page.
app   = Flask('api')
cache = redis.Redis(host='redis', port=6379)

# -------------------------------------------------------------------------------

@app.route('/build')
def build():
    return Response(cli.build())

# -------------------------------------------------------------------------------

@app.route('/setup')
def setup():
    return Response(cli.setup())

# -------------------------------------------------------------------------------

@app.route('/hostname')
def hostname():
    return Response(cli.hostname())

# -------------------------------------------------------------------------------

@app.route('/user')
def user():
    return Response(cli.user())

# -------------------------------------------------------------------------------

@app.route('/password')
def password():
    return Response(cli.password())

# -------------------------------------------------------------------------------

@app.route('/magic')
def magic():
    return Response(cli.magic())

# -------------------------------------------------------------------------------

@app.route('/nextcloud')
def nextcloud():
    return Response(cli.nextcloud())

# -------------------------------------------------------------------------------

@app.route('/samba')
def samba():
    return Response(cli.samba())

# -------------------------------------------------------------------------------

@app.route('/pihole')
def pihole():
    return Response(cli.pihole())

# -------------------------------------------------------------------------------


@app.route('/nat')
def nat():
    return Response(cli.nat())

# -------------------------------------------------------------------------------


def main():
    app.run(host="0.0.0.0", debug=True, use_reloader=False)

# -------------------------------------------------------------------------------


if __name__ == "__main__":
    main()

