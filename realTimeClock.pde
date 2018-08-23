#include <RTClock.h>
#define DEVICE_PIN 10
#define BUTTON_PIN 11

//The ARM microcontroller on the Maple board has a built-in RTC.

//This header is a high-level wrapper for functionality defined in utility/rtc_util.h, with member variables in time.h
//#include <time.h>
//#include <RTClock.h> 


RTClock rtClock(RTCSEL_HSE ); //the constructor argument is defined in RTClock.cpp as the source of the clock.  The default is 62.5kHz



//#define DEVICE_PIN 12


void customDelayBecauseMapleIsBroken()
{
  int i=3;
  for(int j=1; j<250; j+=1)
  {
    i+=2*j;
  }
  int k=i;
}


boolean printFlag=false;

void printTimeAndDate(tm* arg, boolean printDate) 
{

  if(printDate)

  {

    SerialUSB.print(arg->tm_mon);

    SerialUSB.print("/");

    SerialUSB.print(arg->tm_mday);

    SerialUSB.print("/");

    SerialUSB.print((1900 + arg->tm_year));  

    SerialUSB.print("   ");

  }

  SerialUSB.print(arg->tm_hour);

  SerialUSB.print(":");

  SerialUSB.print(arg->tm_min);

  SerialUSB.print(":");

  SerialUSB.println(arg->tm_sec);

}



void userSetDateTime(boolean changeDate)

{

  int number;

  struct tm newTime; 

  if(changeDate)

  {

    SerialUSB.print("Enter month number (1-12): ");

    number = readInt();

    newTime.tm_mon = number;

    SerialUSB.println(number);

      

    SerialUSB.print("Enter day number (1 - 31): ");

    number = readInt();

    newTime.tm_mday = number;

    SerialUSB.println(number);

      

    SerialUSB.print("Enter number of year (must be >1900): ");

    number = readInt();

    newTime.tm_year = number - 1900;

    SerialUSB.println(number);

  }

    

  SerialUSB.print("Enter number of hours 0 - 23: ");

  number = readInt();

  newTime.tm_hour = number;

  SerialUSB.println(number);

    

  SerialUSB.print("Enter number of minutes 0 - 59: ");

  number = readInt();

  newTime.tm_min = number;

  SerialUSB.println(number);

    

  SerialUSB.print("Enter number of seconds 0 - 59: ");

  number = readInt();

  newTime.tm_sec = number;

  SerialUSB.println(number); 

  

  rtClock.setTime(&newTime);


}



int readInt()

{

  char char_in;

  int digit;

  int value = 0;

  

  do

  {

    char_in = SerialUSB.read();



    if(char_in>57 || char_in <48)

    {

      SerialUSB.print("Invalid Character: '");

      SerialUSB.print(char_in);

      SerialUSB.println("'.  Try again...");

      return -1;

    }

    

    //FYI: char's are really stored internally as integers; no implicit type-casting here

    digit = char_in - 48;  

    

    value = (value * 10) + digit;

  }

  while(SerialUSB.available() > 0);

    

  return value;

}                                                                                                                                                                                                                                                                                                                                                                   void clockSecoundInterrupt()

{

  //it is improper to put serial prints in an ISR, so we set a flag that will be addressed in the main loop

  printFlag = true;

}


boolean interruptFlag=false;
void transmitClocks()

{  //the baud rate of data communication wasn't specified, let’s just send as quickly as possible.

  

    //from the documentation:

    /* Interrupts, etc. may cause the actual number of microseconds to exceed [the argument]. 

     However, this function will return no less than [the argument] microseconds from the time it is called. */

     

    //Most IC's latch output data on a clock transition, so irregularities in baud rate shouldn't matter too much

  interruptFlag=true;

  for (int i = 0; i < 1024; i++)

  {

    digitalWrite(DEVICE_PIN, HIGH);

    customDelayBecauseMapleIsBroken();  

    digitalWrite(DEVICE_PIN, LOW);

    customDelayBecauseMapleIsBroken(); 

  }

}

struct tm* mostRecentTime;

void setup() 

{
  SerialUSB.println("Welcome to Lab 4.  The current time is: ");
  
  pinMode(BOARD_LED_PIN, OUTPUT);   

  pinMode(DEVICE_PIN, OUTPUT);

  pinMode(BUTTON_PIN, INPUT);


  attachInterrupt(BUTTON_PIN, transmitClocks, RISING);

  

  //The tm structure is defined in RTClock.h, and contains member variables that can fully describe a date and time.

  struct tm* currentTime=rtClock.getTime(currentTime);


  printTimeAndDate(currentTime, true);

  
  //This handles sending the time to the serial port every second

  rtClock.attachSecondsInterrupt(clockSecoundInterrupt);



}


void loop() 

{

  if (SerialUSB.available() > 0) 

  {

    SerialUSB.read(); //burn the first character



    SerialUSB.println("You have entered the time editor.  Please follow the instructions.");



    userSetDateTime(true);

  }

  

  if (printFlag)

  {

    printFlag = false;

    printTimeAndDate(rtClock.getTime(mostRecentTime), true);

  }
  
  if(interruptFlag)
  {
    SerialUSB.println("INTERRUPT"); 
    interruptFlag=false;
  }

}

