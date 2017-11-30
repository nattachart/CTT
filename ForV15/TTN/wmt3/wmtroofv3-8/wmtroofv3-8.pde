/* To be able to compile this program, new sensors, i.e., 
   - SENSOR_BATT_VOLT
   - SENSOR_BATT_ADC
   - SENSOR_CHARGE_STATUS
   - SENSOR_SOLAR_CHARGE_CURREN
   have to be added to Waspmote's library file WaspFrameConstantsv15.h.
   This was done in the file in the directory 'modified-waspmote-libraries'.
 */
#define VERSION 13

// Concentratios used in calibration process (PPM Values)
#define POINT1_PPM_CO2 300.0  //   <-- Normal concentration in air
#define POINT2_PPM_CO2 1000.0
#define POINT3_PPM_CO2 3000.0

// Calibration vVoltages obtained during calibration process (Volts)
#define POINT1_VOLT_CO2 0.300
#define POINT2_VOLT_CO2 0.350
#define POINT3_VOLT_CO2 0.380

// Define the number of calibration points
#define CAL_POINTS 3

#define BATT_LEVEL F("battery_level=")
#define BATT_VOLT F("battery_voltage=")
#define BATT_ADC F("battery_ADC_value=")
#define TEMP F("temperature=")
#define HUMID F("humidity=")
#define PRESS F("pressure=")
#define CO2 F("co2=")
#define NO2 F("no2=")
#define START F("#")
#define DELIM F(",")
#define PMX_BATT_TRES 60 //The least battery percentage PMX is allowed to function
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
#define MAX_CHARGE_CURRENT 500
#define MIN_CHARGE_CURRENT 0

#define MAX_SENSE_COUNT 10

#include <WaspSensorGas_v30.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include "configParams.h"

float itmTemperature, temperature, accuTemperature;  // Stores the temperature in ºC
float itmHumidity, humidity, accuHumidity;   // Stores the realitve humidity in %RH
float itmPressure, pressure, accuPressure;   // Stores the pressure in Pa
float itmCO2, itmNO2, co2Concentration, no2Concentration, accuCO2, accuNO2;
float pm1, pm2_5, pm10;
float itmBatteryVoltage, batteryVoltage, accuBatteryVoltage;
int batteryLevel, batteryADCLevel;
bool chargeStatus, battVoltOutOfRange;
uint16_t itmChargeCurrent, chargeCurrent, accuChargeCurrent;
float chargeCurrentCount;

int status;
int measure;

int accuCount;
int co2AccuCount, tempAccuCount, presAccuCount, humAccuCount, voltAccuCount, chgAccuCount;
int co2Count, tempCount, presCount, humCount, voltCount, chgCount;
bool outliers;

float concentrations[] = { POINT1_PPM_CO2, POINT2_PPM_CO2, POINT3_PPM_CO2 };
float voltages[] =       { POINT1_VOLT_CO2, POINT2_VOLT_CO2, POINT3_VOLT_CO2 };

uint8_t errorLW;

int senseCount;

char sBuffer[100];

uint8_t i;
uint16_t downSeq, nodeMode, transmittedNodeMode;

typedef void (*routine)(void);

// CO2 Sensor must be connected physically in SOCKET_2 (SOCKET_E on Smart Environment P&S)
CO2SensorClass CO2Sensor;

void configureLoRaWAN();
int getBatteryADCLevel();
void configureFrequency();
uint8_t hexCharsToByte(char leftHexC, char rightHexC);
void transmitAndReceive();
void sample(int minutes, int seconds);
void s40PercentOutof5Min(); //for mode 0
void s50PercentOutof4Min(); //for mode 1
void s60PercentOutof10MinSuper(); //for mode 2
void s80PercentOutof2_5Min(); //for mode 3
void s80PercentOutof5MinSuper(); //for mode 4
void s20PercentOutof10Min(); //for mode 5
void s13PercentOutof15Min(); //for mode 6
void s10PercentOutof20Min(); //for mode 7

