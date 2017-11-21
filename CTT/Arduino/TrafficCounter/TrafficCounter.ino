#include <SoftwareSerial.h>
#define DEBUG 0

const int pinRx = 8;
const int pinTx = 7;

int echoPin = 9;
int trigPin = 10;
int ledPin = 13;

SoftwareSerial sensor(pinTx, pinRx);

const unsigned char cmd_get_sensor[] =
{
    0xff, 0x01, 0x86, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x79
};
unsigned char dataRevice[9];
int temp_temp;
int temp_co2;
int sum_temp;
int sum_co2;
int denominator = 0;

int maximumRange = 200;
int minimumRange = 0;
long duration, distance;
long temporaryDistance = 1;
int contin = 0;
int counter = 0;

void setup(){
    sensor.begin(9600);
    Serial.begin(115200);
    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);
    pinMode(ledPin, OUTPUT);
    Serial.println("DIY Traffic Counter with Co2 measurements");
}

void loop(){
     digitalWrite(trigPin, LOW); 
     delayMicroseconds(2); 
     digitalWrite(trigPin, HIGH);
     delayMicroseconds(10); 
     digitalWrite(trigPin, LOW);
     duration = pulseIn(echoPin, HIGH);
     
     //Calculate the distance (in cm) based on the speed of sound.
     temporaryDistance = duration/58.2;
     
     if (temporaryDistance >= maximumRange || temporaryDistance <= minimumRange){
     /* Send a negative number to computer and Turn LED ON 
     to indicate "out of range" */
     Serial.println("Out of range :-/");
     digitalWrite(ledPin, HIGH); 
     }
     else {
        if(temporaryDistance != distance){
          distance = temporaryDistance;
          counter += 1;
          Serial.print("Number of bypassers: ");
          Serial.println(counter);
          Serial.print("Last bypasser was a distance of: ");
          Serial.print(distance);
          Serial.println(" cm away from the detector.");
          if(dataRecieve()){
             sum_co2 += temp_co2;
             sum_temp += temp_temp;
             denominator += 1;
          }
          if(counter % 10 == 0){
             Serial.print("Average Co2 concentraition in the air so far today: ");
             Serial.print(sum_co2 / denominator);
             Serial.println(" ppm.");
             Serial.print("Average temperature today is: ");
             Serial.print(sum_temp / denominator);
             Serial.println(" Celsius.");
          }
        } else {
          contin = 0;
        }
     /* Send the distance to the computer using Serial protocol, and
     turn LED OFF to indicate successful reading. */
     digitalWrite(ledPin, LOW); 
     }
     //Delay 50ms before next reading.
     delay(500);
      
}

bool dataRecieve(void)
{
    byte data[9];
    int i = 0;
 
    //transmit command data
    for(i=0; i<sizeof(cmd_get_sensor); i++)
    {
        sensor.write(cmd_get_sensor[i]);
    }
    delay(10);
    //begin reveiceing data
    if(sensor.available())
    {
        while(sensor.available())
        {
            for(int i=0;i<9; i++)
            {
                data[i] = sensor.read();
            }
        }
    }
 
#if DEBUG
    for(int j=0; j<9; j++)
    {
        Serial.print(data[j]);
        Serial.print(" ");
    }
    Serial.println("");
#endif
 
    if((i != 9) || (1 + (0xFF ^ (byte)(data[1] + data[2] + data[3]
    + data[4] + data[5] + data[6] + data[7]))) != data[8])
    {
        return false;
    }
    temp_co2 = (int)data[2] * 256 + (int)data[3];
    temp_temp = (int)data[4] - 40;
 
    return true;
}

