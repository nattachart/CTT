/* To be able to compile this program, new sensors, i.e., 
   - SENSOR_BATT_VOLT
   - SENSOR_BATT_ADC
   - SENSOR_CHARGE_STATUS
   - SENSOR_SOLAR_CHARGE_CURRENT
   have to be added to Waspmote's library file WaspFrameConstantsv15.h.
   This was done in the file in the directory 'modified-waspmote-libraries'.
 */
#define VERSION 3

#define PORT 3 //Port to use in Back-End: from 1 to 223
#define SOCKET SOCKET0

#define MAX_TEMP 60
#define MIN_TEMP -40
#define MAX_PRES 200000
#define MIN_PRES 50000
#define MAX_HUM 100
#define MIN_HUM 0
#define MAX_CO2 1000
#define MIN_CO2 50
#define MAX_BATT_VOLT 5
#define MIN_BATT_VOLT 0

#define MAX_SENSE_COUNT 10

#define MAX_TEST_COUNT 255

#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include "configParams.h"

float itmTemperature, temperature;  // Stores the temperature in ºC
float itmHumidity, humidity;   // Stores the realitve humidity in %RH
float itmPressure, pressure;   // Stores the pressure in Pa
float itmCO2, itmNO2, co2Concentration, no2Concentration;
float pm1, pm2_5, pm10;
float itmBatteryVoltage, batteryVoltage;
int batteryLevel, batteryADCLevel;
bool chargeStatus;
uint16_t itmChargeCurrent, chargeCurrent;
uint8_t testCount;

int i;

int status;
int measure;

Gas co2(SOCKET_A);

uint8_t errorLW;

int senseCount;

void configureLoRaWAN();
int getBatteryADCLevel();
void frequencyConfiguration();
uint8_t hexCharsToByte(char leftHexC, char rightHexC);

void setup()
{
	configureLoRaWAN();
	frame.setID(DEVICE_ID);
	testCount = 0;
}

