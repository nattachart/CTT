/*
    ------ Waspmote Pro Code Example --------

    Explanation: This is the basic Code for Waspmote Pro

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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

#include <WaspSensorGas_Pro.h>
#include <WaspOPC_N2.h>

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

//Gas no2(SOCKET_A);
Gas co2(SOCKET_A);

void setup()
{
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

