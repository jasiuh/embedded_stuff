#include <time.h>
#include <RTClock.h>
#include <stdio.h>
#include <adc.h>

#define SRAM_START_ADDRESS  0x20000000
#define SRAM_END_ADDRESS    0x20004FFC

#define FLASH_START_ADDRESS 0x80000000
#define FLASH_END_ADDRESS   0x80020000


boolean sramWriteTest(uint32 address)
{
  //this function writes a value to an address in memory, and reads it to make sure it gets the same thing it wrote
  uint32 origionalValue = *((uint32*)address);
  uint32 secondValue;
  uint32 testValue = 0xBACADAFA;
  
  *((uint32*)address) = testValue;
  secondValue = *((uint32*)address);
  *((uint32*)address) = origionalValue;
  
  if(secondValue == testValue)
    return true;
  else
    return false; 
}


boolean isValidSRAMAddress(uint32 address)
{
  //Need to make sure that I don't mess with the testing function.

  //start by getting the address of the sram test
  boolean (*testAddress)(uint32) = sramWriteTest;

  //what I do here is remove the last two bits ("4 bytes in the map") from the address to account for
  //the fact that words are four bytes wide. 
  uint32 aligned_address = address & 0xFFFFFFFC; 
  
  boolean result_flag = true;
  uint32 firstReadValue;
  uint32 secondReadValue;

  //conditions to confirm the address in question lies outside the bounds of the reader function
  boolean addressIsAfterFunctionStart = address > (uint32)testAddress;
  boolean addressIsBeforeFunctionEnd =  address < (uint32)(testAddress + 100);

  firstReadValue  = *((uint32*)aligned_address);
  secondReadValue = *((uint32*)aligned_address);
  
  if(firstReadValue != secondReadValue) //this is a sanity check to confirm read integrity
    result_flag = false;
    
  if(!(addressIsAfterFunctionStart && addressIsBeforeFunctionEnd)) result_flag=sramWriteTest(aligned_address);
  
  return result_flag;
}


boolean testKilobyte(uint32 startAddress)
{
  //this is a wrapper for a 1kB wide mem check
  uint32 endAddress = startAddress | 0x3FC;
  uint32 middleAddress = startAddress | 0x200; //0x400 is 1kB, and 0x200 is half of that
    
  if(isValidSRAMAddress(startAddress) && isValidSRAMAddress(middleAddress) && isValidSRAMAddress(endAddress))
  {
    return true;
  }
  else
  {
    SerialUSB.println("Test kilobyte failed.");
    return false;
  }
    
}

void setup_temperature_sensor() {
  adc_reg_map *regs = ADC1->regs;

// 3. Set the TSVREFE bit in the ADC control register 2 (ADC_CR2) to wake up the
//    temperature sensor from power down mode.  Do this first because according to
//    the Datasheet section 5.3.21 it takes from 4 to 10 uS to power up the sensor.

  regs->CR2 |= ADC_CR2_TSEREFE;

// 2. Select a sample time of 17.1 µs
// set channel 16 sample time to 239.5 cycles
// 239.5 cycles of the ADC clock (72MHz/6=12MHz) is over 17.1us (about 20us), but no smaller
// sample time exceeds 17.1us.

  regs->SMPR1 = (0b111 << (3*6));     // set channel 16, the temp. sensor
}

boolean testSRAM()
{
  //this is the machinery for testing the SRAM segment, and returns false if the test fails
  uint32 step = 0x400; //1kB
  uint32 count = 0;
  boolean result;
  int failureCount = 0;
  
  for(uint32 firstAddress = SRAM_START_ADDRESS; firstAddress < SRAM_END_ADDRESS; firstAddress += step)
  {
    result = testKilobyte(firstAddress);
    
    count++;
    
    if(result == false)
      failureCount++;
  }
  
  if(failureCount==0)
 {
   return true;
 }
  else
 {
   SerialUSB.print("Number of memory failures: ");
  SerialUSB.println(failureCount);
   return false;
 }
}

