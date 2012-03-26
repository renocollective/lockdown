// RFID reader ID-12 for Arduino 
// Based on code by BARRAGAN <http://people.interaction-ivrea.it/h.barragan> 
// and code from HC Gilje - http://hcgilje.wordpress.com/resources/rfid_id12_tagreader/
// Modified for Arudino by djmatic
// Modified for ID-12 and checksum by Martijn The - http://www.martijnthe.nl/
// Modified for use with Ethernet Shield by Reno Collective
//
// Use the drawings from HC Gilje to wire up the ID-12.
// Remark: disconnect the rx serial wire to the ID-12 when uploading the sketch

#include <Ethernet.h>
#include <SPI.h>

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x3B, 0x8C };  //underneath the shield
byte ip[] = { 10, 0, 1, 250 };       //self assigned internal IP
byte server[] = { 10, 0, 1, 4 }; // IP of endpoint 

EthernetClient client;

boolean found_status_200;
char *found;

int lockPin = 8;
int unlockLength = 2500;
int users = 16;


void setup() {
  pinMode(lockPin, OUTPUT);     
  Serial.begin(9600);                                 // connect to the serial port
  
}

void loop () {
  char cardNum[10];
  byte i = 0;
  byte val = 0;
  byte code[6];
  byte checksum = 0;
  byte bytesread = 0;
  byte tempbyte = 0;

  if(Serial.available() > 0) {
    if((val = Serial.read()) == 2) {                  // check for header 
      bytesread = 0; 
      found_status_200 = false;
      while (bytesread < 12) {                        // read 10 digit code + 2 digit checksum
        if( Serial.available() > 0) { 
          val = Serial.read();
          if((val == 0x0D)||(val == 0x0A)||(val == 0x03)||(val == 0x02)) { // if header or stop bytes before the 10 digit reading 
            break;                                    // stop reading
          }
          
          if (bytesread < 10) { cardNum[bytesread] = val; }

          // Do Ascii/Hex conversion:
          if ((val >= '0') && (val <= '9')) {
            val = val - '0';
          } else if ((val >= 'A') && (val <= 'F')) {
            val = 10 + val - 'A';
          }

          // Every two hex-digits, add byte to code:
          if (bytesread & 1 == 1) {
            // make some space for this hex-digit by
            // shifting the previous hex-digit with 4 bits to the left:
            code[bytesread >> 1] = (val | (tempbyte << 4));

            if (bytesread >> 1 != 5) {                // If we're at the checksum byte,
              checksum ^= code[bytesread >> 1];       // Calculate the checksum... (XOR)
            };
          } else {
            tempbyte = val;                           // Store the first hex digit first...
          };

          bytesread++;                                // ready to read next digit
          if (bytesread==12) {cardNum[10] = ' \0' ; }
        } 
        
       
      } 

      // Output to Serial:
  
   
      if (bytesread == 12) {        // if 12 digit read is complete
        Serial.println("Card number:");
        Serial.println(cardNum);
        
        checkAccessToBuilding(cardNum);
        
        if(found_status_200 == true)
        {
          Serial.println("Card Validated"); 
          unlock();  
          Serial.println(); 
        }
        else { 
          Serial.println("Card INVALID"); 
          Serial.println(); 
        } 
        
      }

      bytesread = 0;
    }
  }
}

bool checkAccessToBuilding(char cardNum[10])
{
   Ethernet.begin(mac, ip);
   Serial.begin(9600);
     
   delay(1000);
  
   Serial.println("connecting...");
  
   if (client.connect(server, 80)) 
   {
     Serial.println("connected");
     client.print("GET /unlock?id=");
     client.print(cardNum);
     client.print(" HTTP/1.1");
     client.println();
     client.println();
   
     checkForResponse();
     
   } else {
     Serial.println("connection failed");
   }
   
   Serial.println("disconnecting");
   client.stop();
   
}

void checkForResponse(){
  char buff[1024];
  int pointer = 0;
    
  while(client.connected()) {
    if(client.available()) {
      char c = client.read();
      buff[pointer++] = c;
    }
  }
  
  buff[pointer] = 0;
  Serial.println(buff);
  
  found = strstr(buff, "200 OK");
  if (found != 0){
      found_status_200 = true; 
  } else {
      found_status_200 = false;
  }
  
}

void unlock() { 
    digitalWrite(lockPin, HIGH); 
    delay(unlockLength); 
    digitalWrite(lockPin, LOW); 
} 
