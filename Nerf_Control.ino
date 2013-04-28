#include <Servo.h> 

Servo myservo;
const int buttonPin = 5;     // the number of the pushbutton pin
const int ledPin =  13;      // the number of the LED pin
const int relayPin = 8;
const int servoPin = 9;

// Variables will change:
int ledState = HIGH;         // the current state of the output pin
int buttonState;             // the current reading from the input pin
int lastButtonState = LOW;   // the previous reading from the input pin
char servo_speed = 0;
const char SERVO_MID = 94;
boolean firing = false;

// the following variables are long's because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long lastDebounceTime = 0;  // the last time the output pin was toggled
long debounceDelay = 50;    // the debounce time; increase if the output flickers

void setup() {
  pinMode(buttonPin, INPUT);
  pinMode(ledPin, OUTPUT);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW);
  Serial.begin(9600); 
  myservo.attach(servoPin);
}

boolean shouldStopFiring() {      
    int reading = digitalRead(buttonPin);
    
    /*
    //TODO: IMPLEMENT THIS
    if (reading != lastButtonState) {
      lastDebounceTime = millis();
    } 
    if ((millis() - lastDebounceTime) > debounceDelay) {
      buttonState = reading;
    }
    */
    
    buttonState = reading;
    digitalWrite(ledPin, buttonState);
    
    
    //Stop shooting on edge transition
    boolean retval = false;
    if (lastButtonState == LOW && buttonState == HIGH) 
      retval = true;
  
    lastButtonState = buttonState;
    return retval;
}

void loop() {
  if (shouldStopFiring()) {
    firing = false;
    digitalWrite(relayPin, LOW);
  }
  
  if (firing) {
    digitalWrite(relayPin, HIGH);
  }
  
  if (Serial.available() > 0) {
          //First bit is fire Y/N
          //Remaining 7 indicate motor speed (signed char)
          char incoming = Serial.read();
          
          firing = incoming & 0x01;
 
          servo_speed = ((double)(incoming & ~0x01) + 128) * (180.0/255); //Convert 0-255 to 0-180
          myservo.write(servo_speed);
          
          Serial.print(servo_speed, DEC);
          if (firing)
            Serial.println(" Firing");
          else
            Serial.print('\n');
  }  
}
