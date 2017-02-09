//#define _DEBUG

#define SOCKET SOCKET0
#define PORT 3 //Port to use in Back-End: from 1 to 223

#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspSensorGas_Pro.h>

char node_id[] = "wmtroof2";
uint8_t errorLW;

Gas co2(SOCKET_A);

float concentration;  // Stores the concentration level in ppm
float temperature;  // Stores the temperature in ºC
float humidity;   // Stores the realitve humidity in %RH
float pressure;   // Stores the pressure in Pa

void setup()
{
  configureLoRaWAN();
  frame.setID(node_id);
}


void loop()
{
  co2.ON();
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  // Read the CO2 sensor and compensate with the temperature internally
  concentration = co2.getConc();

  // Read enviromental variables
  temperature = co2.getTemp();
  humidity = co2.getHumidity();
  pressure = co2.getPressure();
  co2.OFF();
  frame.createFrame(ASCII);
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  frame.addSensor(SENSOR_GP_CO2, concentration);
  frame.addSensor(SENSOR_GP_TC, temperature);
  frame.addSensor(SENSOR_GP_HUM, humidity);
  frame.addSensor(SENSOR_GP_PRES, pressure);
  frame.showFrame();

  //char data[frame.length*2 + 1];
  //Utils.hex2str(frame.buffer, data, frame.length);
  //char data[] = "0102030405060708090A0B0C0D0E0F";
  //PWR.deepSleep("00:00:00:04", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  //Switch on LoRaWAN
  errorLW = LoRaWAN.ON(SOCKET);

#ifdef _DEBUG
  // Check status
  if( errorLW == 0 ) 
  {
    USB.println(F("1. Switch ON OK")); 
  }
  else 
  {
    USB.print(F("1. Switch ON error = ")); 
    USB.println(errorLW, DEC);
  }
#endif
  
  errorLW = LoRaWAN.joinABP();

  if(errorLW == 0)
  {
    //Send confirmed packet
    errorLW = LoRaWAN.sendConfirmed(PORT, frame.buffer, frame.length);
    // Error messages:
    /*
     * '6' : Module hasn't joined a network
     * '5' : Sending error
     * '4' : Error with data length    
     * '2' : Module didn't response
     * '1' : Module communication error   
     */
    // Check status
#ifdef _DEBUG
    if( errorLW == 0 ) 
    {
      USB.println(F("3. Send UnConfirmed packet OK"));
      if (LoRaWAN._dataReceived == true)
      { 
        USB.print(F("   There's data on port number "));
        USB.print(LoRaWAN._port,DEC);
        USB.print(F(".\r\n   Data: "));
        USB.println(LoRaWAN._data);
      }
    }
    else 
    {
      USB.print(F("3. Send UnConfirmed packet error = ")); 
      USB.println(errorLW, DEC);
    }
#endif
  }
  else
  {
#ifdef _DEBUG
    USB.print(F("2. Join network error = ")); 
    USB.println(errorLW, DEC);
#endif
  }
  errorLW = LoRaWAN.OFF(SOCKET);
  //PWR.deepSleep("00:00:00:04", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

#ifdef _DEBUG
  // Check status
  if( errorLW == 0 )
  {
    USB.println(F("4. Switch OFF OK"));
  }
  else 
  {
    USB.print(F("4. Switch OFF error = ")); 
    USB.println(errorLW, DEC);
  }
#endif
  PWR.deepSleep("00:00:10:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

void configureLoRaWAN()
{
  // socket to use
  //////////////////////////////////////////////
  uint8_t socket = SOCKET0;
  //////////////////////////////////////////////
  
  // Device parameters for Back-End registration
  ////////////////////////////////////////////////////////////
  char DEVICE_EUI[]  = "007ED5AA34610EA2";
  char APP_EUI[] = "70B3D57EF0003517";
  char APP_KEY[] = "8CABD1C9F53C7DA15CA91E14E11F0DF6";
  ////////////////////////////////////////////////////////////
  
  // Define data payload to send (maximum is up to data rate)
  char data[] = "0102030405060708090A0B0C0D0E0F";
  
  // variable
  uint8_t error;
  USB.ON();
  USB.println(F("LoRaWAN example - Send Unconfirmed packets (ACK)\n"));


  USB.println(F("------------------------------------"));
  USB.println(F("Module configuration"));
  USB.println(F("------------------------------------\n"));


  //////////////////////////////////////////////
  // 1. Switch on
  //////////////////////////////////////////////

  error = LoRaWAN.ON(socket);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("1. Switch ON OK"));     
  }
  else 
  {
    USB.print(F("1. Switch ON error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 2. Set Device EUI
  //////////////////////////////////////////////

  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("2. Device EUI set OK"));     
  }
  else 
  {
    USB.print(F("2. Device EUI set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Set Application EUI
  //////////////////////////////////////////////

  error = LoRaWAN.setAppEUI(APP_EUI);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("3. Application EUI set OK"));     
  }
  else 
  {
    USB.print(F("3. Application EUI set error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 4. Set Application Session Key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppKey(APP_KEY);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("4. Application Key set OK"));     
  }
  else 
  {
    USB.print(F("4. Application Key set error = ")); 
    USB.println(error, DEC);
  }

  /////////////////////////////////////////////////
  // 5. Join OTAA to negotiate keys with the server
  /////////////////////////////////////////////////
  
  error = LoRaWAN.joinOTAA();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("5. Join network OK"));         
  }
  else 
  {
    USB.print(F("5. Join network error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 6. Save configuration
  //////////////////////////////////////////////

  error = LoRaWAN.saveConfig();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("6. Save configuration OK"));     
  }
  else 
  {
    USB.print(F("6. Save configuration error = ")); 
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 7. Switch off
  //////////////////////////////////////////////

  error = LoRaWAN.OFF(socket);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("7. Switch OFF OK"));     
  }
  else 
  {
    USB.print(F("7. Switch OFF error = ")); 
    USB.println(error, DEC);
  }

  
  USB.println(F("\n---------------------------------------------------------------"));
  USB.println(F("Module configured"));
  USB.println(F("After joining through OTAA, the module and the network exchanged "));
  USB.println(F("the Network Session Key and the Application Session Key which "));
  USB.println(F("are needed to perform communications. After that, 'ABP mode' is used"));
  USB.println(F("to join the network and send messages after powering on the module"));
  USB.println(F("---------------------------------------------------------------\n"));
  USB.println();  
}

