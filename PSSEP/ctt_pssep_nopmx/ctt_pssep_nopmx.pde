#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>

//definition of gas sensors
Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);


//parameters used to hold concentrations and environmental parameters
float co2concentration;	// Stores average co2 concentration 
float no2concentration; //Stores average no2 concentration
float temperature; // Stores average temperature measurement
float humidity;	// Stores average humidity measurement
float pressure;	// Stores average pressure measurement
int battery; //Stores the battery level
float batteryVolts;

//parameters used for measurements of gases
float temporary_co2 = 0;
float temporary_no2 = 0;
float temporary_temp = 0;
float temporary_pres = 0;
float temporary_hum = 0;

float sum_co2 = 0;
float sum_no2 = 0;
float sum_temp = 0;
float sum_pres = 0;
float sum_hum = 0;

int denominator_co2 = 0;
int denominator_no2 = 0;
int denominator_temp = 0;
int denominator_pres = 0;
int denominator_hum = 0;

//error variables for gas sensors
uint8_t co2error;
uint8_t no2error;

//LoRaWAN Parameters
uint8_t error;
uint8_t socket = SOCKET0;
uint8_t PORT = 3;

//node ID contents
char node_ID[] = "CTT";

void setup()
{
  USB.ON();
  USB.println(F("CTT Indoor Testing / Debugging"));
  frame.setID(node_ID);
  
}


