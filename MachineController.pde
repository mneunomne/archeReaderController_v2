class MachineController {
  Serial port;    // Create object from Serial class
  String val;     // Data received from the serial port
  
  // in order to go back to the beggining
  int accumulated_x = 0;
  int accumulated_y = 0;
  
  String lastMovement;

  int timeStarted=0;
  
  int portIndex = 1;
  int lastDirOffset = 0; 
  int readingSegmentInterval = 5000;

  boolean noMachine = false;

  boolean waitNextMovement = false;

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
    if (waitNextMovement) {
      if (millis() - timeStarted > readingSegmentInterval) {
        waitNextMovement = false;
        startMovement();
      }
    }
  }

  void startMovement() {
    int in_row_index = current_segment_index % segment_rows;
    println("startMovement", macroStates[macroState], nextDir, in_row_index, current_row_index, segment_rows);
    if (nextDir == 1) { // if it was moving right
      if (current_col_index < segment_cols - 1) {
        // continue moving same direction
        macroState = READING_RECT;
        moveX(RECT_WIDTH);
        current_col_index+=1;
      } else { // if at the end of the row 
        if (current_row_index < segment_rows-1) {
          // jump row
          jumpRow();
        } else { // end reading plate
          returnToTopOffeset(1);
          current_segment_index=segment_cols-1;
          nextDir = -1;
        }
      }
    } else { // if it was moving left
      if (current_col_index > 0) {
        macroState = READING_RECT_INVERSE;
        moveX(-RECT_WIDTH);
        current_col_index-=1;
      } else { // if at the end of the row 
        if (current_row_index < segment_rows-1) {
          // jump row
          jumpRow();
        } else { // end reading plate
          returnToTopOffeset(-1);
          current_segment_index=0;
          nextDir = 1;
        }
      }
    }
  }

  void goToNextSegment() {
    println("goToNextSegment", lastDir);
    
    if (nextDir == 0) {
      nextDir = 1;
      macroState = READING_RECT;
    }

    timeStarted = millis();
    waitNextMovement = true;
  }

  void setInitialPosition () {
    accumulated_x = 0;
    accumulated_y = 0;
  }

  void moveX (int steps) {
    char dir = steps > 0 ? '+' : '-';
    sendMovementCommand(dir, abs(steps), 'x');
  }

  void moveY (int steps) {
    char dir = steps > 0 ? '+' : '-';
    sendMovementCommand(dir, abs(steps), 'y');
  }

  void sendMovementCommand (char dir, int value, char axis) {
    // e.g.: +100x
    String s = dir + String.valueOf(value) + axis;
    lastMovement = s;
    // println("[MachineController] sending: " + s);
    port.write(s);
  }

  void returnToTopOffeset (int dir) {
    println("returnToTopOffeset!", dir);
    lastDirOffset = dir;
    macroState = RETURNING_TOP_OFFSET;
    moveX(dir * OFFSET_STEPS);
    // moveY(-UNIT_STEPS*current_row_index);
  }

  void resetOffset () {
    println("resetOffset!");
    macroState = RESET_OFFSET;
    moveX(-lastDirOffset * OFFSET_STEPS);
    // moveY(-UNIT_STEPS*current_row_index);
  }

  void returnToTop () {
    println("returnToTop!");
    macroState = RETURNING_TOP;
    moveY(-accumulated_y);
    current_row_index=0;
    setInitialPosition();
  }

  void jumpRow () {
    current_row_index+=1;
    macroState = JUMPING_ROW;
    accumulated_y+=RECT_HEIGHT;
    moveY(RECT_HEIGHT);
  }

  void listenToSerialEvents () {
    if ( port.available() > 0)  {  // If data is available,
      val = port.readStringUntil('\n');         // read it and store it in val
      if (val.length() > 0) {
        char c = val.charAt(0);
        // println("[MachineController] listenToSerialEvents", c); //print it out in the console
        // start
        switch (c) {
          case 's': // start
            // println("[MachineController] movement start", macroStates[macroState]);
            break;
          case 'e': // end
            // println("[MachineController] movement over: ", lastMovement);
            if (lastMovement == null) return; // sometimes there is leftover event coming from arduino
            onMovementEnd();
            break;
        }
      }
    }
  }

  void onMovementEnd () {
    // println("[MachineController] onMovementEnd", macroStates[macroState], current_segment_index, current_row_index, segment_rows);
    switch (macroState) {
      case STOP_MACHINE:
      case RUNNING_WASD_COMMAND:
        macroState = MACRO_IDLE;
        break;
      case READING_RECT:
        current_segment_index+=1;
        sendSegmentSocket(current_segment_index);
        break;
      case READING_RECT_INVERSE:
        current_segment_index-=1;
        sendSegmentSocket(current_segment_index);
        break;
      case JUMPING_ROW:
        if (nextDir == 1) {
          nextDir = -1;
          current_segment_index += segment_rows;
        } else {
          nextDir = 1;
          current_segment_index+=1;
        }
        // nextDir = nextDir * -1;
        sendSegmentSocket(current_segment_index);
        break;
      case RETURNING_TOP_OFFSET:
        // resetOffset();
        returnToTop();
        break;
      case RETURNING_TOP:
        resetOffset();
        break;
      case RESET_OFFSET:
        sendSegmentSocket(current_segment_index);
        break;
    }
  }
}
