int num_planets = 5;
final int win_size_x = 1400, win_size_y = 1000;
final int TEXT_SIZE = 12;
boolean DEBUG = true;
Planet sun;

ArrayList<Planet> planets;

void setup() {
  size(1400, 1000);
  noStroke();
  background(0.0);
  textSize(TEXT_SIZE);
  textAlign(LEFT, TOP);
  
  planets = new ArrayList<Planet>(num_planets);
  sun = new Sun();
  planets.add(sun);
  
  for(int i = 0; i < num_planets; i++) {
    float var = random(0.9, 1.1);
    
    float size = 4*var + i/3;
    int distance_from_sun = (int)(100*var + 100*i);
    double speed = orbital_velocity(size, distance_from_sun)+0.4;
    int fill_color = (int)random(0x00f000, 0xffffff);
    int fill = 0xff000000 + fill_color;
    
    planets.add(new Planet(size, distance_from_sun, speed, fill));
  }
}

void draw() {
  fill(0xa000000);
  rect(0, 0, win_size_x, win_size_y);
  for(Planet p : planets) {
    move_planet(p);
    draw_planet(p);
  }
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
  rect(p.x+p.size-2, p.y+p.size-2, 30+6, TEXT_SIZE+6);
  stroke(0xffffffff);
  fill(0x000000);
  rect(p.x+p.size, p.y+p.size, 30, TEXT_SIZE+2);
  noStroke();
  fill(0xffffffff);
  String text = "v: " + (int)pyth(p.vx, p.vy);
  text(text, p.x+p.size, p.y+p.size);
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
        this.y = win_size_y/2 - distance_from_sun;
        this.x = win_size_x/2;
        this.vx = speed;
        break;
      case 1:
        this.y = win_size_y/2 + distance_from_sun;
        this.x = win_size_x/2;
        this.vx = -speed;
        break;
      case 2:
        this.y = win_size_y/2;
        this.x = win_size_x/2  - distance_from_sun;
        this.vy = -speed;
        break;
      case 3:
        this.y = win_size_y/2;
        this.x = win_size_x/2 + distance_from_sun;
        this.vy = speed;
    }
    
  }
}

class Sun extends Planet {
  Sun(){
    super(35, 0, 0, 0xffFFC000);
  }
}