void loop()
{
    //turn on sensors and set gain of NO2 to max since this is used for indoor debugging		
    co2error = CO2.ON();
    if(co2error == 1){
      USB.println(F("Co2 sensor started correctly."));  
    } else {
      USB.print(F("Co2 sensor did not start correctly. Error code: "));
      USB.println(co2error);  
    }
    no2error = NO2.ON(LMP91000_GAIN_7);
    if(no2error == 1){
      USB.println(F("No2 sensor started correctly."));  
    } else {
      USB.print(F("No2 sensor did not start correctly. Error code: "));
      USB.println(no2error);  
    }
    
    //set the PSSEP into deepSleep to let sensors warm up
    PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    
    //Check that battery level is sufficient for measurements (>40%)
    battery = PWR.getBatteryLevel();
    batteryVolts = PWR.getBatteryVolts();
    USB.print(F("The battery level is currently at "));
    USB.print(battery);
    USB.print(F("%, which is equal to "));
    USB.print(batteryVolts);
    USB.println(F(" Volts."));
    if(battery < 40){
      while(battery < 40){
          USB.println(F("I'm pretty sleepy... I just need to take a 1 hour nap..."));
          //TODO: add function for sending "sleepy" frame to gateway
          PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);    
          battery = PWR.getBatteryLevel();
      }  
    } else {
         USB.println(F("Woah, I feel so energized today! I'm ready to take some measurements."));
    }
    
    /*For-loop for (hopefully) taking 10 measurements of each parameter 
     - Co2, 
     - No2, 
     - Temperature, 
     - Pressure and, 
     - Humidity.
    */
    USB.println("********************************************************************");
    USB.println(F("Entering for loop for Co2 measurements..."));
    for(int i = 1; i < 11; i++){
        //Display which iteration is currently running
        USB.println("============================================================================================");
        USB.print(F("Iteration #: "));
        USB.println(i, DEC);
        
        //Take measurement of each parameter and place in their respective temporary variables
        temporary_co2 = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
        temporary_no2 = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
        temporary_temp = CO2.getTemp();
        temporary_pres = CO2.getPressure();
        temporary_hum = CO2.getHumidity();
        battery = PWR.getBatteryLevel();
        batteryVolts = PWR.getBatteryVolts();
        
        //Print the results of the temporary measurement
        USB.print(F("Co2 measurement = "));
        USB.print(temporary_co2);
        USB.print(F(" ppm, No2 measurement = "));
        USB.print(temporary_no2);
        USB.println(F(" ppm, "));
        USB.print(F("temperature measurement = "));
        USB.print(temporary_temp);
        USB.print(F(" Celsius, pressure measurement = "));
        USB.print(temporary_pres);
        USB.println(F(" Pa,")); 
        USB.print(F("humidity measurement = "));
        USB.print(temporary_hum);
        USB.println(F(" %."));
        USB.print(F("The battery level is currently at "));
        USB.print(battery);
        USB.print(F("%, which is equal to "));
        USB.print(batteryVolts);
        USB.println(F(" Volts."));

        
        //Check that temporary measurement is valid before adding to the sum
        //and adding 1 to the denominator
        if(temporary_co2 > 0){
            sum_co2 += temporary_co2;
            denominator_co2 += 1;  
        }
        if(temporary_no2 > 0){
            sum_no2 += temporary_no2;
            denominator_no2 += 1;  
        }
        if(temporary_temp > 0){
            sum_temp += temporary_temp;
            denominator_temp += 1;  
        }
        if(temporary_pres > 0){
            sum_pres += temporary_pres;
            denominator_pres += 1;  
        }
        if(temporary_hum > 0){
            sum_hum += temporary_hum;
            denominator_hum += 1;  
        }
        delay(10000);
    }
    
    //Check for each that their over 0 and thus can be used to calculate average
    if(sum_co2 > 0 && denominator_co2 > 0){
        co2concentration = sum_co2 / denominator_co2;
    } else {
        co2concentration = -9999.00;  
    }
    
    if(sum_no2 >= 0 && denominator_no2 > 0){
        no2concentration = sum_no2 / denominator_no2;  
    } else {
        no2concentration = -9999.00;  
    }
    
    if(sum_temp > 0 && denominator_temp > 0){
        temperature = sum_temp / denominator_temp;  
    } else {
        temperature = -9999.00;  
    }
    
    if(sum_pres > 0 && denominator_pres > 0){
        pressure = sum_pres / denominator_pres;  
    } else {
        pressure = -9999.00;  
    }
    
    if(sum_hum > 0 && denominator_hum > 0){
        humidity = sum_hum / denominator_hum;  
    } else {
        humidity = -9999.00;  
    }
    
    
    //print results of measurement process
    USB.println("********************************************************************");
    USB.print(F("Sum_co2 / denominator_co2 =   "));
    USB.print(sum_co2);
    USB.print(F(" / "));
    USB.print(denominator_co2);
    USB.print(F(" = "));
    USB.println(co2concentration);   
   
    USB.print(F("sum_no2 / denominator_no2 =   "));
    USB.print(sum_no2);
    USB.print(F(" / "));
    USB.print(denominator_no2);
    USB.print(F(" = "));
    USB.println(no2concentration);    
    
    USB.print(F("sum_temp / denominator_temp =   "));
    USB.print(sum_temp);
    USB.print(F(" / "));
    USB.print(denominator_temp);
    USB.print(F(" = "));
    USB.println(temperature);

    USB.print(F("sum_pres / denominator_pres =   "));
    USB.print(sum_pres);
    USB.print(F(" / "));
    USB.print(denominator_pres);
    USB.print(F(" = "));
    USB.println(pressure);
    
    USB.print(F("sum_hum / denominator_hum =   "));
    USB.print(sum_hum);
    USB.print(F(" / "));
    USB.print(denominator_hum);
    USB.print(F(" = "));
    USB.println(humidity);
    

    //Print all measured values
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

    //turn the sensors off
    CO2.OFF();
    NO2.OFF();

    //create a frame to hold all values
    frame.createFrame(BINARY);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
    frame.addSensor(SENSOR_GP_NO2, no2concentration);
    frame.addSensor(SENSOR_GP_TC, temperature);
    frame.addSensor(SENSOR_GP_HUM, humidity);
    frame.addSensor(SENSOR_GP_PRES, pressure);
    frame.showFrame();
    
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    //set measurement process parameters to intial values for the next cycle
    temporary_co2 = 0;
    temporary_no2 = 0;
    temporary_temp = 0;
    temporary_pres = 0;
    temporary_hum = 0;
    sum_co2 = 0;
    sum_no2 = 0;
    sum_temp = 0;
    sum_pres = 0;
    sum_hum = 0;
    denominator_co2 = 0;
    denominator_no2 = 0;
    denominator_temp = 0;
    denominator_pres = 0;
    denominator_hum = 0;  
    
    /*
    
    error = LoRaWAN.ON(socket);
    if(error == 0){
        USB.println(F("LoRaWAN module is turned on."));  
    } else {
        USB.print(F("LoRaWAN module could not be turned on. Error code: "));
        USB.println(error, DEC);
    }
    
    error = LoRaWAN.joinABP();
    if(error == 0){
        USB.println(F("PSSEP has now joined the network."));  
        
        error = LoRaWAN.sendUnconfirmed(PORT, data);
        if(error == 0){
            USB.println(F("PSSEP sent data unconfirmed."));
            if(LoRaWAN._dataReceived == true){
                USB.print(F("Data on port number :"));
                USB.print(LoRaWAN._port, DEC);
                USB.print(F("Data: "));
                USB.println(LoRaWAN._data);
            }  
        } else {
            USB.print(F("PSSEP failed to send data. Error code :"));
            USB.println(error, DEC);  
        }
        
    } else {
        USB.print(F("PSSEP failed to join network. Error code: "));
        USB.println(error, DEC);
    }
    
    error = LoRaWAN.OFF(socket);
    if(error == 0){
        USB.println(F("Switch turned off."));  
    } else {
        USB.print(F("Error when turning switch off. Error code: "));
        USB.println(error, DEC);
    }
    
    
    //put PSSEP into deepSleep to save battery 
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
    
    */  
}
