#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspOPC_N2.h>

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

char info_string[61];
int status;
int measure;

char node_ID[] = "CTT_TK_02";

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Indoor Testing - Shorter Version"));
    frame.setID(node_ID);
    
        USB.println("********************************************************************");
    
    status = OPC_N2.ON();
    if(status == 1){
        USB.println(F("PMx sensor started correctly."));
        status = OPC_N2.getInfoString(info_string);
        if(status == 1){
            USB.print(F("Successfully retrieved info string from Pmx sensor. Info string: "));
            USB.println(info_string);
        } else {
            USB.println(F("Wasn't able to read the PMx sensor."));
     }
        OPC_N2.OFF();  
    } else {
        USB.println(F("Wasn't able to start the PMx sensor."));
    }
    
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
    
    status = OPC_N2.ON();
    if(status == 1){
        USB.println(F("PMx sensor successfully turned on."));  
    } else {
        USB.println(F("PMx sensor did not start correctly."));
    }
    
    if(status == 1){
        measure = OPC_N2.getPM(8000);
        if(measure == 1){
            USB.println(F("Measure performed"));
            USB.print(F("PM 1: "));
            USB.print(OPC_N2._PM1);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 2.5: "));
            USB.print(OPC_N2._PM2_5);
            USB.println(F(" ug/m3"));
            USB.print(F("PM 10: "));
            USB.print(OPC_N2._PM10);
            USB.println(F(" ug/m3"));
        } else {
            USB.print(F("Wasn't able to measure PMx. Error code: "));
            USB.println(measure, DEC);  
        }
    }
    
    OPC_N2.OFF();
    
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
    frame.addSensor(SENSOR_GP_NO2, no2concentration);
    frame.addSensor(SENSOR_OPC_PM1, OPC_N2._PM1);
    frame.addSensor(SENSOR_OPC_PM2_5, OPC_N2._PM2_5);
    frame.addSensor(SENSOR_OPC_PM10, OPC_N2._PM10);
    frame.showFrame();
    
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_BAT, battery);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);
    frame.showFrame();
    
    char data2[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data2, frame.length);
    
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}

