#define INTERRUPT_PIN 9 //1kohm pulldown resistor from this pin to ground
#define LED_PIN_1 10
#define LED_PIN_2 11


unsigned long secondCounter=0;


void setup()
{
  delay(1);
  delayMicroseconds(10);
  long milliTime=millis();
  long microTime=micros();
  
  pinMode(LED_PIN_1, OUTPUT);
  pinMode(LED_PIN_2, OUTPUT);
  pinMode(INTERRUPT_PIN, INPUT); //attachInterrupt() probably takes care of this, but better to be safe than sorry
  
  //set up the button press interrupt
  attachInterrupt(INTERRUPT_PIN, interruptHandler, RISING);
  
  secondCounter=millis();
}


int LED_PIN=LED_PIN_1;
boolean LED_CHANGED_FLAG=false;
int counter=0;
void loop()
{
  //under the hood, loop() is while(true){}
  if(LED_CHANGED_FLAG)
  {
    LED_CHANGED_FLAG=false;
    digitalWrite(LED_PIN_1, LOW);
    digitalWrite(LED_PIN_2, LOW);
    SerialUSB.println("RADIATION DETECTED. TAKE COVER.");
  }
  else digitalWrite(LED_PIN, LOW);
    
  //this snippet will burn about half a second
  while(millis()-secondCounter<500); 
  secondCounter=millis();
  //*******************************
  
  digitalWrite(LED_PIN, HIGH);
  
  //this snippet will burn about half a second (minus the time it takes to set the LED_PIN)
  while(millis()-secondCounter<500); 
  secondCounter=millis();
  //*******************************
  
  
  counter++;
  SerialUSB.println(counter);
  
}

void interruptHandler()
{
  if(LED_PIN==LED_PIN_1) LED_PIN=LED_PIN_2;
  else LED_PIN=LED_PIN_1;
  
  //It'd be tempting to put the serial print routine in here, but that would be bad form.
  //We'll set a flag, and address the print in the main loop
  LED_CHANGED_FLAG=true;
}

