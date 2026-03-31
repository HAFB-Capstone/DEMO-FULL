import sys
import os
import socket
from hardware_stubs import EngineController

class FlightHardware:
    def __init__(self, rt_address=1):
        self.rt_address = rt_address
        self.engine = EngineController()
        # The simulator typically listens on 5001
        self.port = 5001 
        
    def listen_forever(self):
        print(f"[*] RT {self.rt_address} online. Listening for BC commands on port {self.port}...")
        
        # Create a UDP socket to 'sniff' the bus
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.bind(('0.0.0.0', self.port))

        while True:
            # Receive data from the bus
            data, addr = sock.recvfrom(1024)
            decoded_data = data.decode().strip()
            
            print(f"[RT {self.rt_address}] BUS MONITOR: Incoming Data -> {decoded_data}")
            
            # Pass to the hardware stub
            self.engine.process_command(decoded_data)
            
            # Output the 'Internal Sensor' state to logs
            print(f"[STATUS] Engine: {self.engine.status} | RPM: {self.engine.rpm} | Temp: {self.engine.temp}C")

if __name__ == "__main__":
    pass