//Memory Checker Program

//The maple uses a STM32F103RB MCU
//--------------------------------
//Documented memory map:
//128kB Flash (program memory)
//20kB SRAM (variable/runtime memory)
//0kB EEPROM



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
    return true;
  else 
    return false;
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
  
  
  SerialUSB.print("Number of failures: ");
  SerialUSB.println(failureCount);

  if(failureCount==0) return true;
  else return false;
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

void setup() 
{
  //I need to do this because the folks at LeafLabs decided not to initialize the serial machinery before running setup()
  while (!(SerialUSB.isConnected() && (SerialUSB.getDTR() || SerialUSB.getRTS())))
  {
    delay(100);
  }
  
  // announce start up
  SerialUSB.println("Serial Initialized.  Starting Program...");

  SerialUSB.println("Memory Checking Routine");
  SerialUSB.println("-----------------------");

  if(testSRAM() && testFlash())
  {
    SerialUSB.println("MEMORY TEST RESULTED IN NO ERRORS!");
  }
  else SerialUSB.println("MEMORY TEST RESULTED IN ERRORS!");
  
}

void loop() 
{
 
  delay(1000);
}
