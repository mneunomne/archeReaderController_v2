class OscController {
  OscP5 oscP5;

  NetAddress remoteBroadcast;
  NetAddress parallelAddress; 
  NetAddress localBroadcast;

  PApplet parent;

  OscController (PApplet _parent) {
    parent = _parent;
  }

  void connect () {
    oscP5 = new OscP5(this,LOCAL_PORT);
    remoteBroadcast = new NetAddress(MAX_ADDRESS, MAX_PORT);
    parallelAddress = new NetAddress(PARALLEL_ADDRESS, PARALLEL_PORT);
  }
}