boolean testFlash()
{
  //this is the machinery for testing the Flash segment, and returns false if the test fails
  uint32 step_size = 0x400; //1kB
  boolean result;
  uint32 count = 0;
  int failureCount = 0;
      
  
  for(uint32 firstAddress = FLASH_START_ADDRESS; firstAddress < FLASH_END_ADDRESS; firstAddress += step_size)
  {
    result = testKilobyte(firstAddress);
    
    count++;
    
    if(result == false)
      failureCount++;
  }
  
  
  SerialUSB.print("Number of failures: ");
  SerialUSB.println(failureCount);

  if(failureCount==0) return true;
  else return false;
}

RTClock rtClock(RTCSEL_HSE ); //the constructor argument is defined in RTClock.cpp as the source of the clock.  The default is 62.5kHz

boolean testRTC() 
{
  struct tm newTime; 

  newTime.tm_mon = 1;
  newTime.tm_mday = 1;
  newTime.tm_year = 115; //years since 1900
  newTime.tm_hour = 1;
  newTime.tm_min = 1;
  newTime.tm_sec = 1;

  rtClock.setTime(&newTime);
  struct tm* currentTime=rtClock.getTime(currentTime);
  if(currentTime->tm_mon==1 && currentTime->tm_mday==1 && currentTime->tm_year==115 && currentTime->tm_hour==1 && currentTime->tm_min==1 && currentTime->tm_sec==1)
    return true;
  else 
    return false;
}

void shortDelay()
{
  int k=0;
  for(int i=0; i<100; i++)
  {
    for(int j=0; j<100; j++)
    {
      k+=i+j;
    }
    k=k/(i+1);
  }
}


boolean selfTestPassed=false;
void setup() 
{
  //wait for monitor connection
  while (!(SerialUSB.isConnected() && (SerialUSB.getDTR() || SerialUSB.getRTS())))
  {
    shortDelay();
    toggleLED();
    
  }
  
  //test ram
  if(testSRAM() && testFlash())
  {
    SerialUSB.println("Memory is working.");
    //test internal temperature sensor
    setup_temperature_sensor();
    int temp_reading=adc_read(ADC1, 16);
    
    if(temp_reading>0x04 || temp_reading<0x09) //test against a wide range of possible readings which correspond to plausible temperature readings
    {
      SerialUSB.println("Internal temperature sensor is working.");
      
      if(testRTC())
      {
        SerialUSB.println("Internal RTC is working.");
        
        if(testDigitalPins())
        {
          SerialUSB.println("Digital pins are working.");
          selfTestPassed=true;

        }
        
      }
    }
      
  }
}

void loop()
{
  if(selfTestPassed)
  {
  }
  else
  {
  }
  
}
boolean testDigitalPins()
{
 //assume that all digital Pins are connected to pin 2.  Test pins between 2 and 13.
 
 uint8 basePin=2;
 
 for(int i=3; i<=13; i++)
 {
   if(!testTwoPins(i, basePin)) return false;
   SerialUSB.print("Pin "); SerialUSB.print(i); SerialUSB.println(" is working.");
 }
  return true;
}

boolean testTwoPins(uint8 pin1, uint8 pin2)
{
  uint32 readValue;
  
  pinMode(pin1, OUTPUT);
  pinMode(pin2, INPUT);

  digitalWrite(pin1, HIGH);
  readValue = digitalRead(pin2);
  
  if(readValue != HIGH)return false;
    
  digitalWrite(pin1, LOW);
  readValue = digitalRead(pin2);
  
  if(readValue != LOW) return false;

  pinMode(pin1, INPUT);
  pinMode(pin2, OUTPUT);

  digitalWrite(pin2, HIGH);
  readValue = digitalRead(pin1);
  
  if(readValue != HIGH) return false;
  
  digitalWrite(pin2, LOW);
  readValue = digitalRead(pin1);
 
  if(readValue != LOW) return false;

  return true;
  
}