void sOnlyBattAndCharge10Min(); //for mode 8 (just to transmit the battery level and charging current every 10 minutes)
void sOnlyBattAndCharge60Min(); //for mode 9 (just to transmit the battery level and charging current every 60 minutes)

#define MAX_FN_IDX 7
#define DEFAULT_FN_IDX 5
#define BC_10_IDX 8
#define BC_60_IDX 9
#define BC_10_TRES 75 //The threshold of the battery level to apply mode 8
#define BC_60_TRES 60 //The threshold of the battery level to apply mode 9
#define BATT_DEAD_TRES 40
static routine samplingRoutines[] = {s40PercentOutof5Min, 
					s50PercentOutof4Min,
					s60PercentOutof10MinSuper,
					s80PercentOutof2_5Min,
					s80PercentOutof5MinSuper,
					s20PercentOutof10Min,
					s13PercentOutof15Min,
					s10PercentOutof20Min,
					sOnlyBattAndCharge10Min,
					sOnlyBattAndCharge60Min};

void setup()
{
	configureLoRaWAN();
	frame.setID(DEVICE_ID);
	downSeq = 0;
	nodeMode = DEFAULT_FN_IDX;
	CO2Sensor.setCalibrationPoints(voltages, concentrations, CAL_POINTS);
}

