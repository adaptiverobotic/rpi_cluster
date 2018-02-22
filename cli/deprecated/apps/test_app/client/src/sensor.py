import random

# Reads 'temperature' from sensor. This is a mock function
# that in practice would actually read data from a sensor
# hooked up to GPIO. We have abstracted this to one .py
# file so that if we actually want to use this app to collect
# real data, all that we must do is actually implement this
# function. Everything else is in place and should continue to work
# as it currently functions.
def get_temperature():
    return random.randint(1,101)
