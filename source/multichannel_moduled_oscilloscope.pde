import processing.serial.*;
Serial port;  // Create object from Serial class

float timeScale = 0.03, voltScale;
float prevSaveTime;
float savePeriod = 10000;
int fileIndex;

int channelCnt;
channel sigs[];
color chcols[];
sqrFlagger buttons[];

void findPort(){
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

void setup()
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
  chcols = new color[channelCnt];

  for( int i = 0; i < channelCnt; ++i ) {
    chcols[i] = color( (250/channelCnt)*i,
                      256 - (250/channelCnt)*i,
                      (128 + (250/channelCnt)*i )%256);
                         
    sigs[i] = new channel( (secs*14400/channelCnt/2),
                            -height*0.8/255.0f,
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
void draw()
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


void saveChannels()
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


void mouseClicked() {
  for( int i = 0; i < channelCnt; ++i ) {
    buttons[i].click();
  }
}
