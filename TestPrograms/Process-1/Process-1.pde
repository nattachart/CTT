#include <WaspFrame.h>

char node_id[] = "wmtroof2";
void setup()
{
  PWR.deepSleep("00:00:00:03", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  frame.setID(node_id);
  PWR.deepSleep("00:00:00:03", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}


void loop()
{
  PWR.deepSleep("00:00:00:03", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  frame.createFrame(ASCII);
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  frame.showFrame();
  PWR.deepSleep("00:00:00:03", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
