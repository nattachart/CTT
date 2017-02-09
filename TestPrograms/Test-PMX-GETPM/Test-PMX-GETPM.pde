//#define _DEBUG
#include <WaspOPC_N2.h>

char info_string[61];
int status;
int measure;

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
  PWR.deepSleep("00:00:00:03", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  ///////////////////////////////////////////
    // 1. Turn on the sensor
    /////////////////////////////////////////// 

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
    // 2. Read sensor
    ///////////////////////////////////////////  

    if (status == 1)
    {    
        PWR.deepSleep("00:00:00:04", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
        // Power the fan and the laser and perform a measure of 10 seconds
        measure = OPC_N2.getPM(5000,5000);
 #ifdef _DEBUG
        if (measure == 1)
        {
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
        }
        else
        {
            USB.print(F("Error performing the measure. Error code:"));
            USB.println(measure, DEC);
        }
#endif
    }

    //PWR.deepSleep("00:00:00:05", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);


    ///////////////////////////////////////////
    // 3. Turn off the sensor
    /////////////////////////////////////////// 

    // Power off the OPC_N2 sensor. If there aren't other sensors powered, 
    // turn off the board automatically
    OPC_N2.OFF();
    PWR.deepSleep("00:00:00:06", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