void loop()
{
	//if(testCount == MAX_TEST_COUNT)
		//testCount = 0;

	batteryLevel = PWR.getBatteryLevel();
#ifdef SHOW_BATT_LEVEL
	USB.print("Battery: ");
	USB.println(batteryLevel);
#endif
	if(batteryLevel > 40)
	{
		co2.ON();
		PWR.deepSleep("00:00:02:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
		co2Concentration = temperature = humidity = pressure = batteryVoltage = chargeCurrent = 0;
		senseCount = 0;

		while(senseCount < MAX_SENSE_COUNT)
		{
			//Sense the values and start it all over again if there is a value out of range.
			itmCO2 = co2.getConc();
			if(itmCO2 < MIN_CO2 || itmCO2 > MAX_CO2)
				continue;
			itmTemperature = co2.getTemp();
			if(itmTemperature < MIN_TEMP || itmTemperature > MAX_TEMP)
				continue;
			itmHumidity = co2.getHumidity();
			if(itmHumidity < MIN_HUM || itmHumidity > MAX_HUM)
				continue;
			itmPressure = co2.getPressure();
			if(itmPressure < MIN_PRES || itmPressure > MAX_PRES)
				continue;
			itmBatteryVoltage = PWR.getBatteryVolts();
			if(itmBatteryVoltage < MIN_BATT_VOLT || itmBatteryVoltage > MAX_BATT_VOLT)
				continue;

			co2Concentration += itmCO2;
			temperature += itmTemperature;
			humidity += itmHumidity;
			pressure += itmPressure;
			//Do not accumulate the following 2 values.
			batteryVoltage = itmBatteryVoltage;
			chargeCurrent = 0;

			senseCount++;
		}


		co2.OFF();

		co2Concentration /= MAX_SENSE_COUNT;
		temperature /= MAX_SENSE_COUNT;
		humidity /= MAX_SENSE_COUNT;
		pressure /= MAX_SENSE_COUNT;

		//Dumb values
		no2Concentration = pm1 = pm2_5 = pm10 = 0;

		chargeStatus = 1;

		//Create a new frame
		frame.createFrame(BINARY);
    frame.addSensor(SENSOR_BAT, (int)testCount);
    frame.addSensor(SENSOR_GP_CO2, (double)co2Concentration);
/*
		frame.addSensor(SW_VERSION, (uint16_t)VERSION);
		//frame.addSensor(SENSOR_FLAGS, (uint8_t)testCount);
		frame.addSensor(SENSOR_FLAGS, (uint8_t)chargeStatus);
		//frame.addSensor(SENSOR_BATT_ADC, batteryADCLevel);
		frame.addSensor(SENSOR_BATT_VOLT, (double)batteryVoltage);
		frame.addSensor(SENSOR_SOLAR_CHARGE_CURRENT, chargeCurrent);
		frame.addSensor(SENSOR_GP_CO2, (double)co2Concentration);
		frame.addSensor(SENSOR_GP_TC, (double)temperature);
		frame.addSensor(SENSOR_GP_HUM, (double)humidity);
		frame.addSensor(SENSOR_GP_PRES, (double)pressure);
		frame.addSensor(SENSOR_GP_PM1, (double)pm1);
		frame.addSensor(SENSOR_GP_PM2_5, (double)pm2_5);
		frame.addSensor(SENSOR_GP_PM10, (double)pm10);
		frame.addSensor(SENSOR_GP_NO2, (double)no2Concentration);
*/
	#ifdef _DEBUG
		frame.showFrame();
	#endif
		//Switch on LoRaWAN
		errorLW = LoRaWAN.ON(SOCKET);

		frequencyConfiguration();

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
			//Send unconfirmed packet
			errorLW = LoRaWAN.sendUnconfirmed(PORT, frame.buffer, frame.length);

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
	#ifdef _DEBUG
				USB.println(F("3. Send Unconfirmed packet OK")); 
				if (LoRaWAN._dataReceived)
				{ 
					USB.print(F("   There's data on port number "));
					USB.print(LoRaWAN._port,DEC);
					USB.print(F(".\r\n   Data: "));
          for(i=0; i < 101; i++){
            USB.print(i);
            USB.print(":");
					  USB.print(LoRaWAN._data[i]);
            USB.print(",");
          }
          USB.println("");
					testCount = (uint8_t)hexCharsToByte(LoRaWAN._data[0], LoRaWAN._data[1]); //Test only the first character
				}
       USB.print("testCount: ");
       USB.println((int)testCount);
	#endif
			}
			else 
			{
	#ifdef _DEBUG
				USB.print(F("3. Send Unconfirmed packet error = ")); 
				USB.println(errorLW, DEC);
	#endif
			}
		}
		else
		{
	#ifdef _DEBUG
			USB.print(F("2. Join network error = ")); 
			USB.println(errorLW, DEC);
	#endif
		}
		
	#ifdef _DEBUG
		errorLW = LoRaWAN.getRadioFreq();
		if(errorLW == 0)
		{
			USB.print(F("Operating radio frequency: "));
			USB.println(LoRaWAN._radioFreq);
		}
		else
			USB.print(F("Could not get the radio frequency."));
		errorLW = LoRaWAN.getRadioFreqDeviation();
		if(errorLW == 0)
		{
			USB.print(F("Operating radio frequency deviation: "));
			USB.println(LoRaWAN._radioFreqDev);
		}
		else
			USB.print(F("Could not get the radio frequency deviation."));
		errorLW = LoRaWAN.getRadioMode();
		errorLW = LoRaWAN.getRadioPower();
		if(errorLW == 0)
		{
			USB.print(F("Operating radio power: "));
			USB.println(LoRaWAN._radioPower);
		}
		else
			USB.print(F("Could not get the radio power."));
		if(errorLW == 0)
		{
			USB.print(F("Operating radio mode: "));
			USB.println(LoRaWAN._radioMode);
		}
		else
			USB.print(F("Could not get the radio mode."));
		errorLW = LoRaWAN.getRadioBW();
		if(errorLW == 0)
		{
			USB.print(F("Operating radio bandwidth: "));
			USB.println(LoRaWAN._radioBW);
		}
		else
			USB.print(F("Could not get the radio bandwidth."));
		errorLW = LoRaWAN.getRadioSF();
		if(errorLW == 0)
		{
			USB.print(F("Operating radio spreading factor: "));
			USB.println(LoRaWAN._radioSF);
		}
		else
			USB.print(F("Could not get the radio spreading factor."));
	#endif

		errorLW = LoRaWAN.OFF(SOCKET);
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
		PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  	}
	else
		PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
	
	//testCount++;
}

