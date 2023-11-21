/**
 * Arche-Scripttures
 * Processing reading controller
 */
import websockets.*;
import java.util.*;
import controlP5.*;
import processing.serial.*;
import netP5.*;
import oscP5.*;
import processing.net.*; 

WebsocketServer ws;

Client myClient;

boolean debug = true;

Gui gui;
MachineController machineController;

// Macro States
int one = 0;
static final int MACRO_IDLE                 = 0;
static final int READING_PLATE              = 1;
static final int RUNNING_WASD_COMMAND       = 2;
static final int READING_RECT               = 3;
static final int READING_RECT_INVERSE       = 4;
static final int JUMPING_ROW                = 5;
static final int STOP_MACHINE               = 6;
static final int SENDING_SEGMENT            = 7;
static final int WAITING_RESPONSE           = 8;
static final int WAITING_TIME               = 9;
static final int ERROR                      = 10;
static final int RETURNING_TOP_OFFSET       = 11;
static final int RETURNING_TOP              = 12;
static final int RESET_OFFSET               = 13;

int macroState = 0;
String [] macroStates = {
  "MACRO_IDLE",
  "READING_PLATE",
  "RUNNING_WASD_COMMAND",
  "READING_RECT",
  "READING_RECT_INVERSE",
  "JUMPING_ROW",
  "STOP_MACHINE",
  "SENDING_SEGMENT",
  "WAITING_RESPONSE",
  "WAITING_TIME",
  "ERROR",
  "RETURNING_TOP_OFFSET",
  "RETURNING_TOP",
  "RESET_OFFSET"
};

int OFFSET_STEPS = 2000;

int small_steps = 250;
int big_steps   = 5200;

int lastDir = 0; 
int nextDir = 0;

int reading_rect_interval_default = 5000;
int reading_rect_interval = reading_rect_interval_default;

PFont myFont;

int current_segment_index = 0;

int segment_rows = 5;
int segment_cols = 4;

int RECT_HEIGHT = 5000; // 6000
int RECT_WIDTH  = 5100; // 6000

int current_row_index = 0;
int current_col_index = 0;

boolean noMachine = false;

static int MARGIN = 10;

int now;

boolean isRunTest=false;


void setup() {
  
  frameRate(30);

  size(400, 400, P2D); // much smaller

  if (isRunTest == true) {
    RECT_HEIGHT = RECT_HEIGHT / 10;
    RECT_WIDTH = RECT_WIDTH / 10;
    reading_rect_interval = 500;
  }
  
  ws= new WebsocketServer(this,8025,"/arche-scriptures");

  // connect to socket
  // myClient = new Client(this, "0.0.0.0", 3000); 

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

void read_plate () {
  macroState = READING_PLATE;
  // machineController.runRect();
  machineController.setInitialPosition();
  sendSegmentSocket(current_segment_index);
}

void stop_machine () {
  macroState = STOP_MACHINE;
}

void wasd_command (char key) {
  macroState = RUNNING_WASD_COMMAND;
  switch (key) {
    /* Movements */
    case 'w': machineController.moveY(small_steps); break;
    case 'a': machineController.moveX(small_steps); break;
    case 's': machineController.moveY(-small_steps); break;
    case 'd': machineController.moveX(-small_steps); break;
    /* big movements */
    case 'W': machineController.moveY(RECT_HEIGHT); break;
    case 'A': machineController.moveX(RECT_WIDTH); break;
    case 'S': machineController.moveY(-RECT_HEIGHT); break;
    case 'D': machineController.moveX(-RECT_WIDTH); break;
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

void sendSegmentSocket (int segmentIndex) {
  macroState = SENDING_SEGMENT;
  println("sendSegmentSocket", segmentIndex);
  int idx = segmentIndex;
  // if (segmentIndex == 2) idx = 5;
  // if (segmentIndex == 3) idx = 6;

  if (isRunTest == true) {
    macroState = WAITING_TIME;
    machineController.goToNextSegment();
    return;
  }
  GetRequest get = new GetRequest("http://0.0.0.0:3000/on_segment/" + idx);
  get.send();
  macroState = WAITING_RESPONSE;
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
  if (get.getContent().equals("fail")) {
     println("fail reading... continue");
  } else {
      ws.sendMessage("detection-" + get.getContent());  
  }
  macroState = WAITING_TIME;
  machineController.goToNextSegment();
}

void sendSegmentSocketTest (int segmentIndex) {
  macroState = SENDING_SEGMENT;
  println("sendSegmentSocket", segmentIndex);
  int idx = segmentIndex;
  GetRequest get = new GetRequest("http://0.0.0.0:3000/on_segment/" + idx);
  get.send();
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

void sendClearMessage () {
  println("sendClearMessage");
  GetRequest get = new GetRequest("http://0.0.0.0:3000/clear");
  get.send();
  System.out.println("Reponse Content: " + get.getContent());
  System.out.println("Reponse Content-Length Header: " + get.getHeader("Content-Length"));
}

void startReadingPlate () {
  nextDir = 0;
  macroState = READING_PLATE;
  machineController.setInitialPosition();
  current_segment_index = 0;
  sendSegmentSocket(current_segment_index);
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
    case 'A': wasd_command(key); break;
    case 'S': 
    case 'D': wasd_command(key); break;
    case '.': toggleDebug(!debug); break;
    case 'r': startReadingPlate(); break;
    case 'c': sendClearMessage(); break;
    case '1': sendSegmentSocketTest(1); break;
    case '2': sendSegmentSocketTest(2); break;
    case '3': sendSegmentSocketTest(3); break;
  }
}
