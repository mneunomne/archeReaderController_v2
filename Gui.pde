public class Gui {
  
  ControlP5 cp5;

  int cp_width = 200;
  int cp_height = 10;

  int chart_h = 150;
  int chart_w = 200;
  
  int margin = MARGIN;
  int y = margin; 

  Gui (ControlP5 _cp5) {
    cp5 = _cp5;
  }

  void init () {
    cp5.setColorForeground(color(255, 150));
    cp5.setColorBackground(color(0, 150));
    sliders();
    buttons();
  }

  void sliders () {
    cp5.addSlider("reading_rect_interval_slider")
      .setPosition(margin,y)
      .setSize(cp_width, cp_height)
      .setValue(reading_rect_interval_default)
      .setRange(1, 20)
      ;
    y+=cp_height+margin;
  }

  void buttons () {
    // Group bangButtons = cp5.addGroup("bangButtons").setPosition(width-100-margin,margin).setWidth(100);
    int fx = width - 100 - margin;
    int fy = margin; 
    int button_w = 30;
    int button_h = 15;
    
    cp5.addBang("start")
      .setPosition(fx, fy)
      .setSize(button_w, button_h)
      ;
    fy+= button_h+margin+10;
    
    cp5.addBang("stop")
      .setPosition(fx, fy)
      .setSize(button_w, button_h)
      ;
    fy+= button_h+margin+10;

    cp5.addBang("next_rect")
      .setPosition(fx, fy)
      .setSize(button_w, button_h)
      ;
    fy+= button_h+margin+10; 
    
    cp5.addBang("reset")
      .setPosition(fx, fy)
      .setSize(button_w, button_h)
      ;
    fy+= button_h+margin+10;

  }


  void display () {
    fill(255);
    if (debug) {
      int fy = margin * 2;
      int fx = margin*3+chart_w;
      text("frameRate: " + frameRate, fx,fy);
      fy+=margin+5;
      text("timeElapsed: " + millis()/1000, fx,fy);
      fy+=margin+5;
      text("macroState: " + macroStates[macroState], fx,fy);
      fy+=margin+5;
      text("machineState: " + machineStates[machineState], fx,fy);
      fy+=margin+5;
      text("last_direction: " + lastDir, fx,fy);
      fy+=margin+5;
    }
  }

  void hideButtons () {
    cp5.getController("start").hide();
    cp5.getController("stop").hide();
    cp5.getController("next_rect").hide();
    cp5.getController("reset").hide();
  }

  void showDebugElements () {
    showButtons();
  }

  void hideDebugElements () {
    hideButtons();
  }
  
  void showButtons () {
    cp5.getController("start").show();
    cp5.getController("stop").show();
    cp5.getController("next_rect").show();
    cp5.getController("reset").show();
  }
}
