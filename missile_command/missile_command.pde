/*
Justin Burrill
 Nov 02 2021
 Missile command for the Atari recreation
 
 TODO:
 *** fix missile split
 make the tracer stay after the line splits currently the splitpos follows the tail pos offscreen
 ^^ then make another constructor that allows missiles to have a plane as a parent, basically the same issue as the split missile
 
 make it harder as it goes on?
 */

// lists for each object that needs to be updated each frame
ArrayList<Missile> missiles = new ArrayList<Missile>();
ArrayList<Fireball> fireballs = new ArrayList<Fireball>();
ArrayList<Cannon> cannons = new ArrayList<Cannon>();
ArrayList<Tracer> tracers = new ArrayList<Tracer>();
ArrayList<Reticle> reticles = new ArrayList<Reticle>();
ArrayList<Plane> planes = new ArrayList<Plane>();
ArrayList<Score_text> texts = new ArrayList<Score_text>();
ArrayList<Xhair> xhairs = new ArrayList<Xhair>();

ArrayList<HighScores> highScoresObjs = new ArrayList<HighScores>();

// create certain variables that need to be accessed globally

color dirtColour, backgroundColour;

// object that holds methods related to the highscore system, created so it can be accessed globally
HighScores highScoresObj = new HighScores("data/txt/highscores.txt", "data/txt/instructions/default.txt");
HighScores challengeHighScoresObj = new HighScores("data/txt/challengehighscores.txt", "data/txt/instructions/challenge.txt");
HighScores multiplayerHighScoresObj = new HighScores("data/txt/multiplayerhighscores.txt", "data/txt/instructions/multiplayer.txt");
HighScores blankHighScoresObj = new HighScores("data/txt/blank.txt", "data/txt/blank.txt");


// some settings are written in a json file, object is created here
JSONObject cfg;
int cfgIndex, hsIndex;
String[] cfgs = { "default", "multiplayer", "challenge", "custom" };

Xhair redplayer;
Xhair blueplayer;

int floorHeight, cannonCount;
int enemyMissileTimer = 0, enemyPlaneTimer = 0;
boolean menuOpen = true;
int actualScore, highscore;
int displayScore = 0;


color[] colourArray = new color[8];

int menuUpdateDelay;
int enemySpawnDelay, planeSpawnDelay;

int currentMenuUpdateDelay = menuUpdateDelay;
int menuIndex = 0;
String menuText2;
boolean topTenScore = false;

boolean userTyping = false;
String typedText="";
String displayedUserText;
String userInitials;


void setup() {
  // size of the window
  size(800, 800);
  
  resetScreen();
  
  dirtColour = color(125, 83, 54);
  backgroundColour = color(0);
  
  highScoresObjs.clear();
  highScoresObjs.add(highScoresObj);
  highScoresObjs.add(multiplayerHighScoresObj);
  highScoresObjs.add(challengeHighScoresObj);
  highScoresObjs.add(blankHighScoresObj);
  
  for (HighScores hs : highScoresObjs) {
    hs.readAndSortScores();
  }

  cannons.clear();
  
  // get settings from the json file
  loadcfg();

  // make my cannons
  for (int i = 0; i < cannonCount; i++) {
    //println("new cannon made");
    cannons.add(new Cannon(i));
  }

  // gives warning if the amount of cannons is too much or too little and won't work with the controls
  if (cannonCount > 10 || cannonCount < 1) {
    println("cannon count out of bounds!");
  }
}

void loadcfg() {
  if (cfgs[cfgIndex] == "default") {
    cfg = loadJSONObject("cfg/cfg_default.json");
  } else if (cfgs[cfgIndex] == "custom") {
    cfg = loadJSONObject("cfg/cfg_custom.json");
  } else if (cfgs[cfgIndex] == "multiplayer") {
    setupMultiplayer();
    cfg = loadJSONObject("cfg/cfg_multiplayer.json");
  } else if (cfgs[cfgIndex] == "challenge") {
    cfg = loadJSONObject("cfg/cfg_challenge.json");
  }

  floorHeight = cfg.getInt("game_floorHeight");
  cannonCount = cfg.getInt("cannon_cannonCount");
  menuUpdateDelay = cfg.getInt("menu_textUpdateDelay");
  enemySpawnDelay = cfg.getInt("missile_enemySpawnDelay");
  planeSpawnDelay = cfg.getInt("plane_enemySpawnDelay");
}


