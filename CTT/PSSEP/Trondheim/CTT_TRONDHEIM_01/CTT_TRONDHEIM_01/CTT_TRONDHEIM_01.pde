//#include <WaspSensorCities_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspOPC_N2.h>

Gas CO2(SOCKET_B);
Gas NO2(SOCKET_C);
float co2concentration, accuCO2;
float no2concentration, accuNO2;
float temperature, accuTemperature;
float humidity, accuHumidity;
float pressure, accuPressure;
int batteryVoltage, accuBatteryVoltage;
uint8_t errorLoRaWAN;
uint8_t socket = SOCKET0;
char node_ID[] = "wmtroof1";
uint8_t PORT = 3; // Port to use in Back-End: from 1 to 223

typedef void (*routine)(void);

void s40PercentOutof5Min(); //for mode 0
void s50PercentOutof4Min(); //for mode 1
void s60PercentOutof10MinSuper(); //for mode 2
void s80PercentOutof2_5Min(); //for mode 3
void s80PercentOutof5MinSuper(); //for mode 4
void s20PercentOutof10Min(); //for mode 5
void s13PercentOutof15Min(); //for mode 6
void s10PercentOutof20Min(); //for mode 7

#define MAX_FN_IDX 7
#define DEFAULT_FN_IDX 5
static routine samplingRoutines[] = {s40PercentOutof5Min, 
					s50PercentOutof4Min,
					s60PercentOutof10MinSuper,
					s80PercentOutof2_5Min,
					s80PercentOutof5MinSuper,
					s20PercentOutof10Min,
					s13PercentOutof15Min,
					s10PercentOutof20Min};

uint8_t socketLoRaWAN = SOCKET0;

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT TRONDHEIM"));
    USB.println((int)PWR.getBatteryLevel());
    frame.setID(node_ID);
}


void loop() {
// Power on the the gas sensor socket
                SensorCitiesPRO.ON(SOCKET_B);
                // Power on the temperature sensor socket
                SensorCitiesPRO.ON(SOCKET_E);
                CO2.ON();
    // put your main code here, to run repeatedly:
    CO2.ON();
//    NO2.ON();
    PWR.deepSleep("00:00:02:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    battery = PWR.getBatteryLevel();
    if(battery < 40){
        while(battery < 40){
            PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
            battery = PWR.getBatteryLevel();
        }  
    }
    USB.print(F("Battery level: "));
    USB.println(battery, DEC);
//    NO2.autoGain();
    temperature = CO2.getTemp();
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();
    co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
//    no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
    CO2.OFF();
//    NO2.OFF();
    if(co2concentration <= 0){
        co2concentration = -99.0;
    }
//    if(no2concentration < 0){
//        no2concentration = -99.0;
//    }
    frame.createFrame(BINARY);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
//    frame.addSensor(SENSOR_GP_NO2, no2concentration);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);
    frame.addSensor(SENSOR_BAT, battery);
    frame.showFrame();
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    USB.print(F("Turning on lora. Value = "));
    USB.println(errorLoRaWAN, DEC);
    // Join network
    errorLoRaWAN = LoRaWAN.joinABP();
    USB.print(F("Joining. Value = "));
    USB.println(errorLoRaWAN, DEC);
    if (errorLoRaWAN == 0) 
    {
        errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data);   
        USB.print(F("Sending lora. Value = "));
        USB.println(errorLoRaWAN, DEC); 
    }
    errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
    USB.print(F("Turning off lora. Value = "));
    USB.println(errorLoRaWAN, DEC);
    PWR.deepSleep("00:00:04:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

void sample(int minutes, int seconds)
{
	/*
	// Power on the the gas sensor socket
	SensorCitiesPRO.ON(SOCKET_B);
	// Power on the temperature sensor socket
	SensorCitiesPRO.ON(SOCKET_E);
	*/
	CO2.ON();
	NO2.ON();
	sprintf(sBuffer, "00:00:%02d:%02d", minutes, seconds);
	PWR.deepSleep(sBuffer, RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	co2Concentration  = no2Concentration = temperature = humidity = pressure = batteryVoltage = 0;
	chargeCurrentCount = 0;
	battVoltOutOfRange = true;
	co2Count = tempCount = presCount = humCount = voltCount = chgCount = 0;

	temperature = CO2.getTemp();
	humidity = CO2.getHumidity();
	pressure = CO2.getPressure();
	co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
	no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);

	CO2.OFF();
	NO2.OFF();

	if(co2concentration <= 0){
		co2concentration = -99.0;
	}
	if(no2concentration < 0){
		no2concentration = -99.0;
	}
	/*
	// Power off the the gas sensor socket
	SensorCitiesPRO.OFF(SOCKET_B);
	// Power off the temperature sensor socket
	SensorCitiesPRO.OFF(SOCKET_E);
	*/
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
}
