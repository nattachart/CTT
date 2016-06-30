/*  
 *  ------------ [GP_02] - CO2 ------------
 *  
 *  Explanation: This is the basic code to manage and read the carbon dioxide
 *  (CO2) gas sensor. The concentration and the enviromental variables will be
 *  stored in a frame. Cycle time: 5 minutes
 *  
 *  Copyright (C) 2015 Libelium Comunicaciones Distribuidas S.L. 
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
 *  Version:           0.3
 *  Design:            David Gascón 
 *  Implementation:    Alejandro Gállego
 */
 
 //Include libraries here

//Library used for the gases pro board
#include <WaspSensorGas_Pro.h>

//Library used for the Waspmote Frame (to store data in a preformatted packet)
#include <WaspFrame.h>

/*
 * Define object for sensor: CO2
 * Input to choose board socket. 
 * Waspmote OEM. Possibilities for this sensor:
 * 	- SOCKET_1 
 * P&S! Possibilities for this sensor:
 * 	- SOCKET_A
 * 	- SOCKET_B
 * 	- SOCKET_C
 * 	- SOCKET_F
 */
Gas CO2(SOCKET_A);

float co2conc;	// Stores the concentration level in ppm
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa
int battery;

//parameters used in the measurement process
float temporary;
float sum;
int denominator;
int iteration;

//paramters used for storing error codes
int co2error;

char node_ID[] = "CTT_debug_node";

void setup()
{
    USB.println(F("CTT indoor debug"));
    // Set the Waspmote ID
    frame.setID(node_ID);  
}	


void loop()
{		
    //Make sure battery level is sufficient for taking measurements
    battery = PWR.getBatteryLevel();
    USB.print(F("Current battery level is "));
    USB.print(battery, DEC);
    USB.println("%");
    //checkBatteryLevel();

    //Turn sensors on
    co2error = CO2.ON();
    USB.print(F("CO2 sensor return the error code: "));
    USB.println(co2error);
    
    //Let the PSSEP sleep for some time while the sensors warm up
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

    //Take measurements 
    //readCo2sensor();
    co2conc = CO2.getConc();

    //The temperature, pressure and humidity sensor (BME280) is indirectly measured through either co2 or no2 sensors
    temperature = CO2.getTemp();
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();

    //turn sensors off
    CO2.OFF();
    
    // Display measurements on serial monitor
    USB.println(F("***************************************"));
    USB.print(F("Co2 concentration: "));
    USB.print(co2conc);
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

    //Turn off sensors in order to save battery
    CO2.OFF();

    // Create an ASCII frame - can create BINARY instead 
    // Not really necessary to create frame unless you're sending the data somewhere (in our case to a gateway
    // through the use of LoRaWAN)
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_GP_CO2, co2conc);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);	
    frame.showFrame();

    //Put the PSSEP into deepSleep mode between measurements in order to save battery 
    //Since this code is used for debugging only, it's not necessary to sleep as it would only make you have to wait...
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}


void checkBatteryLevel(){
    battery = PWR.getBatteryLevel();  
    if(battery < 40){
        PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
    }
}


void readCo2sensor(){
    //set measurement parameters to initial states
    iteration = 10;
    sum = 0;
    co2conc = 0;
    denominator = 0;
    while(iteration > 0){
        USB.print(F("Iteration #: "));
        USB.println(iteration, DEC);
        if(co2error == 1){
             temporary = CO2.getConc();
             USB.print(F("Measured concentration was "));
             USB.print(temporary);
             USB.println(F(" ppm."));
             if(temporary > 0){
                sum += temporary;
                USB.print(F("The sum is now "));
                USB.println(sum);
                denominator += 1;
                USB.print(F("The denominator is now "));
                USB.println(denominator);
            }
        } else {
            USB.println(F("Sensor never started correctly."));  
        }
        iteration -= 1;
    }
    co2conc = sum / denominator;
    USB.print(F("Total sum of measured concentrations is "));
    USB.print(sum);
    USB.println(F("."));
    USB.print(sum);
    USB.print(F(" divided by "));
    USB.print(denominator);
    USB.print(F(" is equal to "));
    USB.print(co2conc);
    USB.println(F("."));
  }

