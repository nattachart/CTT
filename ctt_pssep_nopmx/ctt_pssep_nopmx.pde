#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>

Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);

float concentration1;	// Stores the concentration level in ppm
float concentration2;
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa

float temporary = 0;
float sum = 0;
int denominator = 0;

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

    USB.println(F("Entering for loop..."));
    for(int i = 1; i < 10; i++){
        USB.print(F("i: "));
        USB.println(i, DEC);
        
        temporary = CO2.getConc();
        
        USB.print(F("Temporary measurement was "));
        USB.println(temporary);
        if(temporary > 0){
            sum += temporary;
            denominator += 1;  
        }
        delay(10000);
    }
    
    if(sum > 0 && denominator > 0){
        concentration1 = sum / denominator;
    } else {
        concentration1 = -9999.00;  
    }
    
    USB.print(F("Sum is "));
    USB.println(sum);
    USB.print(F("Denominator is "));
    USB.println(denominator);
    USB.print(F("There concentration1 is equal to "));
    USB.println(concentration1);    
    
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

