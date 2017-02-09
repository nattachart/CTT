//#define _DEBUG
#include <WaspSensorGas_Pro.h>

Gas co2(SOCKET_A);

float concentration;  // Stores the concentration level in ppm
float temperature;  // Stores the temperature in ºC
float humidity;   // Stores the realitve humidity in %RH
float pressure;   // Stores the pressure in Pa

void setup()
{
}


void loop()
{
  PWR.deepSleep("00:00:00:05", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  co2.ON();
  PWR.deepSleep("00:00:00:06", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

  // Read the CO2 sensor and compensate with the temperature internally
  concentration = co2.getConc();

  // Read enviromental variables
  temperature = co2.getTemp();
  humidity = co2.getHumidity();
  pressure = co2.getPressure();

  PWR.deepSleep("00:00:00:04", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  co2.OFF();
  PWR.deepSleep("00:00:00:06", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
#ifdef _DEBUG
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
#endif
}
