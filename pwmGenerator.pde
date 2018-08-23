#include "timer.h"
#include "stdlib.h"
#include "stdio.h"

#define WAVE_PIN 10

HardwareTimer timer(2);

void setup() {
  // put your setup code here, to run once:
  timer.pause();
  pinMode(2, PWM);
  // Set up an interrupt on channel 1
  timer.setChannel1Mode(TIMER_PWM);
  timer.setCompare(TIMER_CH1, 1);  // Interrupt 1 count after each update
  timer.attachInterrupt(1, counterInterrupt);
  
  squareWave(1, 10);
}

void loop() {
  // put your main code here, to run repeatedly:

}

void counterInterrupt()
{
  return;
}


void squareWave(int frequencyHz, int dutyCyclePercent)
{
  timer.pause();

  int periodMicroseconds=1000000.0/frequencyHz;
  int overflowValue=65536.0*(dutyCyclePercent)/100.0;
  int prescalerValue=72000000/frequencyHz;

  
  timer.setPeriod(periodMicroseconds);
  timer.setChannel1Mode(TIMER_PWM);
  timer.setCompare(TIMER_CH1, overflowValue);
  
  
  timer.resume();
  
}
