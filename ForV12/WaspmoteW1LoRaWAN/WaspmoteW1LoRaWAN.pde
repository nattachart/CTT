#define _DEBUG

#define BATT_LEVEL F("battery_level=")
#define BATT_VOLT F("battery_voltage=")
#define BATT_ADC F("battery_ADC_value=")
#define TEMP F("temperature=")
#define HUMID F("humidity=")
#define PRESS F("pressure=")
#define CO2 F("co2=")
#define NO2 F("no2=")
#define PM1 F("pm1=")
#define PM2 F("pm2=")
#define PM10 F("pm10=")
#define START F("#")
#define DELIM F(",")
#define PMX_BATT_TRES 60 //The least battery percentage PMX is allowed to function
#define PORT 3 //Port to use in Back-End: from 1 to 223
#define SOCKET SOCKET0

#include <WaspSensorGas_Pro.h>
#include <WaspOPC_N2.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>

float temperature;  // Stores the temperature in ºC
float humidity;   // Stores the realitve humidity in %RH
float pressure;   // Stores the pressure in Pa
float co2Concentration, no2Concentration;
float pm1, pm2, pm10;
float batteryVolt;
int batteryLevel, batteryADCLevel;

char info_string[61];
int status;
int measure;

Gas co2(SOCKET_A);

char node_id[] = "TRW1";

bool pmx;
uint8_t errorLW;

//#define SENSOR_BAT_VOLT 175
//#define SENSOR_BAT_ADC 176

//prog_char str_

void setup()
{
  //configureLoRaWAN();
  frame.setID(node_id);
  status = OPC_N2.ON(OPC_N2_SPI_MODE);
  if (status == 1)
  {
      status = OPC_N2.getInfoString(info_string);
#ifdef _DEBUG
      if (status == 1)
      {
          USB.println(F("Information string extracted:"));
          USB.println(info_string);
      }
      else
      {
          USB.println(F("Error reading the particle sensor"));
      }
#endif

      OPC_N2.OFF();
  }
  else
  {
#ifdef _DEBUG
      USB.println(F("Error starting the particle sensor"));
#endif
  }
}