String menuTxt2() {
  // this handles the fun little animation on the main menu
  String[] periodArray = {".  ", ".. ", "..."};
  currentMenuUpdateDelay--;
  // goes through the array at the rate specified in the config file
  if (currentMenuUpdateDelay <= 0) {
    menuText2 = periodArray[menuIndex];
    menuIndex = (menuIndex != periodArray.length - 1) ? menuIndex + 1 : 0;
    currentMenuUpdateDelay = menuUpdateDelay;
  }
  return menuText2;
}

void resetScreen() {
  // clear everything off screen
  missiles.clear();
  fireballs.clear();
  tracers.clear();
  planes.clear();
  reticles.clear();
  texts.clear();
}

void newMissile(Point start, Point finish, boolean player, Missile parent) {
  Missile m = new Missile(start, finish, player, parent);
  missiles.add(m); // make a new missile in my array
  spawnTracer(m, player); // new tracer with the missile as its parent
  if (player) {
    // only the player's missiles get reticles
    newReticle(m, finish);
  }
}

void spawnEnemyMissile(Point spawn, Point finish, Missile parent) {
  // this calls the newMissile() function with parameters for an enemy missile
  // println("new missile finish.x: " + finish.x + " finish.y: " + finish.y);
  newMissile(spawn, finish, false, parent);
}

void newReticle(Missile m, Point pos) {
  Reticle r = new Reticle(pos, m); // make a new reticle where the mouse is and tie it to the missile
  reticles.add(r); // add it to the array
}

void newFireball(int x, int y, int size) {
  //println("fireball made");
  fireballs.add(new Fireball(x, y, size)); // make a new object for each fireball and and to array
}

void spawnTracer(Missile m, boolean player) {
  // create tracer with the missile as its parent
  Tracer t = new Tracer(m, player);
  // and add it to the array
  tracers.add(t);
}

void spawnPlane( Point startingPos, int bombX, boolean movingLeft ) {
  Plane p = new Plane( startingPos, bombX, movingLeft );
  planes.add(p);
}

void drawCentreLine() { // used for making sure my cannons are in the right spots and stuff
  // unused
  stroke(255);
  strokeWeight(2);
  line(width / 2, 0, width / 2, height);
}

int nextIndex(int in) {
  // return the next one in the array, jump back to the start if you're at the end
  int out = in != colourArray.length - 1 ? in + 1 : 0;
  return out;
}

color getColour(int index) {
  // bunch of different colours in the array so the fireballs and stuff can cycle through it
  colourArray[0] = color(0);
  colourArray[1] = color(255);
  colourArray[2] = color(255, 0, 0);
  colourArray[3] = color(255, 0, 242);
  colourArray[4] = color(0, 0, 255);
  colourArray[5] = color(0, 255, 0);
  colourArray[6] = color(0, 255, 247);
  colourArray[7] = color(255, 251, 0);
  // return the colour in the array
  return colourArray[index];
}

void startGame() {
  
  if (cfgs[cfgIndex] == "multiplayer") {
    setupMultiplayer();
  }
  
  menuOpen = false; // close menu
  topTenScore = false;
  actualScore = 0;
  displayScore = 0; // reset score
  int enemyStartingSpawnDelay = cfg.getInt("missile_enemyStartingSpawnDelay");
  int enemyPlaneStartingSpawnDelay = cfg.getInt("plane_enemyStartingSpawnDelay");

  enemyMissileTimer = millis() + enemyStartingSpawnDelay;// delay before starting
  enemyPlaneTimer = millis() + enemyPlaneStartingSpawnDelay;
  resetScreen();
  for (int i = 0; i < cannons.size(); i++) { // reset ammo
    Cannon c = cannons.get(i);
    c.reset();
  }
}

void gameOver() {

  menuOpen = true;

  HighScores currentHS = highScoresObjs.get(hsIndex);
  if (hsIndex<3) {
    userTyping = true;
  }
  currentHS.readAndSortScores();
  if (currentHS.checkHighScore( actualScore ) ) {
    topTenScore = true;
  }
  enemySpawnDelay = cfg.getInt("missile_enemySpawnDelay");
  planeSpawnDelay = cfg.getInt("plane_enemySpawnDelay");
}
