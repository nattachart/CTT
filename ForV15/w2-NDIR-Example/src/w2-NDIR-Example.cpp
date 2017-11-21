/*  
 *  ------------ [SCP_v30_02] - NDIR gas sensors ------------
 *  
 *  Explanation: This is the basic code to manage and read the NDIR
 *  gas sensor with Smart Cities PRO board. 
 *  These sensors include: CO2. Cycle time: 5 minutes
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify  
 *  it under the terms of the GNU General Public License as published by  
 *  the Free Software Foundation, either version 3 of the License, or  
 *  (at your option) any later version.  
 *   
 *  This program is distributed in the hope that it will be useful,  
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of  
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
 *  GNU General Public License for more details.  
 *   
 *  You should have received a copy of the GNU General Public License  
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.  
 * 
 *  Version:           3.1
 *  Design:            David Gascón 
 *  Implementation:    Alejandro Gállego
 */

#include <Waspmote.h>
#include <WaspSensorCities_PRO.h>
#include <WaspSensorGas_Pro.h>

/*
 * Define object for sensor: gas_PRO_sensor
 * Input to choose board socket. 
 * Waspmote OEM. Possibilities for this sensor:
 * 	- SOCKET_1 
 * 	- SOCKET_3
 * 	- SOCKET_5
 * P&S! Possibilities for this sensor:
 * 	- SOCKET_B
 * 	- SOCKET_C
 * 	- SOCKET_F
 */
Gas gas_PRO_sensor(SOCKET_B);

float concentration;	// Stores the concentration level in ppm
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa

void setup()
{
	USB.println(F("NDIR CO2 example"));
	USB.println(F("A temperature, humidity and pressure sensor in socket 2 is also required"));

}	


void loop()
{		
	///////////////////////////////////////////
	// 1. Power on  sensors
	///////////////////////////////////////////  

	// Power on the socket 1 for the gas sensor
	SensorCitiesPRO.ON(SOCKET_B);
	// Power on the socket 2 for the temperature sensor
	SensorCitiesPRO.ON(SOCKET_E);
	// Power on the NDIR sensor. 
	// If the gases PRO board is off, turn it on automatically.
	gas_PRO_sensor.ON();

	// NDIR gas sensor needs a warm up time at least 120 seconds	
	// To reduce the battery consumption, use deepSleep instead delay
	// After 2 minutes, Waspmote wakes up thanks to the RTC Alarm
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);


	///////////////////////////////////////////
	// 2. Read sensors
	///////////////////////////////////////////  

	// Read the NDIR sensor and compensate with the temperature internally
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

	// Go to deepsleep. 	
	// After 3 minutes, Waspmote wakes up thanks to the RTC Alarm
	digitalWrite(SCP_I2C_MAIN_EN, LOW);
	delay(30000);
	PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}

