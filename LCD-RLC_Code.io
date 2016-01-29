/*
 LCD Dwelling Light Controller (LCD-DLC)
 
This is a program that controls room lights using PWM and digital signals.
It comes equipped with a countdown timer so that one can turn off their lights automatically.
    
The circuit:
 * LCD RS pin to digital pin 12
 * LCD Enable pin to digital pin 11
 * LCD D4 pin to digital pin 5
 * LCD D5 pin to digital pin 4
 * LCD D6 pin to digital pin 3
 * LCD D7 pin to digital pin 2
 * LCD R/W pin to ground
 * 10K resistor:
 * ends to +5V and ground
 * wiper to LCD VO pin (pin 3)
 (This configuration uses the defualt setup for the Liquid Crystal library to provide ease of use)
 
 * LED light / transistor pin to digital pin 6
 * Secondary light transistor pin to digiital pin 13
 
 * Each button is connected to +5v and a 10k ohm resistor to side one and connected to the Arduino one the other side.
 * Wiring for these buttons can be found at https://www.arduino.cc/en/Tutorial/Button
 * Leftmost button to digital pin 8
 * Center button to digital pin 9
 * Rightmost button to digital pin 10
 
 Created 16 January 2016
 By Grant Bonds
 Modified 22 January 2016
 By Grant Bonds
*/


#include <LiquidCrystal.h> //include the library code
int menuLevel = 0; //menu navigation variable. Each button is tied to a "level" that tells the 
int ledBrightness = 0; //LED brightness control variable
int ledPin = 6; //select the pin connected directly to a single LED or to a transistor that controls several LEDs
int backButton = 7; //select the reset button pin for the LCD menu
int buttonLeft = 8; //select the leftmost button pin
int buttonCenter = 9; //select the center button pin
int buttonRight = 10; //select the rightmost button pin
int lightPin = 13; //select the pin connected to the gate pin of a transistor
unsigned long minutesLeft = 0; //A timer that stores the variable that millisecondtimeChange will count to
unsigned long millisecondCounter = 0; //A continuous counter variable that keeps time
unsigned long millisecondTimeChange = 0; //A variable that counts the time change since the last press of the center button on menuLevel 3
unsigned long millisecondTime = 0; //A variable that stores the last time the center button on menuLevel 3 was pressed
boolean isTimerRunning = false; //A boolean that determines if the timer is running
LiquidCrystal lcd(12, 11, 5, 4, 3, 2); // initialize the library with the numbers of the interface pins

void setup() {
  pinMode(ledPin,OUTPUT); // initialize outputs for LEDs and lights
  pinMode(lightPin,OUTPUT);
  pinMode(buttonLeft,INPUT); // initalize inputs for buttons
  pinMode(buttonCenter,INPUT);
  pinMode(buttonRight,INPUT);
  pinMode(backButton,INPUT);
  lcd.begin(20,4); // set up the LCD's number of columns and rows
  mainMenu(); //call the main reset function for the program
}

