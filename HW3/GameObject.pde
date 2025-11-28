public class GameObject {
    Transform transform;
    Mesh mesh;
    String name;
    Shader shader;

    GameObject() {
        transform = new Transform();
    }

    GameObject(String fname) {
        transform = new Transform();
        setMesh(fname);
        String[] sn = fname.split("\\\\");
        name = sn[sn.length - 1].substring(0, sn[sn.length - 1].length() - 4);
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    void reset() {
        transform.position.setZero();
        transform.rotation.setZero();
        transform.scale.setOnes();
    }

    void setMesh(String fname) {
        mesh = new Mesh(fname);
    }

    boolean debugPrinted = false;
    int pixelCount = 0;
    
    void Draw() {
        renderBuffer.loadPixels();
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        
        pixelCount = 0;
        
        for (int i=0; i<mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] position = triangle.verts;
            Vector4[] gl_Position = shader.vertex.main(new Object[]{position}, new Object[]{MVP});
            
            // Check if any vertex is behind camera (w <= 0)
            boolean anyBehind = false;
            for (int j = 0; j < gl_Position.length; j++) {
                if (gl_Position[j].w <= 0.001) {
                    anyBehind = true;
                    break;
                }
            }
            if (anyBehind) continue;
            
            Vector3[] s_Position = new Vector3[3];
            for (int j = 0; j<gl_Position.length; j++) {
                s_Position[j] = gl_Position[j].homogenized();
            }
            
            // Backface culling
            Vector3 edge1 = Vector3.sub(s_Position[1], s_Position[0]);
            Vector3 edge2 = Vector3.sub(s_Position[2], s_Position[0]);
            float signedArea = edge1.x * edge2.y - edge1.y * edge2.x;
            if (signedArea < 0) continue; // Back-facing
            
            Vector3[] boundbox = findBoundBox(s_Position);
            float minX = map(min( max(boundbox[0].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
            float maxX = map(min( max(boundbox[1].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
            float minY = map(min( max(boundbox[0].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
            float maxY = map(min( max(boundbox[1].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
            
            for (int y = int(minY); y < maxY; y++) {
                for (int x = int(minX); x < maxX; x++) {
                    // Sample at pixel center (x + 0.5, y + 0.5) for consistent edge behavior
                    float rx=map(x + 0.5, 0.0 , renderer_size.z - renderer_size.x, -1, 1);
                    float ry=map(y + 0.5, 0.0, renderer_size.w - renderer_size.y, -1, 1);
                    if (!pnpoly(rx, ry, s_Position)) continue;
                    int index = y * int(renderer_size.z - renderer_size.x) + x;
                    
                    float z = getDepth(rx, ry, s_Position );
                    Vector4 c = shader.fragment.main(new Object[]{new Vector3(rx, ry, z)});
                    
                    // Use >= to ensure pixels on shared edges are filled
                    if (GH_DEPTH[index] >= z) {
                        GH_DEPTH[index] = z;
                        renderBuffer.pixels[index] = color(c.x * 255, c.y*255, c.z*255);
                        pixelCount++;
                    }
                }
            }
        }
        
        // Print debug only once after loading
        if (!debugPrinted && mesh.triangles.size() > 0) {
            debugPrinted = true;
            println("Pixels filled this frame: " + pixelCount);
        }
        
        renderBuffer.updatePixels();
        update();
    }

    void update() {
    }

    void debugDraw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            
            // Transform vertices to clip space (before homogenization)
            Vector4[] clip_pos = new Vector4[3];
            for (int j = 0; j < 3; j++) {
                clip_pos[j] = MVP.mult(triangle.verts[j].getVector4(1.0));
            }
            
            // Check if all vertices are behind the camera (w <= 0)
            boolean allBehind = true;
            boolean anyBehind = false;
            for (int j = 0; j < 3; j++) {
                if (clip_pos[j].w > 0.001) {
                    allBehind = false;
                } else {
                    anyBehind = true;
                }
            }
            if (allBehind) continue;
            
            // Backface culling (only when all vertices are in front)
            if (!anyBehind) {
                Vector3[] ndc_check = new Vector3[3];
                for (int j = 0; j < 3; j++) {
                    ndc_check[j] = clip_pos[j].homogenized();
                }
                Vector3 edge1 = Vector3.sub(ndc_check[1], ndc_check[0]);
                Vector3 edge2 = Vector3.sub(ndc_check[2], ndc_check[0]);
                float signedArea = edge1.x * edge2.y - edge1.y * edge2.x;
                if (signedArea < 0) continue; // Back-facing
            }
            
            // Process each edge with near plane clipping and 3D clipping
            for (int e = 0; e < 3; e++) {
                Vector4 v0 = clip_pos[e];
                Vector4 v1 = clip_pos[(e + 1) % 3];
                
                float epsilon = 0.001;
                boolean v0_inside = v0.w > epsilon;
                boolean v1_inside = v1.w > epsilon;
                
                if (!v0_inside && !v1_inside) continue; // Both behind camera
                
                Vector4 clipped_v0 = v0;
                Vector4 clipped_v1 = v1;
                
                // Clip against near plane (w = epsilon)
                if (!v0_inside) {
                    float t = (epsilon - v0.w) / (v1.w - v0.w);
                    clipped_v0 = new Vector4(
                        v0.x + t * (v1.x - v0.x),
                        v0.y + t * (v1.y - v0.y),
                        v0.z + t * (v1.z - v0.z),
                        v0.w + t * (v1.w - v0.w)
                    );
                }
                if (!v1_inside) {
                    float t = (epsilon - v0.w) / (v1.w - v0.w);
                    clipped_v1 = new Vector4(
                        v0.x + t * (v1.x - v0.x),
                        v0.y + t * (v1.y - v0.y),
                        v0.z + t * (v1.z - v0.z),
                        v0.w + t * (v1.w - v0.w)
                    );
                }
                
                // Homogenize clipped vertices
                Vector3 ndc0 = clipped_v0.homogenized();
                Vector3 ndc1 = clipped_v1.homogenized();
                
                // Clip against NDC cube [-1, 1]
                float[] clippedLine = clipLineToFrustum(ndc0.x, ndc0.y, ndc0.z, ndc1.x, ndc1.y, ndc1.z);
                
                if (clippedLine != null) {
                    float x0 = map(clippedLine[0], -1, 1, renderer_size.x, renderer_size.z);
                    float y0 = map(clippedLine[1], -1, 1, renderer_size.y, renderer_size.w);
                    float x1 = map(clippedLine[3], -1, 1, renderer_size.x, renderer_size.z);
                    float y1 = map(clippedLine[4], -1, 1, renderer_size.y, renderer_size.w);
                    
                    CGLine(x0, y0, x1, y1);
                }
            }
        }
    }
    
    // Cohen-Sutherland inspired 3D line clipping against [-1, 1] cube
    float[] clipLineToFrustum(float x0, float y0, float z0, float x1, float y1, float z1) {
        float t0 = 0.0;
        float t1 = 1.0;
        float dx = x1 - x0;
        float dy = y1 - y0;
        float dz = z1 - z0;
        
        // Clip against all 6 planes
        float[] p = {-dx, dx, -dy, dy, -dz, dz};
        float[] q = {x0 - (-1), 1 - x0, y0 - (-1), 1 - y0, z0 - (-1), 1 - z0};
        
        for (int i = 0; i < 6; i++) {
            if (p[i] == 0) {
                // Line is parallel to the plane
                if (q[i] < 0) {
                    return null; // Line is outside the plane
                }
            } else {
                float t = q[i] / p[i];
                if (p[i] < 0) {
                    // Entering the plane
                    t0 = max(t0, t);
                } else {
                    // Leaving the plane
                    t1 = min(t1, t);
                }
            }
        }
        
        if (t0 > t1) {
            return null; // Line is completely outside
        }
        
        // Calculate clipped endpoints
        float cx0 = x0 + t0 * dx;
        float cy0 = y0 + t0 * dy;
        float cz0 = z0 + t0 * dz;
        float cx1 = x0 + t1 * dx;
        float cy1 = y0 + t1 * dy;
        float cz1 = z0 + t1 * dz;
        
        return new float[]{cx0, cy0, cz0, cx1, cy1, cz1};
    }

    String getGameObjectName() {
        return name;
    }

    Matrix4 localToWorld() {
        // Model Matrix = Translation * RotationY * RotationX * RotationZ * Scale
        // This transforms from local object space to world space
        
        Matrix4 translationMatrix = Matrix4.Trans(transform.position);
        Matrix4 rotationY = Matrix4.RotY(transform.rotation.y);
        Matrix4 rotationX = Matrix4.RotX(transform.rotation.x);
        Matrix4 rotationZ = Matrix4.RotZ(transform.rotation.z);
        Matrix4 scaleMatrix = Matrix4.Scale(transform.scale);
        
        // Apply transformations in order: Scale -> RotZ -> RotX -> RotY -> Translate
        Matrix4 modelMatrix = translationMatrix.mult(rotationY).mult(rotationX).mult(rotationZ).mult(scaleMatrix);
        
        return modelMatrix;
    }

    Matrix4 worldToLocal() {
        return Matrix4.Scale(transform.scale.inv()).mult(Matrix4.RotZ(-transform.rotation.z))
                .mult(Matrix4.RotX(-transform.rotation.x)).mult(Matrix4.RotY(-transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    Vector3 forward() {
        return (Matrix4.RotZ(transform.rotation.z).mult(Matrix4.RotX(transform.rotation.y))
                .mult(Matrix4.RotY(transform.rotation.x)).zAxis()).mult(-1);
    }
}
