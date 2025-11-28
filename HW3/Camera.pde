public class Camera {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;
    Transform transform;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform = new Transform();
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {
        wid = w;
        hei = h;
        near = n;
        far = f;
        
        // Perspective Projection Matrix
        // Using FOV (field of view), aspect ratio, near and far planes
        
        float aspect = (float)w / (float)h;
        float fovRad = radians(GH_FOV);
        float tanHalfFov = tan(fovRad / 2.0);
        
        // Standard OpenGL perspective projection matrix (row-major for this framework)
        // Maps z from [-n, -f] to [-1, 1] in NDC
        // 
        // | 1/(aspect*tan(fov/2))  0              0                    0                |
        // | 0                      1/tan(fov/2)   0                    0                |
        // | 0                      0              (f+n)/(f-n)          -2*f*n/(f-n)     |
        // | 0                      0              1                    0                |
        
        projection.makeZero();
        projection.m[0] = 1.0 / (aspect * tanHalfFov);
        projection.m[5] = 1.0 / tanHalfFov;
        projection.m[10] = (f + n) / (f - n);
        projection.m[11] = -2.0 * f * n / (f - n);
        projection.m[14] = 1.0;
    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {
        // Alternative method using rotation angles
        Matrix4 rotationX = Matrix4.RotX(-rotX);
        Matrix4 rotationY = Matrix4.RotY(-rotY);
        Matrix4 translation = Matrix4.Trans(pos.mult(-1));
        worldView = rotationX.mult(rotationY).mult(translation);
    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
        // LookAt View Matrix construction
        // pos: camera position
        // lookat: target point the camera is looking at
        // up: world up vector (0, 1, 0)
        
        Vector3 up = new Vector3(0, 1, 0);
        
        // Calculate camera coordinate system axes
        // Forward: direction from camera to target
        Vector3 forward = Vector3.sub(lookat, pos).unit_vector();
        
        // Right (x-axis): perpendicular to forward and up
        Vector3 right = Vector3.cross(forward, up).unit_vector();
        
        // Recalculate up (y-axis): perpendicular to right and forward
        Vector3 newUp = Vector3.cross(right, forward).unit_vector();
        
        // View matrix transforms world coordinates to camera coordinates
        // Objects in front of camera should have positive Z in view space
        // (to work with our projection matrix that expects positive Z)
        
        worldView.makeIdentity();
        
        // Row 0: right vector
        worldView.m[0] = right.x;
        worldView.m[1] = right.y;
        worldView.m[2] = right.z;
        worldView.m[3] = -Vector3.dot(right, pos);
        
        // Row 1: up vector  
        worldView.m[4] = newUp.x;
        worldView.m[5] = newUp.y;
        worldView.m[6] = newUp.z;
        worldView.m[7] = -Vector3.dot(newUp, pos);
        
        // Row 2: forward vector (positive Z = in front of camera)
        worldView.m[8] = forward.x;
        worldView.m[9] = forward.y;
        worldView.m[10] = forward.z;
        worldView.m[11] = -Vector3.dot(forward, pos);
        
        // Row 3: homogeneous coordinate
        worldView.m[12] = 0;
        worldView.m[13] = 0;
        worldView.m[14] = 0;
        worldView.m[15] = 1;
    }
}
