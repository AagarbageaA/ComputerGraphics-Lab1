import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public Vector4 renderer_size;
static public float GH_FOV = 45.0f;
static public float GH_NEAR_MIN = 1e-3f;
static public float GH_NEAR_MAX = 1e-1f;
static public float GH_FAR = 1000.0f;

public boolean debug = false;

public float[] GH_DEPTH;
public PImage renderBuffer;

Engine engine;
Camera main_camera;
Vector3 cam_position;
Vector3 lookat;

void setup() {
    size(1000, 600);
    renderer_size = new Vector4(20, 50, 520, 550);
    cam_position = new Vector3(0, 0, -10);
    lookat = new Vector3(0, 0, 0);
    setDepthBuffer();
    main_camera = new Camera();
    engine = new Engine();

}

void setDepthBuffer(){
    renderBuffer = new PImage(int(renderer_size.z - renderer_size.x) , int(renderer_size.w - renderer_size.y));
    GH_DEPTH = new float[int(renderer_size.z - renderer_size.x) * int(renderer_size.w - renderer_size.y)];
    renderBuffer.loadPixels();
    for(int i = 0 ; i < GH_DEPTH.length;i++){
        GH_DEPTH[i] = 1.0;  // Far plane in NDC is 1.0
        renderBuffer.pixels[i] = color(250);  // Light background to match debug mode
    }
    renderBuffer.updatePixels();
}

void draw() {
    background(255);

    engine.run();
    cameraControl();
}

String selectFile() {
    JFileChooser fileChooser = new JFileChooser();
    fileChooser.setCurrentDirectory(new File("."));
    fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
    FileNameExtensionFilter filter = new FileNameExtensionFilter("Obj Files", "obj");
    fileChooser.setFileFilter(filter);

    int result = fileChooser.showOpenDialog(null);
    if (result == JFileChooser.APPROVE_OPTION) {
        String filePath = fileChooser.getSelectedFile().getAbsolutePath();
        return filePath;
    }
    return "";
}

void cameraControl(){
    // Orbit Camera Control
    // WASD: rotate camera around the lookat point (orbit)
    // QE: zoom in/out
    // Arrow keys: move lookat point
    
    float orbitSpeed = 0.02;
    float zoomSpeed = 0.2;
    float panSpeed = 0.1;
    
    if (keyPressed) {
        // Get current orbit parameters
        Vector3 offset = Vector3.sub(cam_position, lookat);
        float radius = offset.length();
        float theta = atan2(offset.x, offset.z);  // Horizontal angle
        float phi = asin(offset.y / radius);       // Vertical angle
        
        // WASD: Orbit around the object
        if (key == 'a' || key == 'A') {
            theta += orbitSpeed;  // Rotate left
        }
        if (key == 'd' || key == 'D') {
            theta -= orbitSpeed;  // Rotate right
        }
        if (key == 'w' || key == 'W') {
            phi = constrain(phi + orbitSpeed, -HALF_PI + 0.1, HALF_PI - 0.1);  // Rotate up
        }
        if (key == 's' || key == 'S') {
            phi = constrain(phi - orbitSpeed, -HALF_PI + 0.1, HALF_PI - 0.1);  // Rotate down
        }
        
        // Update camera position based on spherical coordinates
        cam_position.x = lookat.x + radius * cos(phi) * sin(theta);
        cam_position.y = lookat.y + radius * sin(phi);
        cam_position.z = lookat.z + radius * cos(phi) * cos(theta);
        
        // QE: Zoom in/out
        if (key == 'q' || key == 'Q') {
            radius = max(1.0, radius - zoomSpeed);  // Zoom in
            cam_position.x = lookat.x + radius * cos(phi) * sin(theta);
            cam_position.y = lookat.y + radius * sin(phi);
            cam_position.z = lookat.z + radius * cos(phi) * cos(theta);
        }
        if (key == 'e' || key == 'E') {
            radius = radius + zoomSpeed;  // Zoom out
            cam_position.x = lookat.x + radius * cos(phi) * sin(theta);
            cam_position.y = lookat.y + radius * sin(phi);
            cam_position.z = lookat.z + radius * cos(phi) * cos(theta);
        }
        
        // Arrow keys: Pan (move lookat point)
        if (keyCode == LEFT) {
            Vector3 right = Vector3.cross(Vector3.sub(lookat, cam_position).unit_vector(), new Vector3(0, 1, 0)).unit_vector();
            lookat.minus(right.mult(panSpeed));
            cam_position.minus(right.mult(panSpeed));
        }
        if (keyCode == RIGHT) {
            Vector3 right = Vector3.cross(Vector3.sub(lookat, cam_position).unit_vector(), new Vector3(0, 1, 0)).unit_vector();
            lookat.plus(right.mult(panSpeed));
            cam_position.plus(right.mult(panSpeed));
        }
        if (keyCode == UP) {
            lookat.y += panSpeed;
            cam_position.y += panSpeed;
        }
        if (keyCode == DOWN) {
            lookat.y -= panSpeed;
            cam_position.y -= panSpeed;
        }
    }
    
    main_camera.setPositionOrientation(cam_position, lookat);
    main_camera.setSize(int(renderer_size.z - renderer_size.x), int(renderer_size.w - renderer_size.y), GH_NEAR_MIN, GH_FAR);
}
