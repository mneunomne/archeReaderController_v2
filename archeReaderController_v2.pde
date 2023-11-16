/**
 * Arche-Scripttures
 * Processing reading controller
 */

import java.util.*;
import controlP5.*;
import processing.video.*;
import processing.serial.*;
import netP5.*;
import oscP5.*;
import processing.net.*; 

Client myClient;

boolean debug = true;

Gui gui;
MachineController machineController;

int [] last_values = new int [100];

int UNIT_STEPS = 88;
int ROW_STEPS = 16725;
int COLS_STEPS = 23082; // origonal was 23083

int OFFSET_STEPS = 4000;

int PLATE_COLS = 192;
int PLATE_ROWS = 265;

int RECT_WIDTH = 192;
int RECT_HEIGHT = 265;
int RECT_GAP = 0;

static int MARGIN = 10;

boolean savingFrame = false;

// Macro States
int one = 0;
static final int MACRO_IDLE                 = 0;
static final int RUNNING_WASD_COMMAND       = 1;
static final int READING_RECT               = 3;
static final int READING_RECT_INVERSE       = 4;
static final int READING_PLATE              = 5;
static final int STOP_MACHINE               = 6;
int macroState = 0;
String [] macroStates = {
  "MACRO_IDLE",
  "RUNNING_WASD_COMMAND",
  "READING_RECT",
  "READING_RECT_INVERSE",
  "READING_PLATE",
  "STOP_MACHINE",
};

// Machine States
static final int MACHINE_IDLE               = 0;
static final int RUNNING_RECT_INVERSE       = 1;
static final int RUNNING_RECT               = 2;
static final int JUMPING_ROW                = 3;
static final int RUNNING_WASD               = 5;
static final int RETURNING_TOP              = 6;
static final int RETURNING_TOP_OFFSET       = 8;
static final int RESET_OFFSET               = 9;
int machineState = 0;
String [] machineStates = {
  "MACHINE_IDLE",
  "RUNNING_RECT_INVERSE",
  "RUNNING_RECT",
  "RUNNING_WASD",
  "RETURNING_TOP",
  "RETURNING_TOP_OFFSET",
  "RESET_OFFSET"
};

int threshold   = 150;
int small_steps = 250;
int big_steps   = 8000;
int current_row_index = 0;
int current_col_index = 0;

int currentReadTime = 0;

int small_steps_default = UNIT_STEPS;
int big_steps_default   = ROW_STEPS;
int lastDir = 0; 

int reading_rect_interval_default = 5000;
int reading_rect_interval = reading_rect_interval_default;

PFont myFont;

boolean noMachine = true;

void setup() {
  
  frameRate(30);

  size(400, 400, P2D); // much smaller

  // connect to socket
  myClient = new Client(this, "0.0.0.0", 3000); 

  smooth();
  
  loadConfig();

  machineController = new MachineController(this, noMachine);

  ControlP5 cp5 = new ControlP5(this);
  gui = new Gui(cp5);
  gui.init();

  myFont = createFont("PTMono-Regular", 9);
  textFont(myFont);

  // set initial debug state
  toggleDebug(false);
}

void loadConfig() {
  // load json file data/config.json
}

void draw() {
  background(0);

  // update gui chart with the value from the camera 
  // gui.updateChart(currentCameraValue);
  gui.display();
  if (!noMachine) {
    machineController.listenToSerialEvents();
    machineController.update();
  }
}

/*
  ControlP5 listeners
*/

void small_steps_slider (float value) {
  small_steps = floor(value);
  println("small_steps_slider", value, small_steps);
}

void big_steps_slider (float value) {
  big_steps = floor(value);
  println("big_steps_slider", value, big_steps);
}

void reading_rect_interval_slider (float value) {
  reading_rect_interval = int(value);
}

/*
  ControlP5 Bang Buttons
*/

void read_rect_inverse () {
  macroState = READING_RECT_INVERSE;
  machineController.runRectInverse();
}

void read_rect () {
  macroState = READING_RECT;
  machineController.runRect();
}

void read_plate () {
  macroState = READING_PLATE;
  machineController.runRect();
}

void stop_machine () {
  macroState = STOP_MACHINE;
}

void wasd_command (char key) {
  macroState = RUNNING_WASD_COMMAND;
  machineState = RUNNING_WASD;
  switch (key) {
    /* Movements */
    case 'w': machineController.moveY(small_steps); break;
    case 'a': machineController.moveX(small_steps); break;
    case 's': machineController.moveY(-small_steps); break;
    case 'd': machineController.moveX(-small_steps); break;
    /* big movements */
    case 'W': machineController.moveY(big_steps); break;
    case 'A': machineController.moveX(big_steps); break;
    case 'S': machineController.moveY(-big_steps); break;
    case 'D': machineController.moveX(-big_steps); break;
  }
}

void toggleDebug (boolean value) {
  debug = value;
  if (debug) {
    gui.showDebugElements();
  } else {
    gui.hideDebugElements();
  }
}

import http.requests.*;

void sendMessage (String route, String message) {
  println("sendMessage");
  GetRequest get = new GetRequest("http://0.0.0.0:3000/" + route + "/" + message);
  get.send();
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

void testSocket () {
  println("testSocket");
  GetRequest get = new GetRequest("http://0.0.0.0:3000/test/" + machineState);
  get.send();
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

void sendSegmentSocket (int segmentIndex) {
  println("sendSegmentSocket");
  GetRequest get = new GetRequest("http://0.0.0.0:3000/on_segment/" + segmentIndex);
  get.send();
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

// wasd movement keys
void keyPressed() {
  switch (key) {
    /* Movements */
    case 'w': 
    case 'a': 
    case 's': 
    case 'd': 
    case 'W': 
    case 'A': 
    case 'S': 
    case 'D': wasd_command(key); break;
    case '.': toggleDebug(!debug); break;
    case 't': testSocket(); break;
    case '1': sendSegmentSocket(10); break;
  }
}
