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
    
    void setParameters( float vScale, float ofst )  {
      offset    = ofst;
      voltScale = vScale;
    }
    
    void reset() {
      
    }
    
    void enqueue(int in) {
      buf[InPtr] = in;
      
      if( InPtr < capacity - 1 )
        ++InPtr;
      else
        InPtr = 0;
    }
    
    
    
    float peek(int numBack)
    {
      assert( numBack < capacity );
      float ret;
      if( OutPtr - numBack > 0 )
        ret = buf[OutPtr - numBack];
      else
        ret = buf[capacity-numBack];
        
      return (ret + offset)*voltScale;
    }
    
    
    float dequeue() {
      float ret = (buf[OutPtr] + offset)*voltScale;
      
      if( OutPtr < capacity - 1 )
        ++OutPtr;
      else
        OutPtr = 0;
        
      return ret;
    }
    
    
    
    void saveIntoFile(String s)
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
    
    
    int available()
    {
      if( InPtr > OutPtr )
        return InPtr - OutPtr - 1;
      else
        return InPtr - OutPtr + capacity - 1;
    }
};
