from flask import Flask, Response
import redis
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
    return Response(cli.command('build', ''))

# -------------------------------------------------------------------------------

@app.route('/setup')
def setup():
    return Response(cli.command('setup', ''))

# -------------------------------------------------------------------------------

@app.route('/hostname')
def hostname():
    return Response(cli.hostname('set_hostname', 'rpi'))

# -------------------------------------------------------------------------------

@app.route('/user')
def user():
    return Response(cli.command('set_user', 'pi'))

# -------------------------------------------------------------------------------

@app.route('/password')
def password():
    return Response(cli.command('set_password', 'raspberry'))

# -------------------------------------------------------------------------------

@app.route('/magic')
def magic():
    return Response(cli.command('magic', 'install'))

# -------------------------------------------------------------------------------

@app.route('/nextcloud')
def nextcloud():
    return Response(cli.command('nextcloud', 'install_nextcloud'))

# -------------------------------------------------------------------------------

@app.route('/samba')
def samba():
    return Response(cli.command('samba', 'install_samba'))

# -------------------------------------------------------------------------------

@app.route('/pihole')
def pihole():
    return Response(cli.command('pihole', 'install_pihole'))

# -------------------------------------------------------------------------------

@app.route('/nat')
def nat():
    return Response(cli.command('nat', 'install_nat'))

# -------------------------------------------------------------------------------

# Run the Flask app
def main():
    app.run(host="0.0.0.0", debug=True, use_reloader=False)

# -------------------------------------------------------------------------------


if __name__ == "__main__":
    main()