void loop()
{
  co2.ON();
  PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  
  
  co2Concentration = co2.getConc();
  temperature = co2.getTemp();
  humidity = co2.getHumidity();
  pressure = co2.getPressure();
  
  co2.OFF();

  batteryVolt = PWR.getBatteryVolts();
  batteryLevel = PWR.getBatteryLevel();
  batteryADCLevel = getBatteryADCLevel();

  if(batteryLevel >= PMX_BATT_TRES)
  {
    pmx = true;
  }
  else
  {
    pmx = false;
  }

  if(pmx)
  {
  // Power on the OPC_N2 sensor. 
    // If the gases PRO board is off, turn it on automatically.
    status = OPC_N2.ON(OPC_N2_SPI_MODE);
#ifdef _DEBUG
    if (status == 1)
    {
        USB.println(F("Particle sensor started"));

    }
    else
    {
        USB.println(F("Error starting the particle sensor"));
    }
#endif
  

    ///////////////////////////////////////////
    // 2. Read sensors
    ///////////////////////////////////////////  

    if (status == 1)
    {
        // Power the fan and the laser and perform a measure of 5 seconds
        measure = OPC_N2.getPM(5000);
        if (measure == 1)
        {
            pm1 = OPC_N2._PM1;
            pm2 = OPC_N2._PM2_5;
            pm10 = OPC_N2._PM10;
#ifdef _DEBUG
            USB.println(F("Measure performed"));
            USB.print(F("PM 1: "));
            USB.print(pm1);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 2.5: "));
            USB.print(pm2);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 10: "));
            USB.print(pm10);
            USB.println(F(" ug/m3"));
#endif
        }
        else
        {
#ifdef _DEBUG
            USB.print(F("Error performing the measure. Error code:"));
            USB.println(measure, DEC);
#endif
        }
    }


    ///////////////////////////////////////////
    // 3. Turn off the sensors
    /////////////////////////////////////////// 

    // Power off the OPC_N2 sensor. If there aren't other sensors powered, 
    // turn off the board automatically
    OPC_N2.OFF();
  }
  else
  {
    pm1 = pm2 = pm10 = -1;
  }

  //Output to serial port
  USB.print(START);
  USB.print(BATT_LEVEL);
  USB.print(batteryLevel);
  USB.print(DELIM);
  USB.print(BATT_VOLT);
  USB.print(batteryVolt);
  USB.print(DELIM);
  USB.print(BATT_ADC);
  USB.print(batteryADCLevel);
  USB.print(DELIM);
  USB.print(TEMP);
  USB.print(temperature);
  USB.print(DELIM);
  USB.print(HUMID);
  USB.print(humidity);
  USB.print(DELIM);
  USB.print(PRESS);
  USB.print(pressure);
  USB.print(DELIM);
  USB.print(CO2);
  USB.print(co2Concentration);
  USB.print(DELIM);
  USB.print(NO2);
  USB.print(no2Concentration);
  USB.print(DELIM);
  USB.print(PM1);
  USB.print(pm1);
  USB.print(DELIM);
  USB.print(PM2);
  USB.print(pm2);
  USB.print(DELIM);
  USB.print(PM10);
  USB.println(pm10);

  
  //Create a new frame
  frame.createFrame(BINARY);
  frame.addSensor(SENSOR_BAT, (uint8_t)batteryLevel);
  //frame.addSensor(SENSOR_GP_TF, batteryVolt);
  //frame.addSensor(SENSOR_DATE, (uint8_t)batteryADCLevel);
  frame.addSensor(SENSOR_GP_CO2, co2Concentration);
  frame.addSensor(SENSOR_GP_TC, temperature);
  frame.addSensor(SENSOR_GP_HUM, humidity);
  frame.addSensor(SENSOR_GP_PRES, pressure);
  frame.addSensor(SENSOR_OPC_PM1, pm1);
  frame.addSensor(SENSOR_OPC_PM2_5, pm2);
  frame.addSensor(SENSOR_OPC_PM10, pm10);

  char data[frame.length * 2 + 1];
  Utils.hex2str(frame.buffer, data, frame.length);

  //frame.showFrame();

  //Switch on LoRaWAN
  errorLW = LoRaWAN.ON(SOCKET);

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
  
  errorLW = LoRaWAN.joinABP();

  if(errorLW == 0)
  {
    //Send confirmed packet
    errorLW = LoRaWAN.sendUnconfirmed(PORT, data);
    // Error messages:
    /*
     * '6' : Module hasn't joined a network
     * '5' : Sending error
     * '4' : Error with data length    
     * '2' : Module didn't response
     * '1' : Module communication error   
     */
    // Check status
    if( errorLW == 0 ) 
    {
      USB.println(F("3. Send Confirmed packet OK")); 
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
      USB.print(F("3. Send Confirmed packet error = ")); 
      USB.println(errorLW, DEC);
    }
  }
  else
  {
    USB.print(F("2. Join network error = ")); 
    USB.println(errorLW, DEC);
  }

  errorLW = LoRaWAN.OFF(SOCKET);
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
  
  pm1 = pm2 = pm10 = 0;
  //PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

int getBatteryADCLevel()
{
  int aux_volts=0;
  pinMode(BAT_MONITOR_PW,OUTPUT);
  digitalWrite(BAT_MONITOR_PW,HIGH);
  aux_volts=analogRead(0);
  digitalWrite(BAT_MONITOR_PW,LOW);
  return aux_volts;
}

void configureLoRaWAN()
{
  char DEVICE_EUI[]  = "0000000419659732";
  char DEVICE_ADDR[] = "26011C4F";
  char NWK_SESSION_KEY[] = "7E3D769747A37F51EC2817F1AC4E156D";
  char APP_SESSION_KEY[] = "112E1C23D56DF5A48110858B9FA751D2";
  char APP_KEY[] = "112E1C23D56DF5A48110858B9FA751D2";
  //////////////////////////////////////////////
  // 1. switch on
  //////////////////////////////////////////////

  uint8_t error = LoRaWAN.ON(SOCKET);

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
  // 2. Reset to factory default values
  //////////////////////////////////////////////

  error = LoRaWAN.factoryReset();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("2. Reset to factory default values OK"));     
  }
  else 
  {
    USB.print(F("2. Reset to factory error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 3. Set/Get Device EUI
  //////////////////////////////////////////////

  // Set Device EUI
  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("3.1. Set Device EUI OK"));     
  }
  else 
  {
    USB.print(F("3.1. Set Device EUI error = ")); 
    USB.println(error, DEC);
  }

  // Get Device EUI
  error = LoRaWAN.getDeviceEUI();

  // Check status
  if( error == 0 ) 
  {
    USB.print(F("3.2. Get Device EUI OK. ")); 
    USB.print(F("Device EUI: "));
    USB.println(LoRaWAN._devEUI);
  }
  else 
  {
    USB.print(F("3.2. Get Device EUI error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 4. Set/Get Device Address
  //////////////////////////////////////////////

  // Set Device Address
  error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("4.1. Set Device address OK"));     
  }
  else 
  {
    USB.print(F("4.1. Set Device address error = ")); 
    USB.println(error, DEC);
  }
  
  // Get Device Address
  error = LoRaWAN.getDeviceAddr();

  // Check status
  if( error == 0 ) 
  {
    USB.print(F("4.2. Get Device address OK. ")); 
    USB.print(F("Device address: "));
    USB.println(LoRaWAN._devAddr);
  }
  else 
  {
    USB.print(F("4.2. Get Device address error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 5. Set Network Session Key
  //////////////////////////////////////////////
 
  error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("5. Set Network Session Key OK"));     
  }
  else 
  {
    USB.print(F("5. Set Network Session Key error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 6. Set Application Session Key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("6. Set Application Session Key OK"));     
  }
  else 
  {
    USB.print(F("6. Set Application Session Key error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 7. Set retransmissions for uplink confirmed packet
  //////////////////////////////////////////////

  // set retries
  error = LoRaWAN.setRetries(7);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("7.1. Set Retransmissions for uplink confirmed packet OK"));     
  }
  else 
  {
    USB.print(F("7.1. Set Retransmissions for uplink confirmed packet error = ")); 
    USB.println(error, DEC);
  }
  
  // Get retries
  error = LoRaWAN.getRetries();

  // Check status
  if( error == 0 ) 
  {
    USB.print(F("7.2. Get Retransmissions for uplink confirmed packet OK. ")); 
    USB.print(F("TX retries: "));
    USB.println(LoRaWAN._retries, DEC);
  }
  else 
  {
    USB.print(F("7.2. Get Retransmissions for uplink confirmed packet error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 8. Set application key
  //////////////////////////////////////////////

  error = LoRaWAN.setAppKey(APP_KEY);

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("8. Application key set OK"));     
  }
  else 
  {
    USB.print(F("8. Application key set error = ")); 
    USB.println(error, DEC);
  }


  ////////////////////////////////////////////////////////
  //  ______________________________________________________
  // |                                                      |
  // |  It is not mandatory to configure channel parameters.|
  // |  Server should configure the module during the       |
  // |  Over The Air Activation process. If channels aren't |
  // |  configured, please uncomment channel configuration  |
  // |  functions below these lines.                        |
  // |______________________________________________________|
  //
  ////////////////////////////////////////////////////////

  //////////////////////////////////////////////
  // 9. Channel configuration. (Recommended)
  // Consult your Network Operator and Backend Provider
  //////////////////////////////////////////////

  // Set channel 3 -> 867.1 MHz
  // Set channel 4 -> 867.3 MHz
  // Set channel 5 -> 867.5 MHz
  // Set channel 6 -> 867.7 MHz
  // Set channel 7 -> 867.9 MHz

//  uint32_t freq = 867100000;
//  
//  for (uint8_t ch = 3; ch <= 7; ch++)
//  {
//    error = LoRaWAN.setChannelFreq(ch, freq);
//    freq += 200000;
//    
//    // Check status
//    if( error == 0 ) 
//    {
//      USB.println(F("9. Frequency channel set OK"));     
//    }
//    else 
//    {
//      USB.print(F("9. Frequency channel set error = ")); 
//      USB.println(error, DEC);
//    }
//    
//    
//  }
  
  

  //////////////////////////////////////////////
  // 10. Set Duty Cycle for specific channel. (Recommended)
  // Consult your Network Operator and Backend Provider
  //////////////////////////////////////////////

//  for (uint8_t ch = 0; ch <= 2; ch++)
//  {
//    error = LoRaWAN.setChannelDutyCycle(ch, 33333);
//    
//    // Check status
//    if( error == 0 ) 
//    {
//      USB.println(F("10. Duty cycle channel set OK"));     
//    }
//    else 
//    {
//      USB.print(F("10. Duty cycle channel set error = ")); 
//      USB.println(error, DEC);
//    }
//  }
//
//  for (uint8_t ch = 3; ch <= 7; ch++)
//  {
//    error = LoRaWAN.setChannelDutyCycle(ch, 40000);
//    
//    // Check status
//    if( error == 0 ) 
//    {
//      USB.println(F("10. Duty cycle channel set OK"));     
//    }
//    else 
//    {
//      USB.print(F("10. Duty cycle channel set error = ")); 
//      USB.println(error, DEC);
//    }
//  }

  //////////////////////////////////////////////
  // 11. Set Data Range for specific channel. (Recommended)
  // Consult your Network Operator and Backend Provider
  //////////////////////////////////////////////

//  for (int ch = 0; ch <= 7; ch++)
//  {
//    error = LoRaWAN.setChannelDRRange(ch, 0, 5);
//  
//    // Check status
//    if( error == 0 ) 
//    {
//      USB.println(F("11. Data rate range channel set OK"));     
//    }
//    else 
//    {
//      USB.print(F("11. Data rate range channel set error = ")); 
//      USB.println(error, DEC);
//    }
//  }

  

  //////////////////////////////////////////////
  // 12. Set Data rate range for specific channel. (Recommended)
  // Consult your Network Operator and Backend Provider
  //////////////////////////////////////////////

//  for (int ch = 0; ch <= 7; ch++)
//  {
//    error = LoRaWAN.setChannelStatus(ch, "on");
//    
//    // Check status
//    if( error == 0 ) 
//    {
//      USB.println(F("12. Channel status set OK"));     
//    }
//    else 
//    {
//      USB.print(F("12. Channel status set error = ")); 
//      USB.println(error, DEC);
//    }
//  }


  //////////////////////////////////////////////
  // 13. Set Adaptive Data Rate (recommended)
  //////////////////////////////////////////////

  // set ADR
  error = LoRaWAN.setADR("on");

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("13.1. Set Adaptive data rate status to on OK"));     
  }
  else 
  {
    USB.print(F("13.1. Set Adaptive data rate status to on error = ")); 
    USB.println(error, DEC);
  }
  
  // Get ADR
  error = LoRaWAN.getADR();

  // Check status
  if( error == 0 ) 
  {
    USB.print(F("13.2. Get Adaptive data rate status OK. ")); 
    USB.print(F("Adaptive data rate status: "));
    if (LoRaWAN._adr == true)
    {
      USB.println("on");      
    }
    else
    {
      USB.println("off");
    }
  }
  else 
  {
    USB.print(F("13.2. Get Adaptive data rate status error = ")); 
    USB.println(error, DEC);
  }


  //////////////////////////////////////////////
  // 14. Set Automatic Reply
  //////////////////////////////////////////////

  // set AR
  error = LoRaWAN.setAR("on");

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("14.1. Set automatic reply status to on OK"));     
  }
  else 
  {
    USB.print(F("14.1. Set automatic reply status to on error = ")); 
    USB.println(error, DEC);
  }
  
  // Get AR
  error = LoRaWAN.getAR();

  // Check status
  if( error == 0 ) 
  {
    USB.print(F("14.2. Get automatic reply status OK. ")); 
    USB.print(F("Automatic reply status: "));
    if (LoRaWAN._ar == true)
    {
      USB.println("on");      
    }
    else
    {
      USB.println("off");
    }
  }
  else 
  {
    USB.print(F("14.2. Get automatic reply status error = ")); 
    USB.println(error, DEC);
  }

  
  //////////////////////////////////////////////
  // 15. Save configuration
  //////////////////////////////////////////////
  
  error = LoRaWAN.saveConfig();

  // Check status
  if( error == 0 ) 
  {
    USB.println(F("15. Save configuration OK"));     
  }
  else 
  {
    USB.print(F("15. Save configuration error = ")); 
    USB.println(error, DEC);
  }

  USB.println(F("------------------------------------"));
  USB.println(F("Now the LoRaWAN module is ready for"));
  USB.println(F("joining networks and send messages."));
  USB.println(F("Please check the next examples..."));
  USB.println(F("------------------------------------\n"));

  error = LoRaWAN.OFF(SOCKET);
  // Check status
  if( error == 0 ) 
  {
    USB.println(F("4. Switch OFF OK"));     
  }
  else 
  {
    USB.print(F("4. Switch OFF error = ")); 
    USB.println(error, DEC);
  }
}


