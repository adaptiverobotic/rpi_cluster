# Task scheduling
from apscheduler.schedulers.background import BackgroundScheduler

# Exception handling
import sys

# REST API and serving files / webpage to browser
from flask import Flask, jsonify, request
import redis

# Logging
import logging
from logging.handlers import RotatingFileHandler

# Interfacing with  cli
import cli

# Reading in the config file
# and command line arguments
import json
import os

#-------------------------------------------------------------------------------

# Initialize the Flask application
# This is the main app that will be
# listening to request on this device
# and hosting the main web page.
app   = Flask('api')
cache = redis.Redis(host='redis', port=6379)

#-------------------------------------------------------------------------------

@app.route('/build')
def build():
    return 1

#-------------------------------------------------------------------------------

@app.route('/setup')
def setup():
    return 1

#-------------------------------------------------------------------------------

@app.route('/hostname')
def hostname():
    return 1

#-------------------------------------------------------------------------------

@app.route('/user')
def user():
    return 1

#-------------------------------------------------------------------------------

@app.route('/password')
def password():
    return 1

#-------------------------------------------------------------------------------

@app.route('/magic')
def magic():
    return 1

#-------------------------------------------------------------------------------

@app.route('/nextcloud')
def nextcloud():
    return 1

#-------------------------------------------------------------------------------

@app.route('/samba')
def samba():
    return 1

#-------------------------------------------------------------------------------

@app.route('/pihole')
def pihole():
    return 1

#-------------------------------------------------------------------------------

@app.route('/nat')
def nat():
    return 1
