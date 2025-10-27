Engine engine;

void setup() {
    size(1000, 600);
    frameRate(10);  // Lower frame rate to reduce rendering load
    engine = new Engine();
}

void draw() {
    background(255);

    engine.run();

}

