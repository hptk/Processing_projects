final int NUM_PLANETS = 20;
final int WIN_X = 1400, WIN_Y = 1000;

final int TEXT_SIZE = 12;
int debug_level = 1;

final float VARIANCE = 0.5;
final float SCALE = 1; //master scale variable for system model
final float SPEEDUP = 1;

final boolean ALLOW_COMETS = true;
final int COMET_SIZE = 2;
final float COMET_SPEED_PENALTY = 2.5;
final int COMET_EXTRA_DISTANCE = 50;
final int COMET_PERCENT = 70;

final int SUN_SIZE = 35;

final int PLANET_DISTANCE = 40;

final boolean ALLOW_MOONS = false;
final int MOON_PERCENT = 50;
final int MOON_SIZE = 2;
final int MOON_DISTANCE = 4;
final float MOON_EXTRA_SPEED = 1.1;

Sun sun;
int comet_count = 0;
int collision_count = 0;
int start_time = 0;

ArrayList<Planet> planets;

final int CLEAR_BUTTON_WIDTH = 50;
final int CLEAR_BUTTON_HEIGHT = TEXT_SIZE*2;
final String CLEAR_BUTTON_TEXT = "CLEAR";
final int CLEAR_BUTTON_X = WIN_X-CLEAR_BUTTON_WIDTH-3;
final int CLEAR_BUTTON_Y = 2;

void setup() {
  start_time = millis();
  size(1400, 1000);
  noStroke();
  background(0.0);
  textSize(TEXT_SIZE);
  textLeading(TEXT_SIZE);
  textAlign(LEFT, TOP);
  
  planets = new ArrayList<Planet>(NUM_PLANETS);
  sun = new Sun();
  planets.add(sun);
  
  for(int i = 0; i < NUM_PLANETS; i++) {
    float var = random(1-VARIANCE, 1+VARIANCE);
    int distance_from_sun = (int)(SCALE*PLANET_DISTANCE*var + SCALE*PLANET_DISTANCE*i);

    if(ALLOW_COMETS && (int)random(100) < COMET_PERCENT) { //comet
      double speed = SCALE*orbital_velocity(COMET_SIZE, distance_from_sun)/COMET_SPEED_PENALTY;
      planets.add(new Comet((int)(distance_from_sun+(SCALE*COMET_EXTRA_DISTANCE*var)), speed*var));
      i--;
      comet_count++;
    } else { //planet
      float size = SCALE * (4*var + i/3);
      double speed = orbital_velocity(size, distance_from_sun);
      int fill_color = (int)random(0x00f000, 0xffffff);
      int fill = 0xff000000 + fill_color;
      Planet p = new Planet(size, distance_from_sun, speed, fill);
      planets.add(p);
      if(ALLOW_MOONS && (int)random(100) < MOON_PERCENT) { //add moon
        speed = orbital_velocity(size, distance_from_sun)*(MOON_EXTRA_SPEED*SCALE);
        distance_from_sun += MOON_DISTANCE*var*SCALE;
        planets.add(new Moon(distance_from_sun, speed));
      }
    }
  }
}

void draw() {
  fill(0x0a000000);
  rect(0, 0, WIN_X, WIN_Y);
  draw_clear_button();
  for(Planet p : planets) {
    move_planet(p);
    draw_planet(p);
  }
  if(debug_level >= 1) {
    if(debug_level >= 2) {
      for(Planet p : planets) {
        write_planet_info(p);
      }
    }
    write_all_info();
  }
}

void draw_planet(Planet p) {
  if(p instanceof Comet && p.collided) return;
  fill(p.fill);
  ellipse(p.x, p.y, p.size, p.size);
}

void write_planet_info(Planet p) {
  if(p == sun) return;
  if(p.collided) return;
  fill(0x000000);
  stroke(0x000000);
  rect(p.x+p.size*SCALE, p.y+p.size*SCALE, 50+6, TEXT_SIZE*3+6);
  if(p instanceof Comet) {
    stroke(0xff00ffff);
  } else {
    stroke(0xffffffff);
  }
  fill(0x000000);
  rect(p.x+p.size*SCALE+2, p.y+p.size*SCALE+2, 50, TEXT_SIZE*3+2);
  noStroke();
  fill(0xffffffff);
  String text = "v: " + (int)(1000*pyth(p.vx, p.vy))/100.0;
  text += "\nm: " + (int)p.mass;
  text += "\nd: " + (int)distance(p, sun);
  text(text, p.x+p.size*SCALE+3, p.y+p.size*SCALE+3);
}

