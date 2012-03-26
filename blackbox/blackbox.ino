// RFID reader ID-12 for Arduino -- http://www.sparkfun.com/products/8419
// Based on code by BARRAGAN <http://people.interaction-ivrea.it/h.barragan>
// and code from HC Gilje - http://hcgilje.wordpress.com/resources/rfid_id12_tagreader/
// Modified for Arudino by djmatic
// Modified for ID-12 and checksum by Martijn The - http://www.martijnthe.nl/
// Modified for use with Ethernet Shield by Reno Collective
//
// Use the drawings from HC Gilje to wire up the ID-12.
// Remark: disconnect the rx serial wire to the ID-12 when uploading the sketch

// ID-12 Features:
//  * 9600bps TTL and RS232 output

#include <Ethernet.h>
#include <SPI.h>

// the media access control (ethernet hardware) address for the shield:
byte mac[]    = { 0x90, 0xA2, 0xDA, 0x00, 0x3B, 0x8C };
byte ip[]     = { 10, 0, 1, 250 };                // self-assigned internal IP

byte server[] = { 10, 0, 1, 4 };                  // IP of endpoint
EthernetClient client;

char *found;
int responseBufferSize = 256;                       // only 1024 bytes total of SRAM are available (ATmega168)

int LOCK_PIN = 8;
int UNLOCK_LEN = 2500;                              // maybe get the length from the web server?
int MAX_BAUD_OF_RFID = 9600;

// runs once, only on powerup or reset:
void setup() {
  pinMode(LOCK_PIN, OUTPUT);
  Serial.begin(MAX_BAUD_OF_RFID);                   // connect to the RFID reader's serial port
}

void loop () {
  int cardLen = 10;
  char cardNum[cardLen];
  byte i = 0;
  byte val = 0;
  byte code[6];
  byte checksum = 0;
  byte bytesread = 0;
  byte tempbyte = 0;

  if (Serial.available() > 0) {
    val = Serial.read();
    if (val == 2) {                                 // check for header
      bytesread = 0;
      connectToEthernet();
      while (bytesread < 12) {                      // read 10 digit code + 2 digit checksum
        if (Serial.available() > 0) {
          val = Serial.read();

          // if header or stop bytes before the 10 digit reading, stop reading:
          if ((val == 0x0D) || (val == 0x0A) || (val == 0x03) || (val == 0x02)) { 
            break;
          }

          if (bytesread < cardLen) { cardNum[bytesread] = val; }

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

            if (bytesread >> 1 != 5) {              // If we're at the checksum byte,
              checksum ^= code[bytesread >> 1];     // Calculate the checksum... (XOR)
            }
          } else {
            tempbyte = val;                         // Store the first hex digit first...
          }

          bytesread++;                              // ready to read next digit
          if (bytesread == 12) { cardNum[cardLen] = ' \0' ; }
        }
      }

      // Output to Serial:
      if (bytesread == 12) {                        // if 12, digit read is complete
        Serial.println("Card number:");
        Serial.println(cardNum);

        if (checkAccessToBuilding(cardNum)) {
          Serial.println("Card Validated");
          unlock();
          Serial.println();
        } else {
          Serial.println("Card INVALID");
          Serial.println();
        }
      }

      bytesread = 0;
    }
  }
}

void connectToEthernet() {
   Serial.println("connecting to ethernet...");
   Ethernet.begin(mac, ip);
}

bool checkAccessToBuilding(char cardNum[10]) {
  bool retval = false;

   if (client.connect(server, 80)) {
     Serial.println("connected");
     client.print("GET /unlock?id=");
     client.print(cardNum);
     client.print(" HTTP/1.0");
     client.println();
     client.println();

     retval = parseResponse();
   } else {
     Serial.println("connection failed");
   }

   Serial.println("disconnecting");
   client.stop();

  return retval;   
}

bool parseResponse() {
  char buff[responseBufferSize];
  int pointer = 0;

  while (client.connected()) {
    if (client.available()) {
      char c = client.read();
      if (pointer < responseBufferSize) {
        buff[pointer++] = c;
      }
    }
  }

  buff[pointer] = 0;
  Serial.println(buff);

  found = strstr(buff, "200 OK");
  if (found != 0) {
    return true;
  } else {
    return false;
  }
}

void unlock() {
    digitalWrite(LOCK_PIN, HIGH);
    delay(UNLOCK_LEN);
    digitalWrite(LOCK_PIN, LOW);
}
