class MachineController {
  Serial port;  // Create object from Serial class
  String val;     // Data received from the serial port
  int accumulated_x = 0;
  int accumulated_y = 0;
  boolean isRunning;
  String lastMovement;

  int timeStarted=0;

  MachineController(PApplet parent) {
    // null
    print("[MachineController] SerialList: ");
    printArray(Serial.list());
    String portName = Serial.list()[6]; //change the 0 to a 1 or 2 etc. to match your port
    port = new Serial(parent, portName, 9600);    
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
    accumulated_x=+steps;
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

  void returnToTop () {
    machineState = RETURNING_TOP;
    moveY(UNIT_STEPS*current_row_index);
    current_row_index=0;
  }

  void runRow () {
    lastDir = 1;
    machineState = RUNNING_ROW;
    moveX(ROW_STEPS);
  }
  
  void runRowInverse () {
    lastDir = -1;
    machineState = RUNNING_ROW_INVERSE;
    moveX(-ROW_STEPS);
  }

  void jumpRow () {
    current_row_index+=ammountReadingPoints;
    machineState = JUMPING_ROW;
    moveY(UNIT_STEPS * ammountReadingPoints);
  }

  void runPlate () {
    if (ammountReadingPoints > 1) {
      // need to move the camera down before it starts
    } else {
      machineState = READING_PLATE;
      moveX(ROW_STEPS);
    }
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
      case READING_ROW:
      case READING_ROW_INVERSE:
      case READING_PLATE:
      switch (machineState) {
        case RUNNING_ROW_INVERSE:
          // interpret signal
          decoder.startReadingRowInverted();
          break;
        case RUNNING_ROW:
          // interpret signal
          decoder.startReadingRow();
          break;
      }
    }
  }

  void onMovementEnd () {
    int timeSpent = millis()-timeStarted;
    println("timeSpent", timeSpent);
    switch (macroState) {
      case STOP_MACHINE:
      case RUNNING_WASD_COMMAND:
      case RETURNING_TOP:
        // after these events, no reading is involved
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_ROW:
        // interpret signal and push to database? (or does this happen live)
        decoder.endReading(false);
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_ROW_INVERSE:
        // interpret signal inverted
        decoder.endReading(true);
        macroState = MACRO_IDLE;
        machineState = MACHINE_IDLE;
        break;
      case READING_PLATE:
        onMovementEndReadingPlate();
        break;
    }
  }

  void onMovementEndReadingPlate () {
    switch (machineState) {
      case RUNNING_ROW_INVERSE:
        // interpret signal
        decoder.endReading(true); // is inverted
        // jump to next row
        if (current_row_index < PLATE_ROWS) {
          jumpRow();
        } else {
          returnToTop();
        }  
        break;
      case RUNNING_ROW:
        // interpret signal
        decoder.endReading(false); // is inverted
        // jump to next row
        if (current_row_index < PLATE_ROWS) {
          jumpRow();
        } else {
          returnToTop();
        }
        break;
      case JUMPING_ROW: 
        if (lastDir < 0) {
          runRow();
        } else {
          runRowInverse();
        }
        break;
    }
  }
}