#define OUNCES_PER_REVOLUTION 1 //a constant defined by the performance of the vehicle

#define FLOW_RATE_LIMIT 10 //in ounces per second

#define SERIAL_PRINT_RATE 1 //the number of quadrature changes we wait for before we print serial data

const int ENCODER_INPUT_A=12;
const int ENCODER_INPUT_B=13;


void setup() 
{
  pinMode(ENCODER_INPUT_A, INPUT_PULLUP);  
  pinMode(ENCODER_INPUT_B, INPUT_PULLUP);

  
}

int counter=0;
void loop() 
{
  decodeQuadrature(readValueFromEncoder());
}

int number_of_quadrature_transitions=0;
double time_of_last_transition=0;
double duration_of_last_transition=0;
int lastEncoderPosition=0;

double rotationalVelocity=0;
double lastRotationalVelocity=0;

double rotationalAcceleration=0;

double totalGallons=0;
double flowRate=0;
bool printFlag=false;



void decodeQuadrature(int decoderValue)
{
  if(decoderValue != lastEncoderPosition && !printFlag) //printFlag prevents the serial prints from disturbing our results
  {
    //this is an encoder transition: the thing is spinning
    number_of_quadrature_transitions++;  //this will only work until we overflow the integer...but before that happens (probably several tens of minutes), the timers below will overflow.

    //calculate RPS (radians per second...use metric) by assuming the motion will be unchanging
    duration_of_last_transition=(micros()-time_of_last_transition)/1000000.0;  //in seconds
    time_of_last_transition=micros();
    SerialUSB.print("Transition time: ");
    SerialUSB.println(duration_of_last_transition);
    
    rotationalVelocity=2*3.14159/(16.0*duration_of_last_transition);  //denominator times 16, because one encoder transition represents only PI/2 radians
    rotationalAcceleration=(rotationalVelocity-lastRotationalVelocity)/duration_of_last_transition;

    double fluid_increment=OUNCES_PER_REVOLUTION/(4*128.0); //in gallons.  there are 128 fluid ounces per gallon.
    
    totalGallons+=fluid_increment;
    flowRate=fluid_increment/duration_of_last_transition;

    //SERIAL FUNCTIONS GO HERE.  THIS WILL TAKE A HANDFULL OF MILLISECONDS
    //So, we're not going to print every iteration because it would mess up our
    //calculations.  But we will print if there's a flow rate limit violation,
    //and we will print 'every so often'.  The effect of printing, which will be
    //interpreted by our calculations as 

    if(flowRate>FLOW_RATE_LIMIT)
    {
      SerialUSB.println("FLOW RATE EXCEEDS LIMIT!");
    }
    
    if(number_of_quadrature_transitions%SERIAL_PRINT_RATE==0) //set SERIAL_PRINT_RATE to 1 if you want to print every time the encoder changes
    {
      SerialUSB.print("Rotational Velocity (rad/sec): ");
      SerialUSB.println(rotationalVelocity);
      SerialUSB.print("Rotational Acceleration (rad/sec^2): ");
      SerialUSB.println(rotationalAcceleration);
      SerialUSB.print("Total Fuel Consumption (gallons): ");
      SerialUSB.println(totalGallons);
      SerialUSB.print("Flow Rate (gallons/sec): ");
      SerialUSB.println(flowRate);
      //printFlag=true;
    }

    
    lastEncoderPosition=decoderValue;
  }
  else if(decoderValue != lastEncoderPosition && printFlag)
  {
    //don't let serial printing mess up our results
    time_of_last_transition=micros();
    printFlag=false;
  }
}



byte readValueFromEncoder()
{
  return (((boolean) digitalRead(ENCODER_INPUT_A)) | ((boolean) digitalRead(ENCODER_INPUT_B))<<1);
 
  /*boolean pinA = (boolean) digitalRead(ENCODER_INPUT_A);
  boolean pinB = (boolean) digitalRead(ENCODER_INPUT_B);
  
  if (pinA && pinB)
    return 0;
  
  if (!pinA && pinB)
    return 1;
  
  if (!pinA && !pinB)
    return 2;
  
  if (pinA && !pinB)
    return 3;
*/
    
}
