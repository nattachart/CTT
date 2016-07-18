#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>

Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);

float co2concentration;
float no2concentration;
float temperature;
float humidity;
float pressure;
int battery;
float volts;

uint8_t co2error;
uint8_t no2error;
uint8_t errorLoRaWAN;
uint8_t socket = SOCKET0;

char node_ID[] = "Vejle_01";

char DEVICE_EUI[]  = "00000000D2ACEF0A";
char DEVICE_ADDR[] = "D2ACEF0A";
char NWK_SESSION_KEY[] = "BC306690133E39101194E7C4FA559C2F";
char APP_SESSION_KEY[] = "3045ADDDC67544C93F53DF1D2303112B";
char APP_KEY[] = "41D97468A7AE68499F3824959F84C2F3";
uint8_t PORT = 3; // Port to use in Back-End: from 1 to 223

uint8_t socketLoRaWAN = SOCKET0;

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Vejle"));
    frame.setID(node_ID);
    USB.println("********************************************************************");
}


void loop() {
    // put your main code here, to run repeatedly:
    co2error = CO2.ON();
    if(co2error == 1){
        USB.println(F("Co2 sensor started correctly."));  
    } else {
        USB.print(F("Error when starting Co2 sensor. Error code: "));
        USB.println(co2error);  
    }
    
    no2error = NO2.ON();
    if(no2error == 1){
        USB.println(F("No2 sensor started correctly."));
    } else {
        USB.print(F("Error when starting No2 sensor. Error code: "));
        USB.println(no2error);
    }
    
    USB.println(F("Warming up sensors for 2 minutes."));
    PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    
    battery = PWR.getBatteryLevel();
    USB.print(F("The current battery level is: "));
    USB.print(battery);
    if(battery < 40){
        USB.println(F("Not enough power left to take measurements."));
        while(battery < 40){
            USB.println(F("Sleeping for an hour."));
            PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
            battery = PWR.getBatteryLevel();
        }  
    } else {
        USB.println(F("Starting measurement process..."));  
    }
    
    NO2.autoGain();
    CO2.showSensorInfo();
    NO2.showSensorInfo();
    
    temperature = CO2.getTemp();
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();
    co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
    no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
    
    CO2.OFF();
    NO2.OFF();
    
    USB.println(F("***************************************"));
    USB.print(F("Co2 concentration: "));
    USB.print(co2concentration);
    USB.println(F(" ppm"));
    USB.print(F("No2 concentration: "));
    USB.print(no2concentration);
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
   
    if(co2concentration <= 0){
        co2concentration = -99.0;
    }
    
    if(no2concentration < 0){
        no2concentration = -99.0;
    }
    
    frame.createFrame(BINARY);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
    frame.addSensor(SENSOR_GP_NO2, no2concentration);
    frame.addSensor(SENSOR_BAT, battery);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);
    frame.showFrame();
    
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    if (errorLoRaWAN == 0) 
    {
        USB.println(F("LoRaWAN switch on: OK"));     
    }
    else 
    {
        USB.print(F("LoRaWAN switch on: error = ")); 
        USB.println(errorLoRaWAN, DEC);
    }
    // Join network
    errorLoRaWAN = LoRaWAN.joinABP();
    if (errorLoRaWAN == 0) 
    {
        USB.println(F("LoRaWAN join network: OK")); 
        // Send confirmed packet 1
        errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data);
        /* Error messages:
         * '6' : Module hasn't joined a network
         * '5' : Sending error
         * '4' : Error with data length
         * '2' : Module didn't response
         * '1' : Module communication error   
         */
        if (errorLoRaWAN == 0) 
        {
            USB.println(F("LoRaWAN send confirmed packet 1: OK"));     
        }
        else 
        {
            USB.print(F("LoRaWAN send confirmed packet 1: error = ")); 
            USB.println(errorLoRaWAN, DEC);
        }     
    }
    else 
    {
        USB.print(F("LoRaWAN join network: error = ")); 
        USB.println(errorLoRaWAN, DEC);
    }
    // Turn off LoRaWAN module
    errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
    if (errorLoRaWAN == 0) 
    {
        USB.println(F("LoRaWAN switch off: OK"));     
    }
    else 
    {
        USB.print(F("LoRaWAN switch off: error = ")); 
        USB.println(errorLoRaWAN, DEC);
    }
    
    PWR.deepSleep("00:00:05:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}
