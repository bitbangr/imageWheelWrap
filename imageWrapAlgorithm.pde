//------------------------------------------------------
// circular weaving algorithm
// dan@marginallyclever.com 2016-08-05
// based on work by Petros Vrellis (http://artof01.com/vrellis/works/knit.html)
//------------------------------------------------------

// points around the circle
int numberOfPoints = 200;
// self-documenting
int numberOfLinesToDrawPerFrame = 1;
// self-documenting
//int totalLinesToDraw=3000;
int totalLinesToDraw=3500;
// how dark is the string being added.  1...255 smaller is lighter.
int stringAlpha = 45;
// ignore N nearest neighbors to this starting point
int skipNeighbors=10;
//int skipNeighbors=15;
// set true to start paused.  click the mouse in the screen to pause/unpause.
boolean paused=true;

//------------------------------------------------------
// convenience
color white = color(255,255,255);
color black = color(0,0,0);
color blue = color(0,0,255);
color green = color(0,255,0);


//------------------------------------------------------
int numLines = numberOfPoints * numberOfPoints / 2;
float [] intensities = new float[numberOfPoints];
double [] px = new double[numberOfPoints];
double [] py = new double[numberOfPoints];
double [] lengths = new double[numberOfPoints];
PImage img;

int [] iThreadPoints = new int [totalLinesToDraw];
byte [] bThreadPoints = new byte [totalLinesToDraw];
String [] sThreadPoints= new String[totalLinesToDraw];

int totalLinesDrawn=0;
int currentPoint=0;



//------------------------------------------------------
/**
 * To modify this example for another image, you will have to MANUALLY
 * tweak the size() values to match the img.width and img.height.
 * Don't like it?  Tell the Processing team. 
 */
void setup() {
  
//  img = loadImage("2016-05-08 greek woman.jpg");   // the name of the image to load
//  size(1336,1000);    // the size of the screen is img.width*2, img.height
//  img = loadImage("LDVDavidFace.jpg");
//  size(1356,808);   // 678x808
//  img = loadImage("decalcircle.jpg");
//  size(1600,800);
//  img = loadImage("GeorgeJohnston.jpg");
//  size(1128,600);  564x600
//  img = loadImage("cowboyno5.jpg");
//  img = loadImage("pirate.jpg");
//  size(1200,559);

  img = loadImage("JeanneNurseGrad1.jpg");
  size(1200,598);

  // smash the image to grayscale
  img.filter(GRAY);
  
  // find the size of the circle and calculate the points around the edge.
  double maxr;
  if( img.width > img.height ) 
       maxr = img.height/2;
  else maxr = img.width/2;

  int i;
  for(i=0;i<numberOfPoints;++i) {
    double d = Math.PI * 2.0 * (double)i/(double)numberOfPoints;
    px[i] = img.width/2 + Math.sin(d) * maxr;
    py[i] = img.height/2 + Math.cos(d) * maxr;
  }
  
  // a lookup table because sqrt is slow.
  for(i=0;i<numberOfPoints;++i) {
    double dx = px[i] - px[0];
    double dy = py[i] - py[0];
    lengths[i] = Math.floor( Math.sqrt(dx*dx+dy*dy) );
  }
 
  // Drop the framerate to 3.3 frames per second to simulate hand stringing  
  // gives approx 100 strings in 5.5 minutes 
  // 4000 lines / 100*5.5 (lines/min) = 220 minutes or 3.6 hours 
  //or
  // 3000 lines / 100*5.5 (lines 
  //frameRate(.3);

}


//------------------------------------------------------
void mouseReleased() {
  paused = paused ? false : true;  
}


//------------------------------------------------------
void draw() {
  // if we aren't done
  if(totalLinesDrawn<totalLinesToDraw) {
    if(!paused) {
      // draw a few at a time so it looks interactive.
      int i;
      for(i=0;i<numberOfLinesToDrawPerFrame;++i) {
        drawLine();
        totalLinesDrawn++;
      }
    }
    image(img,width/2,0);
  }
  else
  { // we are done so output points
    println ( "Total # Points = " + iThreadPoints.length);
    
    int j;
    for (j=0;j<iThreadPoints.length; j++){
      print( iThreadPoints[j] + " " );
    }
    
     saveBytes("lines.dat", bThreadPoints);
     saveStrings("lines.txt", sThreadPoints );
     exit(); 
  }
  
  
  
  
  // progress bar
  float percent = (float)totalLinesDrawn / (float)totalLinesToDraw;
  
  strokeWeight(10);  // thick
  stroke(blue);
  line(10,5,(width-10),5);
  stroke(green);
  line(10,5,(width-10)*percent,5);
  strokeWeight(1);  // default
}


//------------------------------------------------------
/**
 * find the darkest line on the image between two points
 * subtract that line from the source image
 * add that line to the output.
 */
void drawLine() {
  int i,j,k;
  double maxValue = 1000000;
  int maxA = 0;
  int maxB = 0;
  // find the darkest line in the picture
  
  // starting from the last line added
  i=currentPoint;

  // uncomment this line to choose from all possible lines.  much slower.
  //for(i=0;i<numberOfPoints;++i)
  {
    for(j=1+skipNeighbors;j<numberOfPoints-skipNeighbors;++j) {
      int nextPoint = ( i + j ) % numberOfPoints;
      if(nextPoint==i) continue;
      double dx = px[nextPoint] - px[i];
      double dy = py[nextPoint] - py[i];
      double len = lengths[j];//Math.floor( Math.sqrt(dx*dx+dy*dy) );
      
      // measure how dark is the image under this line.
      double intensity = 0;
      for(k=0;k<len;++k) {
        double s = (double)k/len; 
        double fx = px[i] + dx * s;
        double fy = py[i] + dy * s;
        intensity += img.get((int)fx, (int)fy);
      }
      double currentIntensity = intensity / len;
      if( maxValue > currentIntensity ) {
        maxValue = currentIntensity;
        maxA = i;
        maxB = nextPoint;
      }
    }
  }
  
  //println("totalLinesDrawn -> " + totalLinesDrawn + " line "+maxA+ " to "+maxB);
  
 // println (maxB);
  // Store the line
  iThreadPoints[totalLinesDrawn] = maxB;
  sThreadPoints[totalLinesDrawn] = str(maxB);
  bThreadPoints[totalLinesDrawn] = byte(maxB);
  
  
  // maxIndex is the darkest line on the image.
  // subtract the darkest line from the source image.
  currentPoint = maxA;
  int nextPoint = maxB;
  double dx = px[nextPoint] - px[currentPoint];
  double dy = py[nextPoint] - py[currentPoint];
  double len = Math.floor( Math.sqrt(dx*dx+dy*dy) );
  for(k=0;k<len;++k) {
    double s = (double)k/len; 
    double fx = px[currentPoint] + dx * s;
    double fy = py[currentPoint] + dy * s;
    color c = img.get((int)fx, (int)fy);
    float r = red(c);
    if(r<255-stringAlpha) {
      r += stringAlpha; 
    } else {
      r = 255;
    }
    img.set((int)fx, (int)fy,color(r));
  }
  
  // draw darkest lines on screen.
  stroke(0,0,0,stringAlpha);
  line((float)px[currentPoint],(float)py[currentPoint],(float)px[nextPoint],(float)py[nextPoint]);
  
  // move to the end of the line.
  currentPoint = nextPoint;
}
