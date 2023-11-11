class MachineController {
  Serial port;  // Create object from Serial class
  String val;     // Data received from the serial port
  int accumulated_x = 0;
  int accumulated_y = 0;
  boolean isRunning;
  String lastMovement;

  int timeStarted=0;
  int nextInterval=500; // in millis
  int readingRowInterval = 5000;
  int timeFinnishedRow=0;
  boolean rowDelay = false; 
  int portIndex = 1;
  int pictureIndex = 0;  
  char nextDir = '+';
  boolean noMachine = false;
  int lastDirOffset = 0; 

  MachineController(PApplet parent, boolean _noMachine) {
    // if no machine, don't connect to serial
    noMachine = _noMachine;
    if (noMachine) return;
    // Connect to Serial
    print("[MachineController] SerialList: ");
    printArray(Serial.list());
    String portName = Serial.list()[portIndex]; //change the 0 to a 1 or 2 etc. to match your port
    port = new Serial(parent, portName, 9600);    
  }

  void update () {
    // add a delay before reading next row
    if (rowDelay) {
      if (millis() >= timeFinnishedRow+readingRowInterval) {
        jumpRow();
        rowDelay=false;
      }
    }
  }

  void startReading () {
    isRunning = true;
  }

  void setInitialPosition () {
    accumulated_x = 0;
    accumulated_y = 0;
  }

  void goBackToInitialPosition () {
    moveDiagonally(-accumulated_x, -accumulated_y);
  }

  void moveX (int steps) {
    this.accumulated_x = this.accumulated_x+steps;
    char dir = steps > 0 ? '+' : '-';
    sendMovementCommand(dir, abs(steps), 'x');
  }

  void moveY (int steps) {
    accumulated_y=+steps;
    char dir = steps > 0 ? '+' : '-';
    sendMovementCommand(dir, abs(steps), 'y');
  }

  void moveDiagonally (int stepsX, int stepsY) {}

  void sendMovementCommand (char dir, int value, char axis) {
    // e.g.: +100x
    String s = dir + String.valueOf(value) + axis;
    lastMovement = s;
    println("[MachineController] sending: " + s);
    port.write(s);
  }

  void returnToTopOffeset (int dir) {
    println("returnToTopOffeset!", dir);
    lastDirOffset = dir;
    machineState = RETURNING_TOP_OFFSET;
    moveX(dir * OFFSET_STEPS);
    // moveY(-UNIT_STEPS*current_row_index);
  }

  void resetOffset () {
    println("resetOffset!");
    machineState = RESET_OFFSET;
    moveX(-lastDirOffset * OFFSET_STEPS);
    // moveY(-UNIT_STEPS*current_row_index);
  }

  void returnToTop () {
    println("returnToTop!");
    machineState = RETURNING_TOP;
    moveY(-UNIT_STEPS*current_row_index);
    current_row_index=0;
  }

  void runRect () {
    lastDir = 1;
    machineState = RUNNING_RECT;
    moveX(RECT_WIDTH);
  }
  
  void runRectInverse () {
    lastDir = -1;
    machineState = RUNNING_RECT_INVERSE;
    moveX(-RECT_WIDTH);
  }

  void jumpRow () {
    current_row_index+=1;
    machineState = JUMPING_ROW;
    moveY(RECT_HEIGHT);
  }


  void runPlate () {
    setInitialPosition();
    machineState = READING_PLATE;
    moveX(RECT_WIDTH);
  }

  void listenToSerialEvents () {
    if ( port.available() > 0)  {  // If data is available,
      val = port.readStringUntil('\n');         // read it and store it in val
      if (val.length() > 0) {
        char c = val.charAt(0);
        println("[MachineController] listenToSerialEvents", c); //print it out in the console
        // start
        switch (c) {
          case 's': // start
            println("[MachineController] movement start", macroStates[macroState]);
            onMovementStart();
            break;
          case 'e': // end
            println("[MachineController] movement over: ", lastMovement);
            if (lastMovement == null) return; // sometimes there is leftover event coming from arduino
            onMovementEnd();
            break;
        }
      }
    }
  }

  void onMovementStart () {
    timeStarted=millis();
    switch (macroState) {
      case READING_RECT:
      case READING_RECT_INVERSE:
      case READING_PLATE:
        // no need to do anything
        println("[MachineController] onMovementStart");
        break;
    }
  }

  void onMovementEnd () {
    int timeSpent = millis()-timeStarted;
    timeFinnishedRow = millis();
    switch (macroState) {
      case STOP_MACHINE:
      case RUNNING_WASD_COMMAND:
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_RECT:
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_RECT_INVERSE:
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_PLATE:
        onMovementEndReadingPlate();
        break;
    }
  }

  // unifying all the decisions if the current macro state is reading plate. 
  void onMovementEndReadingPlate () {
    switch (machineState) {
      case RUNNING_RECT_INVERSE:
        // jump to next row
        if (current_row_index < PLATE_ROWS-1) {
          //jumpRow();
          rowDelay=true;
        } else { // ended reading plate
          returnToTopOffeset(-1);
          // returnToTop();
        }
        break;
      case RUNNING_RECT:
        // interpret signal
        // jump to next row
        if (current_row_index < PLATE_ROWS-1) {
          //jumpRow();
          rowDelay=true;
        } else { // ended reading plate
          returnToTopOffeset(1);
          // returnToTop();
        }
        break;
      case JUMPING_ROW: 
        if (lastDir < 0) {
          runRect();
        } else {
          runRectInverse();
        }
        break;
      // after offset side, go to top
      case RETURNING_TOP_OFFSET:
        returnToTop();
        break;
      // after go to top, reset offset
      case RETURNING_TOP:
        resetOffset();
        break; 
      // after reset offset, start reading again
      case RESET_OFFSET:
        if (lastDirOffset < 0) {
          runRect();
        } else {
          runRectInverse();
        }
        break;
    }
  }
}
