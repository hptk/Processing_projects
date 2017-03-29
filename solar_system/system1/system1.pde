final int NUM_PLANETS = 5;
final int WIN_X = 1400, WIN_Y = 1000;
final int TEXT_SIZE = 12;
final float VARIANCE = 0.6;
final boolean DEBUG = true;
final boolean ALLOW_COMETS = true;
final int COMET_SIZE = 2;

Sun sun;
int comet_count = 0;
int collision_count = 0;
int start_time = 0;

ArrayList<Planet> planets;

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
    int distance_from_sun = (int)(100*var + 100*i);

    if(ALLOW_COMETS && (int)random(5)%5 == 0) { //comet
      double speed = orbital_velocity(COMET_SIZE, distance_from_sun)/3;
      planets.add(new Comet((int)(distance_from_sun+(250*var)), speed*var));
      i--;
      comet_count++;
    } else { //planet
      float size = 4*var + i/3;
      double speed = orbital_velocity(size, distance_from_sun)+0.4;
      int fill_color = (int)random(0x00f000, 0xffffff);
      int fill = 0xff000000 + fill_color;
      planets.add(new Planet(size, distance_from_sun, speed, fill));
    }
  }
}

void draw() {
  fill(0xa000000);
  rect(0, 0, WIN_X, WIN_Y);
  for(Planet p : planets) {
    move_planet(p);
    draw_planet(p);
  }
  if(DEBUG) write_all_info();
}

void draw_planet(Planet p) {
  fill(p.fill);
  ellipse(p.x, p.y, p.size, p.size);
  if(DEBUG) write_planet_info(p);
}

void write_planet_info(Planet p) {
  if(p == sun) return;
  fill(0x000000);
  stroke(0x000000);
  rect(p.x+p.size, p.y+p.size, 45+6, TEXT_SIZE*2+6);
  stroke(0xffffffff);
  fill(0x000000);
  rect(p.x+p.size+2, p.y+p.size+2, 45, TEXT_SIZE*2+2);
  noStroke();
  fill(0xffffffff);
  String text = "v: " + (int)pyth(p.vx, p.vy) + "\nm: " + (int)p.mass;
  text(text, p.x+p.size+3, p.y+p.size+2);
}

void write_all_info() {
  stroke(0xffffffff);
  fill(0x000000);
  rect(1, 1, 200, TEXT_SIZE*5+2);
  noStroke();
  fill(0xffffffff);
  
  String text = "INFORMATION:";
  text += "\nPlanets: " + NUM_PLANETS;
  text += "\nComets: " + comet_count;
  text += "\nCollisions: " + collision_count;
  text += "\nTime: " + (millis() - start_time) / 1000;
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
      double force = force_of_gravity(p1, p2)*2;
      float angle = get_angle(p1, p2);
      p1.vx += cos(angle) * force;
      p1.vy += sin(angle) * force;
    }
  }
  if(p1.collided) return;
  p1.x += p1.vx/10;
  p1.y += p1.vy/10;
}

boolean calculate_movement(Planet p1, Planet p2){
  if(p1==p2) return false;
  if(p1 instanceof Sun) return false;
  if(p1.collided || p2.collided) return false;
  if(distance(p1, p2) < (p1.size/2) + (p2.size/2)) {
    collision(p1, p2);
    return false;
  }
  return true;
}

void collision(Planet p1, Planet p2){ 
  p1.collided = true;
  p1.fill = 0xffff0000;
  p1.vx = 0;
  p1.vy = 0;
  if(!(p2 instanceof Sun)) {
    p2.collided = true;
    p2.fill = 0xffff0000;
    p2.vx = 0;
    p2.vy = 0;
  }
  collision_count++;
}

double force_of_gravity(Planet p1, Planet p2) {
  return 0.3 * (p1.mass*p2.mass)/Math.pow(distance(p1, p2), 2)*10e-5;
}

double orbital_velocity(float size, int distance_from_sun) {
  return Math.sqrt((75 * size*size*size*PI*(4/3)) / distance_from_sun);
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


class Planet {
  
  float size = 10;
  float mass = 10*10*PI;
  
  int fill = 0xffffffff;
  boolean collided = false;
  
  float x, y;
  double vx = 0, vy = 0;
  
  Planet(float size, int distance_from_sun, double speed, int fill) {
    this.size = size;
    set_initial_position_and_speed(speed, distance_from_sun);
    this.mass = size*size*size*PI*(4/3);
    this.fill = fill;
  }
  
  void set_initial_position_and_speed(double speed, int distance_from_sun) {
    int pos = (int)random(1000)%4;
    
    switch(pos){
      case 0:
        this.y = WIN_Y/2 - distance_from_sun;
        this.x = WIN_X/2;
        this.vx = speed;
        break;
      case 1:
        this.y = WIN_Y/2 + distance_from_sun;
        this.x = WIN_X/2;
        this.vx = -speed;
        break;
      case 2:
        this.y = WIN_Y/2;
        this.x = WIN_X/2  - distance_from_sun;
        this.vy = -speed;
        break;
      case 3:
        this.y = WIN_Y/2;
        this.x = WIN_X/2 + distance_from_sun;
        this.vy = speed;
    }
    
  }
}

class Sun extends Planet {
  Sun(){
    super(35, 0, 0, 0xffFFC000);
  }
}

class Comet extends Planet {
  Comet(int distance_from_sun, double speed) {
    super(COMET_SIZE, distance_from_sun, speed, 0xffffffff);
  }
}