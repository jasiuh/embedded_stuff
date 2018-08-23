///sine wave simulator
#define LED_PIN 9
unsigned long millisecondTimer;
void setup()
{
  //the leaflabs documentation is incorrect:
  //pwm pins must be initialized with the second
  //argument being PWM, not OUTPUT
  //http://leaflabs.com/docs/lang/api/analogwrite.html

  pinMode(LED_PIN, PWM);
  millisecondTimer=millis();
}

double  sineFrequencyHertz=0.1;

int degreeIterator=0;

boolean debugFlop=false;
void loop()
{
  //all we have to do is iterate an int so that it
  //is incremented by 360 every 1/(sineFrequencyHertz)

  //the loop has an indeterminate iteration time, and we wish the
  //sine wave to be smooth, so we need a way to determine timing intervals
  if(millis()-millisecondTimer>((1000.0/sineFrequencyHertz)/360.0))
  {
    millisecondTimer=millis();
    if(degreeIterator<180)
    {
      degreeIterator++;
    }
    else degreeIterator=0;
  }
  
  int pwmValue=65535*bhaskaraApproximation(degreeIterator);
  SerialUSB.println(pwmValue);
  
  pwmWrite(LED_PIN, pwmValue);

}

double bhaskaraApproximation(int angleDegrees)
{
  int sign=1;
  
  if(angleDegrees>180)
  {
    int multiplier=angleDegrees/180; //this will round down 
    angleDegrees-=180*multiplier;
    
    SerialUSB.print("MULTIPLIER: ");
    SerialUSB.println(multiplier);
    
    if(multiplier%2==0) sign=-1;
  }
    //this approximation is only valid in the region [0deg, 180deg]
    double returnValue=sign*((4.0*angleDegrees*(180.0-angleDegrees)/(40500.0-angleDegrees*(180.0-angleDegrees))));  
    if(returnValue>1) return 1;
    else if(returnValue<0) return 0;
    else return returnValue;
}
