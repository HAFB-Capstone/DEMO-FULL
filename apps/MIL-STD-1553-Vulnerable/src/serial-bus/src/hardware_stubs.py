class EngineController:
    def __init__(self):
        self.rpm = 0
        self.status = "OFF"
        self.temp = 20

    def process_command(self, cmd):
        # We strip any whitespace or extra characters from the network packet
        clean_cmd = str(cmd).strip().lower()
        
        if clean_cmd == "0x01" or clean_cmd == "1":
            self.status = "IGNITION / STARTING"
            self.rpm = 15000
            self.temp = 650
            print("!!! CRITICAL: ENGINE START SEQUENCE INITIATED !!!")
        
        elif clean_cmd == "0x00":
            self.status = "EMERGENCY SHUTDOWN"
            self.rpm = 0
            print("!!! WARNING: MANUAL CUTOFF DETECTED !!!")