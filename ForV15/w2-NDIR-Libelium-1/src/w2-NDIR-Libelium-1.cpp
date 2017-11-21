#include <Waspmote.h>
#include <WaspSensorCities_PRO.h>
#include <WaspSensorGas_Pro.h>

Gas gas_PRO_sensor(SOCKET_B);

float concentration;   // Stores the concentration level in ppm
float temperature;   // Stores the temperature in ºC
float humidity;      // Stores the realitve humidity in %RH
float pressure;      // Stores the pressure in Pa

void setup()
{
}   

void loop()
{      
	///////////////////////////////////////////
	// 1. Power on  sensors
	/////////////////////////////////////////// 

	// Power on the socket B for the gas sensor
	SensorCitiesPRO.ON(SOCKET_B);
	// Power on the socket E for the temperature sensor
	SensorCitiesPRO.ON(SOCKET_E);
	// Power on the sensor.
	// If the gases PRO board is off, turn it on automatically.
	gas_PRO_sensor.ON();

	USB.println("Sleep 1");
	digitalWrite(SCP_I2C_MAIN_EN, LOW);

	// To reduce the battery consumption, use deepSleep instead delay
	// After 2 minutes, Waspmote wakes up thanks to the RTC Alarm
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	digitalWrite(SCP_I2C_MAIN_EN, HIGH);

	///////////////////////////////////////////
	// 2. Read sensors
	/////////////////////////////////////////// 

	// Read the sensor and compensate with the temperature internally
	concentration = gas_PRO_sensor.getConc();

	// Read enviromental variables
	temperature = gas_PRO_sensor.getTemp();
	humidity = gas_PRO_sensor.getHumidity();
	pressure = gas_PRO_sensor.getPressure();

	// And print the values via USB
	USB.println(F("***************************************"));
	USB.print(F("Gas concentration: "));
	USB.print(concentration);
	USB.println(F(" ppm"));
	USB.print(F("Temperature: "));
	USB.print(temperature);
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print(humidity);
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(pressure);
	USB.println(F(" Pa"));

	///////////////////////////////////////////
	// 3. Power off sensors
	/////////////////////////////////////////// 

	// Power off the NDIR sensor.
	gas_PRO_sensor.OFF();
	// Power off the socket 1
	SensorCitiesPRO.OFF(SOCKET_B);
	// Power off the socket 2
	SensorCitiesPRO.OFF(SOCKET_E);

	///////////////////////////////////////////
	// 4. Sleep
	///////////////////////////////////////////
	USB.println("Sleep 2");
	digitalWrite(SCP_I2C_MAIN_EN, LOW);

	// Go to deepsleep.    
	// After 3 minutes, Waspmote wakes up thanks to the RTC Alarm
	PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}
