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
uint8_t loraerror;
uint8_t socket = SOCKET0;
uint8_t PORT = 3;

char node_ID[] = "CTT_TK_02";

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Indoor Testing - Shorter Version"));
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
    volts = PWR.getBatteryVolts();
    USB.print(F("The current battery level is: "));
    USB.print(battery);
    USB.print(F("%, which amounts to "));
    USB.print(volts);
    USB.println(F(" V."));
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
   
    
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
    frame.addSensor(SENSOR_GP_NO2, no2concentration);
    frame.addSensor(SENSOR_BAT, battery);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);
    frame.showFrame();
    
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}
