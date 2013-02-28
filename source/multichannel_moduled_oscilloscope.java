import processing.core.*; 
import processing.xml.*; 

import processing.serial.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class multichannel_moduled_oscilloscope extends PApplet {


Serial port;  // Create object from Serial class

float timeScale = 0.03f, voltScale;
float prevSaveTime;
float savePeriod = 10000;
int fileIndex;

int channelCnt;
channel sigs[];
int chcols[];
sqrFlagger buttons[];

public void findPort(){
  boolean cnt = false;
  int trail = 0;
  

  while( trail < 2 && cnt == false ) {
    // Some times a single loop doesn't open up the connection despite it is already connected
    trail++;
    for( int J = 0; J < Serial.list().length; ++J ) {
      try {
        port = new Serial(this, Serial.list()[J], 115200);//"/dev/rfcomm4", 9600);
      } catch(Exception e) {
        continue; }
      
      port.write(100);
      
      int mil = millis();
      while(millis()-mil < 300){}
      if( port.available() <= 0 ) {
        port.stop();
        continue;
      }
      while(  port.available() > 7 ) { port.read(); }
      String idstr = port.readString();
      println("\"" + idstr + "\" received");
      if( idstr.equals("BPmeter") ) {
        port.write(90);
        mil = millis();
        channelCnt = -1;  
        while( channelCnt == -1 ){ channelCnt = port.read(); }
        cnt = true;
        break;
      }
    }
  }
  
  if( cnt == false ){//cnt == false ) {
    println("Device not found or already in use\n");
    noLoop();
    channelCnt = 1;  // To avoid array out of bound
  }
}

public void setup()
{
  frameRate(100);
  size(1800, 800);
  println(Serial.list());
  
  findPort();
    
  fileIndex = 0;
  int secs = 10;
  stroke(255);
  background(0);
  fill(0);
  
  println(channelCnt + " channels");
  
  sigs = new channel[channelCnt];
  buttons = new sqrFlagger[channelCnt];
  chcols = new int[channelCnt];

  for( int i = 0; i < channelCnt; ++i ) {
    chcols[i] = color( (250/channelCnt)*i,
                      256 - (250/channelCnt)*i,
                      (128 + (250/channelCnt)*i )%256);
                         
    sigs[i] = new channel( (secs*14400/channelCnt/2),
                            -height*0.8f/255.0f,
                            -128 );

    buttons[i] = new sqrFlagger( width - (channelCnt+1-i)*10,
                                 height - 20,
                                 8, 8, chcols[i] );
  }
  
  smooth();
  prevSaveTime = millis();
  println( "Start recording at " + prevSaveTime );
}


int pos = 0, fp = floor(width/timeScale), dr = floor(1/timeScale);
float preFrameTime;
float nowFrameTime;
public void draw()
{
  //nowFrameTime = millis();
  //if( (nowFrameTime - (fileIndex+1)*savePeriod ) * ( preFrameTime - (fileIndex+1)*savePeriod ) < 0 ){
  //  saveChannels();
  //}
  preFrameTime = nowFrameTime;
  
  for( int i = 0; i < channelCnt; ++i ) {
    buttons[i].drawButton();
  }
  
  // rcv data, store into channel buffers
  while( port.available() > channelCnt ){
    if( port.read() == 0xff ) {
      for( int i = 0; i < channelCnt; ++i)
      { sigs[i].enqueue( port.read() ); }
      if( sigs[0].InPtr == sigs[0].capacity - 1 ) {
        saveChannels();
      }
    }
  }
  
  // draw the signal from channels based on current settings
  while( sigs[channelCnt-1].available() > 0 ){
    for( int i = 0; i < channelCnt; ++i )
    {
      float a = sigs[i].peek(1)    + height/2;
      float b = sigs[i].dequeue()  + height/2;
      
      if( pos*timeScale < width ){
        
        //stroke(0);
        //strokeWeight(5);
        //line( pos*timeScale+5, 0, pos*timeScale+5, height);
        if( pos%dr==0 ){
          noStroke();
          fill(0);
          rect( (pos+dr)*timeScale , height/10-10, 3, height*4/5+20 );
        }
        
        //strokeWeight(1);
        if(buttons[i].on){
          stroke(chcols[i]);
          line( (pos-1)*timeScale, a, pos*timeScale, b);
        }
        
        pos++;
      } else {
        //background(0);
        pos = 1;
      }
    }
  }
  
}


public void saveChannels()
{
  float nowTime = millis();
  float delta = (nowTime - prevSaveTime)/sigs[0].capacity;
  PrintWriter output;
  String s = "NSoC_";
  if( fileIndex < 10 )
    s = s + "00" + fileIndex + ".txt";
  else if( fileIndex < 100 )
    s = s + "0" + fileIndex + ".txt";
  else if( fileIndex < 1000 )
    s = s + fileIndex + ".txt";
  output = createWriter(s);
  
  for(int J = 0; J < sigs[0].capacity; ++J) {
    output.print( (prevSaveTime + (J*delta))/1000 + " " );
    for(int K = 0; K < channelCnt; ++K)
      output.print( sigs[K].buf[J] +" " );
    output.print("\n");
  }
      
  output.flush();
  output.close();
  fileIndex++;
  println( sigs[0].capacity + " samples saved to " + s);
  prevSaveTime = nowTime;
}


public void mouseClicked() {
  for( int i = 0; i < channelCnt; ++i ) {
    buttons[i].click();
  }
}
class sqrFlagger{
  int x;
  int y;
  int w;
  int h;
  
  boolean on;
  int onCol;
  int offCol;
  
  public void setPos( int a, int b, int c, int d )
  { x=a; y=b; w=c; h=d; }
  
  public void setCol( int a, int b )
  { onCol = a; offCol = b; }
  
  sqrFlagger(int a, int b, int c, int d) {
    on = true;
    setPos(a, b, c, d);
    setCol( color(200), color(100) );
  }
  
  sqrFlagger(int a, int b, int c, int d, int col) {
    on = true;
    setPos(a, b, c, d);
    setCol( color(col), color(blendColor(col, color(50), BLEND)) );
  }
  
  public void drawButton() {
    noStroke();
    if(on){ fill(onCol);  }
    else  { fill(offCol); }
    rect(x,y,w,h);
  }
  
  public void click() {
    if( mouseX < x+w && x < mouseX && mouseY < y+h && y<mouseY ) {
      on = !on;
      drawButton();
    }
  }
  
  
};
class channel{
  
    int capacity;
    int InPtr, OutPtr;
    int[] buf;
    
    float voltScale;
    float offset;
    
    
    channel()
    {
      InPtr     = 0;
      OutPtr    = 0;
      capacity  = 2048;
      buf       = new int[capacity];
      setParameters( 1, 0 );
    }
    
    channel(int cap, float vScale, float ofst)
    {
      InPtr     = 0;
      OutPtr    = 0;
      capacity  = cap;
      buf       = new int[capacity];
      setParameters( vScale, ofst );
    }
    
    public void setParameters( float vScale, float ofst )  {
      offset    = ofst;
      voltScale = vScale;
    }
    
    public void reset() {
      
    }
    
    public void enqueue(int in) {
      buf[InPtr] = in;
      
      if( InPtr < capacity - 1 )
        ++InPtr;
      else
        InPtr = 0;
    }
    
    
    
    public float peek(int numBack)
    {
      assert( numBack < capacity );
      float ret;
      if( OutPtr - numBack > 0 )
        ret = buf[OutPtr - numBack];
      else
        ret = buf[capacity-numBack];
        
      return (ret + offset)*voltScale;
    }
    
    
    public float dequeue() {
      float ret = (buf[OutPtr] + offset)*voltScale;
      
      if( OutPtr < capacity - 1 )
        ++OutPtr;
      else
        OutPtr = 0;
        
      return ret;
    }
    
    
    
    public void saveIntoFile(String s)
    {
      PrintWriter output;
      output = createWriter(s);
      
      int i = InPtr + 1;
      do {
        output.println( buf[i] );
        if( i < capacity - 1 )
          ++i;
        else
          i = 0;
      } while( i != InPtr );
      
      output.flush();
      output.close();
    }
    
    
    public int available()
    {
      if( InPtr > OutPtr )
        return InPtr - OutPtr - 1;
      else
        return InPtr - OutPtr + capacity - 1;
    }
};
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#F0F0F0", "multichannel_moduled_oscilloscope" });
  }
}