void loop()
{
	batteryLevel = PWR.getBatteryLevel();
#ifdef SHOW_BATT_LEVEL
	USB.print("Batterry level (%): ");
	USB.println(batteryLevel);
#endif
#ifdef _DEBUG
	USB.print("Mode: ");
	USB.println(nodeMode);
	USB.print("Downling Sequence #: ");
	USB.println(downSeq);
#endif
	//Also check for the 'reflex' against the battery level
	if(batteryLevel <= BC_10_TRES && batteryLevel > BC_60_TRES)
	{
		transmittedNodeMode = BC_10_IDX;
		samplingRoutines[BC_10_IDX]();
	}
	else if(batteryLevel <= BC_60_TRES && batteryLevel > BATT_DEAD_TRES)
	{
		transmittedNodeMode = BC_60_IDX;
		samplingRoutines[BC_60_IDX]();
	}
	else if(batteryLevel > BC_10_TRES)
	{
		if(nodeMode >= 0 && nodeMode <= MAX_FN_IDX)
		{
			transmittedNodeMode = nodeMode;
			samplingRoutines[nodeMode]();
		}
		else
		{
			transmittedNodeMode = DEFAULT_FN_IDX;
			samplingRoutines[DEFAULT_FN_IDX]();
		}
	}
	else //This means batteryLevel <= BATT_DEAD_TRES
		PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

void transmitAndReceive()
{
	//Create a new frame
	frame.createFrame(BINARY);
	frame.addSensor(SW_VERSION, (uint16_t)VERSION);
	frame.addSensor(SENSOR_FLAGS, (uint8_t)chargeStatus);
	//frame.addSensor(SENSOR_BATT_ADC, batteryADCLevel);
	frame.addSensor(SENSOR_BATT_VOLT, (double)batteryVoltage);
	frame.addSensor(SENSOR_SOLAR_CHARGE_CURRENT, chargeCurrent);
	frame.addSensor(SENSOR_GASES_PRO_CO2, (double)co2Concentration);
	frame.addSensor(SENSOR_GASES_PRO_TC, (double)temperature);
	frame.addSensor(SENSOR_GASES_PRO_HUM, (double)humidity);
	frame.addSensor(SENSOR_GASES_PRO_PRES, (double)pressure);
	frame.addSensor(SENSOR_GASES_PRO_PM1, (double)pm1);
	frame.addSensor(SENSOR_GASES_PRO_PM2_5, (double)pm2_5);
	frame.addSensor(SENSOR_GASES_PRO_PM10, (double)pm10);
	frame.addSensor(SENSOR_GASES_PRO_NO2, (double)no2Concentration);
	frame.addSensor(SENSOR_BATT_ADC, downSeq);
	frame.addSensor(SENSOR_BATT_ADC, transmittedNodeMode);
#ifdef _DEBUG
	frame.showFrame();
#endif
	//Switch on LoRaWAN
	errorLW = LoRaWAN.ON(SOCKET);

	//Set channels frequencies and the tranmission power.
	configureFrequency();
	LoRaWAN.setPower(TRANSMISSION_POWER);

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
#endif
			if (LoRaWAN._dataReceived)
			{ 
#ifdef _DEBUG
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
#endif
				//Little endien
				downSeq = (uint16_t)hexCharsToByte(LoRaWAN._data[0], LoRaWAN._data[1]); //Donwlink sequence number's LSB
				downSeq |= ((uint16_t)hexCharsToByte(LoRaWAN._data[2], LoRaWAN._data[3])) << 8; //Downlink sequence number's MSB 
				nodeMode = (uint16_t)hexCharsToByte(LoRaWAN._data[4], LoRaWAN._data[5]); //Mode number's LSB
				nodeMode |= ((uint16_t)hexCharsToByte(LoRaWAN._data[6], LoRaWAN._data[7])) << 8; //Mode number's MSB 
			}
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
}

void sample(int minutes, int seconds, bool onlyBattAndCharge)
{
	if(!onlyBattAndCharge)
	{
		// Switch ON and configure the Gases Board
		Gases.ON();  
		// Switch ON the CO2 Sensor SOCKET_2
		CO2Sensor.ON();
		sprintf(sBuffer, "00:00:%02d:%02d", minutes, seconds);
		PWR.deepSleep(sBuffer, RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
	}

	co2Concentration = temperature = humidity = pressure = batteryVoltage = chargeCurrent = 0;
	chargeCurrentCount = 0;
	battVoltOutOfRange = true;
	co2Count = tempCount = presCount = humCount = voltCount = chgCount = 0;

	if(!onlyBattAndCharge)
	{
		senseCount = 0;
		outliers = false;
		while(senseCount < MAX_SENSE_COUNT)
		{
			itmCO2 = CO2Sensor.readConcentration();
	#ifdef _DEBUG
			USB.print("co2: ");
			USB.println(itmCO2);
	#endif
			if(itmCO2 < MIN_CO2 || itmCO2 > MAX_CO2){
				outliers = true;
			}
			else{
				co2Concentration += itmCO2;
				co2Count++;
			}
			senseCount++;
		}
		if(co2Count > 0)
			co2Concentration /= (co2Count);

		senseCount = 0;
		outliers = false;
		while(senseCount < MAX_SENSE_COUNT)
		{
			itmTemperature = Gases.getTemperature();
	#ifdef _DEBUG
			USB.print("temperature: ");
			USB.println(itmTemperature);
	#endif
			if(itmTemperature < MIN_TEMP || itmTemperature > MAX_TEMP){
				outliers = true;
			}
			else{
				temperature += itmTemperature;
				tempCount++;
			}
			senseCount++;
		}
		if(tempCount > 0)
			temperature /= (tempCount);

		senseCount = 0;
		outliers = false;
		while(senseCount < MAX_SENSE_COUNT)
		{
			itmHumidity = Gases.getHumidity();
	#ifdef _DEBUG
			USB.print("humidity: ");
			USB.println(itmHumidity);
	#endif
			if(itmHumidity < MIN_HUM || itmHumidity > MAX_HUM){
				outliers = true;
			}
			else{
				humidity += itmHumidity;
				humCount++;
			}
			senseCount++;
		}
		if(humCount > 0)
			humidity /= (humCount);

		senseCount = 0;
		outliers = false;
		while(senseCount < MAX_SENSE_COUNT)
		{
			itmPressure = Gases.getPressure();
	#ifdef _DEBUG
			USB.print("pressure: ");
			USB.println(itmPressure);
	#endif
			if(itmPressure < MIN_PRES || itmPressure > MAX_PRES){
				outliers = true;
			}
			else{
				pressure += itmPressure;
				presCount++;
			}
			senseCount++;
		}
		if(presCount > 0)
			pressure /= (presCount);
	}

	senseCount = 0;
	outliers = false;
	while(senseCount < MAX_SENSE_COUNT)
	{
		itmBatteryVoltage = PWR.getBatteryVolts();
#ifdef _DEBUG
		USB.print("volt: ");
		USB.println(itmBatteryVoltage);
#endif
		if((itmBatteryVoltage < MIN_BATT_VOLT || itmBatteryVoltage > MAX_BATT_VOLT) && battVoltOutOfRange){
			battVoltOutOfRange = true;
			outliers = true;
		}
		else if(battVoltOutOfRange)
		{
			battVoltOutOfRange = false;
			batteryVoltage += itmBatteryVoltage;
			voltCount++;
		}
		senseCount++;
	}
	if(voltCount > 0)
		batteryVoltage /= (voltCount);

	senseCount = 0;
	outliers = false;
	while(senseCount < MAX_SENSE_COUNT)
	{
		itmChargeCurrent = PWR.getBatteryCurrent();
#ifdef _DEBUG
		USB.print("charge current: ");
		USB.println(itmChargeCurrent);
#endif
		if(itmChargeCurrent < MIN_CHARGE_CURRENT || itmChargeCurrent > MAX_CHARGE_CURRENT){
			outliers = true;
		}
		if(itmChargeCurrent > 0)
		{
			chargeCurrent += itmChargeCurrent;
			chargeCurrentCount++;
		}
		senseCount++;
	}
	if(!onlyBattAndCharge)
	{
		Gases.OFF();
		CO2Sensor.OFF();
	}

	if(chargeCurrentCount > 0)
		chargeCurrent /= chargeCurrentCount;

	//Dumb values
	no2Concentration = pm1 = pm2_5 = pm10 = 0;

	//batteryADCLevel = getBatteryADCLevel();
	chargeStatus = PWR.getChargingState();
}

void initializeValueAccumulatingVariables()
{
	accuCount = 0;
	accuTemperature = accuHumidity = accuPressure = accuCO2 = accuNO2 = accuBatteryVoltage = accuChargeCurrent = 0;
}

void accumulateValues()
{
	accuCount++;
	accuTemperature += temperature;
	accuHumidity += humidity;
	accuPressure += pressure;
	accuCO2 += co2Concentration;
	accuNO2 += no2Concentration;
	accuBatteryVoltage += batteryVoltage;
	accuChargeCurrent += chargeCurrent;
}

void averageValues()
{
	temperature = accuTemperature / accuCount;
	humidity = accuHumidity / accuCount;
	pressure = accuPressure / accuCount;
	co2Concentration = accuCO2 / accuCount;
	no2Concentration = accuNO2 / accuCount;
	batteryVoltage = accuBatteryVoltage / accuCount;
	chargeCurrent = accuChargeCurrent / accuCount;
}

void s40PercentOutof5Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s50PercentOutof4Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s60PercentOutof10MinSuper()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
	sample(2, 0, false);
	accumulateValues();
	PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s80PercentOutof2_5Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:00:30", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s80PercentOutof5MinSuper()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	PWR.deepSleep("00:00:00:30", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:00:30", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s20PercentOutof10Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:08:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s13PercentOutof15Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:13:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void s10PercentOutof20Min()
{
	initializeValueAccumulatingVariables();
	sample(2, 0, false);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:18:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void sOnlyBattAndCharge10Min()
{
	initializeValueAccumulatingVariables();
	sample(0, 0, true);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:00:10:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
void sOnlyBattAndCharge60Min()
{
	initializeValueAccumulatingVariables();
	sample(0, 0, true);
	accumulateValues();
	averageValues();
	transmitAndReceive();
	PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
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

void configureFrequency()
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
	/*
	   uint32_t freq = 867100000;

	   for (uint8_t ch = 3; ch <= 7; ch++)
	   {
	   error = LoRaWAN.setChannelFreq(ch, freq);
	   freq += 200000;

	// Check status
	if( error == 0 ) 
	{
	USB.println(F("9. Frequency channel set OK"));     
	}
	else 
	{
	USB.print(F("9. Frequency channel set error = ")); 
	USB.println(error, DEC);
	}
	}
	 */
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


