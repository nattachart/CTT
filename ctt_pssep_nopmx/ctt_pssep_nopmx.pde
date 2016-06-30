#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>

Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);

float concentration1;	// Stores the concentration level in ppm
float concentration2;
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa

char node_ID[] = "CTT";

void setup()
{
    USB.println(F("CTT"));
    // Set the Waspmote ID
    frame.setID(node_ID);  
}	


void loop()
{		
    CO2.ON();
    NO2.ON();
    PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    
    concentration1 = CO2.getConc();
    concentration2 = NO2.getConc();
    temperature = CO2.getTemp(1);
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();

    // And print the values via USB
    USB.println(F("***************************************"));
    USB.print(F("Gas concentration: "));
    USB.print(concentration1);
    USB.println(F(" ppm"));
    USB.print(F("Gas concentration: "));
    USB.print(concentration2);
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

    CO2.OFF();
    NO2.OFF();

    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_GP_CO2, concentration1);
    frame.addSensor(SENSOR_GP_NO2, concentration2);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);	
    frame.showFrame();

    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}

