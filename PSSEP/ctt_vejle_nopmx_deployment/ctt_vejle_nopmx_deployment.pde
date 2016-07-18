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
}


void loop() {
    // put your main code here, to run repeatedly:
    CO2.ON();
    NO2.ON();
    PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    battery = PWR.getBatteryLevel();
    if(battery < 40){
        while(battery < 40){
            frame.create(ASCII);
            frame.addSensor(SENSOR_BAT, battery);
            char data2[frame.length * 2 + 1];
            Utils.hex2str(frame.buffer, data2, frame.length);
            
            errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
            // Join network
            errorLoRaWAN = LoRaWAN.joinABP();
            if (errorLoRaWAN == 0) 
            {
                // Send confirmed packet 1
                errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data2);    
            }
            // Turn off LoRaWAN module
            errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
            PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
            battery = PWR.getBatteryLevel();
        }  
    }
    NO2.autoGain();
    temperature = CO2.getTemp();
    humidity = CO2.getHumidity();
    pressure = CO2.getPressure();
    co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
    no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
    CO2.OFF();
    NO2.OFF();
    if(co2concentration <= 0){
        co2concentration = -99.0;
    }
    if(no2concentration < 0){
        no2concentration = -99.0;
    }
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
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    // Join network
    errorLoRaWAN = LoRaWAN.joinABP();
    if (errorLoRaWAN == 0) 
    {
        errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data);    
    }
    errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
    PWR.deepSleep("00:00:05:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
