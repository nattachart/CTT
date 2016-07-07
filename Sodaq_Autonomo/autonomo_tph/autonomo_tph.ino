#include <Sodaq_RN2483.h>
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>

#define BME_SCK 13
#define BME_MISO 12
#define BME_MOSI 11
#define BME_CS 10

#define SEALEVELPRESSURE_HPA (1013.25)
Adafruit_BME280 bme;

//#if defined(ARDUINO_SODAQ_MBILI) || defined(ARDUINO_SODAQ_TATU)
// Autonomo
#define debugSerial SerialUSB
#define loraSerial Serial1
#define beePin BEE_VCC
//#else
//#error "Please select Autonomo, Mbili, or Tatu"
//#endif

//Environmental variables
float temperature;
float pressure;
float humidity;
float altitude;

const uint8_t devAddr[4] =
{
  0x02, 0x03, 0x22, 0x50
};

// USE YOUR OWN KEYS!
const uint8_t appSKey[16] =
{
  0x2B, 0x7E, 0x15, 0x16,
  0x28, 0xAE, 0xD2, 0xA6,
  0xAB, 0xF7, 0x15, 0x88,
  0x09, 0xCF, 0x4F, 0x3C,
};

// USE YOUR OWN KEYS!
const uint8_t nwkSKey[16] =
{
  0x2B, 0x7E, 0x15, 0x16,
  0x28, 0xAE, 0xD2, 0xA6,
  0xAB, 0xF7, 0x15, 0x88,
  0x09, 0xCF, 0x4F, 0x3C,
};

uint8_t testPayload[] =
{
  0x30, 0x31, 0xFF, 0xDE, 0xAD
};

void setup()
{
  debugSerial.begin(57600);
  SerialUSB.println(F("CTT Sodaq Autonomo Indoor Testing"));

  if(!bme.begin()){
    SerialUSB.println(F("The BME280 sensor did not start. Please recheck the wiring."));
    while(1)
  }
  
  loraSerial.begin(LoRaBee.getDefaultBaudRate());

  digitalWrite(beePin, HIGH);
  pinMode(beePin, OUTPUT);

  LoRaBee.setDiag(debugSerial); // optional
  if (LoRaBee.initABP(loraSerial, devAddr, appSKey, nwkSKey, true))
  {
    debugSerial.println("Connection to the network was successful.");
  }
  else
  {
    debugSerial.println("Connection to the network failed!");
  }
}

void loop()
{
   temperature = bme.readTemperature();
   pressure = bme.readPressure();
   humidity = bme.readHumidity();
   altitude = bme.readAltitude(SEALEVELPRESSURE_HPA);
  
  debugSerial.println("Sleeping for 5 seconds before starting sending out test packets.");
  for (uint8_t i = 5; i > 0; i--)
  {
    debugSerial.println(i);
    delay(1000);
  }

  // send 10 packets, with at least a 5 seconds delay after each transmission (more seconds if the device is busy)
  uint8_t i = 10;
  while (i > 0)
  {
    testPayload[0] = i; // change first byte

    switch (LoRaBee.send(1, testPayload, 5))
    {
    case NoError:
      debugSerial.println("Successful transmission.");
      i--;
      break;
    case NoResponse:
      debugSerial.println("There was no response from the device.");
      break;
    case Timeout:
      debugSerial.println("Connection timed-out. Check your serial connection to the device! Sleeping for 20sec.");
      delay(20000);
      break;
    case PayloadSizeError:
      debugSerial.println("The size of the payload is greater than allowed. Transmission failed!");
      break;
    case InternalError:
      debugSerial.println("Oh No! This shouldn't happen. Something is really wrong! Try restarting the device!\r\nThe program will now halt.");
      while (1) {};
      break;
    case Busy:
      debugSerial.println("The device is busy. Sleeping for 10 extra seconds.");
      delay(10000);
      break;
    case NetworkFatalError:
      debugSerial.println("There is a non-recoverable error with the network connection. You should re-connect.\r\nThe program will now halt.");
      while (1) {};
      break;
    case NotConnected:
      debugSerial.println("The device is not connected to the network. Please connect to the network before attempting to send data.\r\nThe program will now halt.");
      while (1) {};
      break;
    case NoAcknowledgment:
      debugSerial.println("There was no acknowledgment sent back!");
      break;
    default:
      break;
    }
    delay(5000);
  }

  while (1) { } // block forever
}
