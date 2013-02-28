class sqrFlagger{
  int x;
  int y;
  int w;
  int h;
  
  boolean on;
  color onCol;
  color offCol;
  
  void setPos( int a, int b, int c, int d )
  { x=a; y=b; w=c; h=d; }
  
  void setCol( color a, color b )
  { onCol = a; offCol = b; }
  
  sqrFlagger(int a, int b, int c, int d) {
    on = true;
    setPos(a, b, c, d);
    setCol( color(200), color(100) );
  }
  
  sqrFlagger(int a, int b, int c, int d, color col) {
    on = true;
    setPos(a, b, c, d);
    setCol( color(col), color(blendColor(col, color(50), BLEND)) );
  }
  
  void drawButton() {
    noStroke();
    if(on){ fill(onCol);  }
    else  { fill(offCol); }
    rect(x,y,w,h);
  }
  
  void click() {
    if( mouseX < x+w && x < mouseX && mouseY < y+h && y<mouseY ) {
      on = !on;
      drawButton();
    }
  }
  
  
};