void write_all_info() {
  stroke(0xffffffff);
  fill(0x000000);
  rect(1, 1, 200, TEXT_SIZE*5+5);
  noStroke();
  fill(0xffffffff);

  String text = "INFORMATION:";
  text += "\nTime: " + (millis() - start_time) / 1000;
  text += "\nPlanets: " + NUM_PLANETS;
  text += "\nComets: " + comet_count;
  text += "\nCollisions: " + collision_count;
  text(text, 2, 2);
}

int get_total_planet_mass() {
  float total_mass = 0.0;
  for(Planet p : planets) {
    total_mass += p.mass;
  }
  return (int)total_mass;
}

void move_planet(Planet p1) {
  for(Planet p2 : planets) {
    if(calculate_movement(p1, p2)) {
      double force = SCALE * force_of_gravity(p1, p2);
      float angle = get_angle(p1, p2);
      p1.vx += cos(angle) * force;
      p1.vy += sin(angle) * force;
    }
  }
  if(p1.collided) return;
  p1.x += p1.vx;
  p1.y += p1.vy;
}

boolean calculate_movement(Planet p1, Planet p2){
  if(p1==p2) return false;
  if(p1 instanceof Sun) return false;
  if(p1.collided || p2.collided) return false;
  if(distance(p1, p2) < (p1.size/2) + (p2.size/2)) {
    return collision(p1, p2);
  }
  return true;
}

boolean collision(Planet p1, Planet p2){
  if(!(p2 instanceof Sun) && (p1 instanceof Comet || p1 instanceof Moon)) return false;
  if (p2 instanceof Moon) return false;
  collision_count++;

  if(!(p2 instanceof Sun)) {
    p2.collided = true;
    p2.fill = 0xffff0000;
    p2.vx = 0;
    p2.vy = 0;
    if(p2 instanceof Comet) {
      comet_count--;
      return true;
    }
  }
  p1.collided = true;
  p1.fill = 0xffff0000;
  p1.vx = 0;
  p1.vy = 0;
  return false;
}

double force_of_gravity(Planet p1, Planet p2) {
  return (p1.mass*p2.mass)/Math.pow(distance(p1, p2), 2)*(1e-4*SPEEDUP);
}

double orbital_velocity(float size, int distance_from_sun) {
  return Math.sqrt((sun.mass * Math.pow(size/2, 3)*PI*(4/3)) / distance_from_sun)/(100/SPEEDUP);
}

float get_angle(Planet p, Planet target) {
  return radians((float) Math.toDegrees(Math.atan2(target.y - p.y, target.x - p.x)));
}

double distance(Planet p1, Planet p2) {
  return pyth(p1.x - p2.x, p1.y - p2.y);
}

double pyth(double x, double y) {
  return Math.sqrt((x*x)+(y*y)); 
}

void draw_clear_button() {
  stroke(0xffffffff);
  rect(CLEAR_BUTTON_X, CLEAR_BUTTON_Y, CLEAR_BUTTON_WIDTH, CLEAR_BUTTON_HEIGHT);
  fill(0xffffffff);
  text(CLEAR_BUTTON_TEXT, CLEAR_BUTTON_X, CLEAR_BUTTON_Y);
  noStroke();
}

void mousePressed() {
  if (overRect(CLEAR_BUTTON_X, CLEAR_BUTTON_Y, CLEAR_BUTTON_WIDTH, CLEAR_BUTTON_HEIGHT)) {
    fill(0xff000000);
    rect(0, 0, WIN_X, WIN_Y);
  }
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width &&
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

class Planet {
  
  float size = 10;
  float mass = 10*10*PI;
  int pos = -1;
  
  int fill = 0xffffffff;
  boolean collided = false;
  
  float x, y;
  double vx = 0, vy = 0;
  
  Planet(float size, int distance_from_sun, double speed, int fill) {
    this.size = size;
    set_initial_position_and_speed(speed, distance_from_sun);
    this.mass = (float)Math.pow(size/2, 3)*PI*(4/3);
    this.fill = fill;
  }

  void set_initial_position_and_speed(double speed, int distance_from_sun) {
    float angle = random(2*PI);
    this.x = WIN_X/2 + distance_from_sun*cos(angle);
    this.y = WIN_Y/2 + distance_from_sun*sin(angle);
    
    angle += 1.57079633;
    
    this.vx = cos(angle) * speed;
    this.vy = sin(angle) * speed;
  }
}

class Sun extends Planet {
  Sun(){
    super(SUN_SIZE*SCALE, 0, 0, 0xffFFC000);
  }
}

class Comet extends Planet {
  Comet(int distance_from_sun, double speed) {
    super(COMET_SIZE*SCALE, distance_from_sun, speed, 0xffffffff);
  }
}

class Moon extends Planet {
  Moon(int distance_from_sun, double speed) {
    super(MOON_SIZE*SCALE, distance_from_sun, speed, 0xffffffff);
    this.vx /= 1;
    this.vy /= 1;
  }
}