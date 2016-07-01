#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>

//definition of gas sensors
Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);


//parameters used to hold concentrations and environmental parameters
float concentration1;	// Stores the concentration level in ppm
float concentration2;
float temperature;	// Stores the temperature in ºC
float humidity;		// Stores the realitve humidity in %RH
float pressure;		// Stores the pressure in Pa
int battery;

//parameters used for measurements of gases
float temporaryco2 = 0;
float sumco2 = 0;
int denominatorco2 = 0;

float temporaryno2 = 0;
float sumno2 = 0;
int denominatorno2 = 0;


//node ID contents
char node_ID[] = "CTT";

void setup()
{
    USB.println(F("CTT"));
    // Set the Waspmote ID
    frame.setID(node_ID);  
}	


void loop()
{
    //turn on sensors and set gain of NO2 to max since this is used for indoor debugging		
    CO2.ON();
    NO2.ON(LMP91000_GAIN_7);
    
    //set the PSSEP into deepSleep to let sensors warm up
    PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    
    battery = PWR.getBatteryLevel();
    USB.print(F("The battery level is currently at "));
    USB.print(battery);
    USB.println(F("%"));
    
    //start of measurement process for Co2 
    USB.println("********************************************************************");
    USB.println(F("Entering for loop for Co2 measurements..."));
    for(int i = 1; i < 11; i++){
        USB.print(F("i: "));
        USB.println(i, DEC);
        
        temporaryco2 = CO2.getConc();
        
        USB.print(F("Temporary measurement was "));
        USB.println(temporaryco2);
        if(temporaryco2 > 0){
            sumco2 += temporaryco2;
            denominatorco2 += 1;  
        }
        delay(10000);
    }
    
    if(sumco2 > 0 && denominatorco2 > 0){
        concentration1 = sumco2 / denominatorco2;
    } else {
        concentration1 = -9999.00;  
    }
    
    //print results of measurement process for Co2
    USB.print(F("Sum of Co2 measurements is "));
    USB.println(sumco2);
    USB.print(F("Denominator for Co2 measurements is "));
    USB.println(denominatorco2);
    USB.print(F("The average Co2 concentration is therefore equal to "));
    USB.println(concentration1);    
    
    
    //start of measurement process for no2
    USB.println("********************************************************************");
    USB.println(F("Entering for loop for No2 measurements..."));
    for(int j = 1; j < 11; j ++){
        USB.print(F("j: "));
        USB.println(j, DEC);
        
        
        temporaryno2 = NO2.getConc();
        
        USB.print(F("Temporary measurement was "));
        USB.println(temporaryno2);
        if(temporaryno2 > 0){
            sumno2 += temporaryno2;
            denominatorno2 += 1;   
        }
        delay(10000);
    }
   
    if(sumno2 > 0 && denominatorno2 > 0){
        concentration2 = sumno2 / denominatorno2;
    } else {
        concentration2 = -9999.00;
    } 
    
    //print results of No2 measurement process
    USB.print(F("Sum of No2 measurments is "));
    USB.println(sumno2);
    USB.print(F("Denominator for No2 measurments is "));
    USB.println(denominatorno2);
    USB.print(F("The average Co2 cocentration is therefore equal to "));
    USB.println(concentration2);
    USB.println("********************************************************************");
    
    //read the BME280 sensor for environmental parameters
    temperature = CO2.getTemp(1);
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();

    //Print all measured values
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

    //turn the sensors off
    CO2.OFF();
    NO2.OFF();

    //create a frame to hold all values
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_GP_CO2, concentration1);
    frame.addSensor(SENSOR_GP_NO2, concentration2);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);	
    frame.showFrame();
    
    //set measurement process parameters to intial values for the next cycle
    temporaryco2 = 0;
    sumco2 = 0;
    denominatorco2 = 0;
    temporaryno2 = 0;
    sumno2 = 0;
    denominatorno2 = 0;

    //put PSSEP into deepSleep to save battery 
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}

