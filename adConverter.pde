const int adcPins[4]{0,1,2,3}; //note that analog pin 4 doesn't have an ADC
int adcValues[4]{0};
float averageADCValue=0;
int numCounts=0;

void setup()
{
  for(int i = 0; i < 4; i++) pinMode(adcPins[i], INPUT_ANALOG);
  
  while (!(SerialUSB.isConnected() && (SerialUSB.getDTR() || SerialUSB.getRTS())))
  {
    
    delay(100);
  }
}


void loop() {

  if(SerialUSB.available())
  {
    //start a new test
    char ch=SerialUSB.read();
    if(ch=='T')
    {
      numCounts=0;
      averageADCValue=0;
    }
  }

  if(numCounts/4<25)
  {
    printADCValuesToSerial();
  }
  

}

void printADCValuesToSerial()
{
  int tempSum=0;
  for(int i=0; i<4; i++)
  {
    adcValues[i]=analogRead(adcPins[i]);
    tempSum+=adcValues[i];
    SerialUSB.print(i); SerialUSB.print(":"); SerialUSB.print(adcValues[i]);
    if(i!=3) SerialUSB.print(", ");
  }

  SerialUSB.print(". Average Voltage=");
  numCounts+=4;
  averageADCValue=(averageADCValue*(numCounts-4)+tempSum)/(numCounts);
  float averageVoltage=averageADCValue*3.3/4095;
  SerialUSB.println(averageVoltage);
}

