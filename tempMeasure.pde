
#include <stdio.h>
#include <adc.h>


#define VALVE_PIN 3

double circular_buffer[10]{0};
unsigned char buffer_index=0;

//read at 10 second and
//1 second intervals. I've chosen 1 second.
unsigned long readIntervalMilliseconds=1000;
unsigned long lastReadTime=0;

double temperatureUpperLimit=33.0;

double V25=0;

void setup() {
  lastReadTime=millis();

  setup_temperature_sensor();

  pinMode(VALVE_PIN, OUTPUT);
  
  V25=3.3*adc_read(ADC1, 16)/4095.0; //should be a room temperature read, about 0x06b1
  //V25=1.4; //this is the datasheet average value
  SerialUSB.print("V25: ");
  SerialUSB.println(V25, HEX);
}

void loop() {

  if((millis()-lastReadTime)>readIntervalMilliseconds)
  {
    //read the temperature, and convert to fahrenheit.

    //the conversion equation is found in the datasheet
    int adcValue=adc_read(ADC1, 16);
    double VSENSE=3.3*adcValue/4095.0;
    double celsius=1000.0*(V25-VSENSE)/4.5+25;
    double fahrenheit=celsius*9.0/5.0+32;
    
    circular_buffer[buffer_index%10]=fahrenheit;

    //send to the PC
    SerialUSB.println(fahrenheit);

    lastReadTime=millis();

    if(fahrenheit>temperatureUpperLimit)
    {
      digitalWrite(VALVE_PIN, HIGH);
      delay(250);
      digitalWrite(VALVE_PIN, LOW);
      delay(250);
    }
    buffer_index++;
  }

}

//lifted from the leaflabs documentation page
void setup_temperature_sensor() {
  adc_reg_map *regs = ADC1->regs;

// 3. Set the TSVREFE bit in the ADC control register 2 (ADC_CR2) to wake up the
//    temperature sensor from power down mode.  Do this first 'cause according to
//    the Datasheet section 5.3.21 it takes from 4 to 10 uS to power up the sensor.

  regs->CR2 |= ADC_CR2_TSEREFE;

// 2. Select a sample time of 17.1 µs
// set channel 16 sample time to 239.5 cycles
// 239.5 cycles of the ADC clock (72MHz/6=12MHz) is over 17.1us (about 20us), but no smaller
// sample time exceeds 17.1us.

  regs->SMPR1 = (0b111 << (3*6));     // set channel 16, the temp. sensor
}