void loop() {
  int buttonLeftState = digitalRead(buttonLeft); //read the pins and assign them to variables
  int buttonCenterState = digitalRead(buttonCenter);
  int buttonRightState = digitalRead(buttonRight);
  int backButtonState = digitalRead(backButton);
  
  if(backButtonState == HIGH) { //reset the LCD and the program
    mainMenu();
    delay(500);
  }
  if(buttonLeftState == HIGH && menuLevel == 0) { //responce to the left button being pressed on menuLevel 0
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Off");
    lcd.setCursor(3,1);
    lcd.print("Light Control!");
    lcd.setCursor(17,0);
    lcd.print("On");
    delay(500);
    menuLevel = 1; //menuLevel changed
    return;
  }
  if(buttonLeftState == HIGH && menuLevel == 1) { //control the state of the lightPin
    digitalWrite(lightPin,LOW);
  }
  if (buttonRightState == HIGH && menuLevel == 1) {
    digitalWrite(lightPin,HIGH);
  }
  if(buttonCenterState == HIGH && menuLevel == 0) { //responce to the center button being pressed on menuLevel 0
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Dimmer");
    lcd.setCursor(3,1);
    lcd.print("LED Brightness");
    lcd.setCursor(12,0);
    lcd.print("Brighter");
    delay(500);
    menuLevel = 2; //menuLevel changed
    return;
  }
  if(buttonRightState == HIGH && menuLevel == 2 && ledBrightness < 255) { //manipulate the PWM signal from ledPin
    ledBrightness = (ledBrightness + 5); //adjust X in the command ledBrightness + X to increase or decrease the magnitude of change with each button press. For proper function, 255 must be evenly divisible by X
    analogWrite(ledPin,ledBrightness);
    delay(50);
  }
  if(buttonLeftState == HIGH && menuLevel == 2 && ledBrightness > 0) { //manipulate the PWM signal from ledPin
    ledBrightness = (ledBrightness - 5); //adjust X in the command ledBrightness + X to increase or decrease the magnitude of change with each button press. For proper function, 255 must be evenly divisible by X
    analogWrite(ledPin,ledBrightness);
    delay(50);
  } 
  if(buttonRightState == HIGH && menuLevel == 0) { //responce to the right button being pressed on menuLevel 0
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("-1 Min");
    lcd.setCursor(7,2);
    lcd.print("Start!");
    lcd.setCursor(14,0);
    lcd.print("+1 Min");
    lcd.setCursor(6,1);
    lcd.print("Mins Left");
    delay(500);
    menuLevel = 3; //menuLevel changed
    return;
  }
  if(buttonLeftState == HIGH && menuLevel == 3 && minutesLeft > 0) { //decrease minutesLeft by 1 when the left button is pressed.
    minutesLeft = minutesLeft - 1; //adjust X in the command minutesLeft - X to increase or decrease magnitude of change with each button press.
    lcd.setCursor(2,1);
    lcd.print(minutesLeft);
    delay(250); //minuetsLeft adjustment speed, can be adapted to the user's liking
  }
  if(buttonRightState == HIGH && menuLevel == 3) { //increase minutesLeft by 1 when the right button is pressed.
    minutesLeft = minutesLeft + 1; //adjust X in the command minutesLeft + X to increase or decrease magnitude of change with each button press.
    lcd.setCursor(2,1);
    lcd.print(minutesLeft);
    delay(250); //minuetsLeft adjustment speed, can be adapted to the user's liking
  }
  if(menuLevel == 3) { //if menuLevel = 3, assign millisecondCounter and millisecondTimeChange a value
    millisecondCounter = millis();
    millisecondTimeChange = millisecondCounter - millisecondTime;
    
    if(buttonCenterState == HIGH) { //if the center button is pressed while menuLevel = 3, assign a value to millisecondTime and set isTimerRunning equal to true
    lcd.clear();
    lcd.setCursor(6,1);
    lcd.print("Running");
    isTimerRunning = true;
    millisecondTime = millisecondCounter;
    }
  }
  while(millisecondTimeChange > minutesLeft * 60000 && isTimerRunning == true) { //while the time change is larger than the time set and the timer is running, turn on the lights
    lcd.setCursor(4,1);
    lcd.print("Timer Done!");
    digitalWrite(lightPin,HIGH);
    return;
  }
}
void mainMenu() {
  menuLevel = 0; //return to the main menuLevel
  ledBrightness = 0; //set the LED brightness to 0
  minutesLeft = 0; //reset the timer variables
  millisecondCounter = 0;
  isTimerRunning = false; //stop the timer from running
  digitalWrite(lightPin,LOW); //turn the lights & LEDs off
  analogWrite(ledPin,0);
  lcd.clear(); //clear the LCD
  lcd.setCursor(0,0); //display the main menu LCD screen
  lcd.print("Light Control");
  lcd.setCursor(0,1);
  lcd.print("LED Control");
  lcd.setCursor(0,2);
  lcd.print("Lights2");
}
