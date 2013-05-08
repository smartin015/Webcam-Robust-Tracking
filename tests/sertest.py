# Simple test of arduino serial communications
# to check for proper servo control.
# Type an integer and press enter to send that 
# 8-bit value over serial to the arduino.
# Scott Martin <semartin@andrew.cmu.edu>
# 5/2013

import serial   
import threading
import struct

try:
    ser = serial.Serial('COM7', 9600, timeout = 1)
    def read_daemon():
        print ser.read()
        
    thread = threading.Thread(target=read_daemon)
    thread.daemon = True
    thread.start()
    
    while (True):
        val = raw_input("> ")
        if (val.strip()):
            ser.write(struct.pack('b', int(val)))
except:
    #ser.close()
    raise