uint8_t hexCharToInt(char c){
  switch(c){
    case '0': return 0;
    case '1': return 1;
    case '2': return 2;
    case '3': return 3;
    case '4': return 4;
    case '5': return 5;
    case '6': return 6;
    case '7': return 7;
    case '8': return 8;
    case '9': return 9;
    case 'A': case 'a': return 10;
    case 'B': case 'b': return 11;
    case 'C': case 'c': return 12;
    case 'D': case 'd': return 13;
    case 'E': case 'e': return 14;
    case 'F': case 'f': return 15;
  }
}

uint8_t hexCharsToByte(char leftHexC, char rightHexC){
  uint8_t leftHex = hexCharToInt(leftHexC);
  uint8_t rightHex = hexCharToInt(rightHexC);
  uint8_t num = (leftHex << 4) | rightHex;
  return num;
}

int getBatteryADCLevel()
{
	int level=0;
	pinMode(BAT_MONITOR_PW,OUTPUT);
	digitalWrite(BAT_MONITOR_PW,HIGH);
	level=analogRead(0);
	digitalWrite(BAT_MONITOR_PW,LOW);
	return level;
}

void frequencyConfiguration()
{
	//LoRaWAN must be turned on before this function is called.
	//This function depends on the constant 'LW_CH' and the array 'lwFreqs' in configParams.h.
	int ch;
	for(ch=1; ch <= LW_CH; ch++)
	{
		errorLW = LoRaWAN.setChannelFreq(ch, lwFreqs[ch-1]);
#ifdef _DEBUG
		if(errorLW == 0){
			USB.print(F("The channel "));     
			USB.print(ch);
			USB.print(F(" is set to "));
			USB.print(lwFreqs[ch-1]/1000000.0);
			USB.println(F(" MHz."));
		} else {
			USB.print(F("Error when setting the frequency channel ")); 
			USB.print(ch);
			USB.print(F(". Error code: "));
			USB.println(errorLW, DEC);
		}
#endif
	}
}

void configureLoRaWAN()
{
	//////////////////////////////////////////////
	// 1. switch on
	//////////////////////////////////////////////

	uint8_t error = LoRaWAN.ON(SOCKET);
#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 2. Reset to factory default values
	//////////////////////////////////////////////

	error = LoRaWAN.factoryReset();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 3. Set/Get Device EUI
	//////////////////////////////////////////////

	// Set Device EUI
	error = LoRaWAN.setDeviceEUI(DEVICE_EUI);

#ifdef _DEBUG
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
#endif

	// Get Device EUI
	error = LoRaWAN.getDeviceEUI();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 4. Set/Get Device Address
	//////////////////////////////////////////////

	// Set Device Address
	error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);

#ifdef _DEBUG
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
#endif

	// Get Device Address
	error = LoRaWAN.getDeviceAddr();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 5. Set Network Session Key
	//////////////////////////////////////////////

	error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 6. Set Application Session Key
	//////////////////////////////////////////////

	error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 7. Set retransmissions for uplink confirmed packet
	//////////////////////////////////////////////

	// set retries
	error = LoRaWAN.setRetries(7);

#ifdef _DEBUG
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
#endif

	// Get retries
	error = LoRaWAN.getRetries();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 8. Set application key
	//////////////////////////////////////////////

	error = LoRaWAN.setAppKey(APP_KEY);

#ifdef _DEBUG
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
#endif

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

#ifdef _DEBUG
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
#endif  

	// Get ADR
	error = LoRaWAN.getADR();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 14. Set Automatic Reply
	//////////////////////////////////////////////

	// set AR
	error = LoRaWAN.setAR("on");

#ifdef _DEBUG
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
#endif  
	// Get AR
	error = LoRaWAN.getAR();

#ifdef _DEBUG
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
#endif

	//////////////////////////////////////////////
	// 15. Save configuration
	//////////////////////////////////////////////

	error = LoRaWAN.saveConfig();

#ifdef _DEBUG
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
#endif

	error = LoRaWAN.OFF(SOCKET);

#ifdef _DEBUG
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
#endif
}


