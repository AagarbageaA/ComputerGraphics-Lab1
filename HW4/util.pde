public void CGLine(float x1, float y1, float x2, float y2) {
    stroke(0);
    line(x1, y1, x2, y2);
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
    // TODO HW2
    // You need to check the coordinate p(x,v) if inside the vertexes.
    // Ray casting algorithm to check if point (x,y) is inside polygon
    int n = vertexes.length;
    boolean inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        if (((vertexes[i].y > y) != (vertexes[j].y > y)) &&
            (x < (vertexes[j].x - vertexes[i].x) * (y - vertexes[i].y) / (vertexes[j].y - vertexes[i].y) + vertexes[i].x)) {
            inside = !inside;
        }
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    Vector3 recordminV = new Vector3(1.0 / 0.0);
    Vector3 recordmaxV = new Vector3(-1.0 / 0.0);
    // TODO HW2
    // You need to find the bounding box of the vertexes v.
    
    if (v.length == 0) {
        recordminV = new Vector3(0);
        recordmaxV = new Vector3(0);
        Vector3[] result = { recordminV, recordmaxV };
        return result;
    }
    
    float minX = v[0].x;
    float minY = v[0].y;
    float maxX = v[0].x;
    float maxY = v[0].y;
    
    for (int i = 1; i < v.length; i++) {
        if (v[i].x < minX) minX = v[i].x;
        if (v[i].y < minY) minY = v[i].y;
        if (v[i].x > maxX) maxX = v[i].x;
        if (v[i].y > maxY) maxY = v[i].y;
    }
    
    recordminV = new Vector3(minX, minY, 0);
    recordmaxV = new Vector3(maxX, maxY, 0);
    Vector3[] result = { recordminV, recordmaxV };
    return result;
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i += 1) {
        input.add(points[i]);
    }

    // TODO HW2
    // You need to implement the Sutherland Hodgman Algorithm in this section.
    // The function you pass 2 parameter. One is the vertexes of the shape "points".
    // And the other is the vertexes of the "boundary".
    // The output is the vertexes of the polygon.

    output = input;

    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i += 1) {
        result[i] = output.get(i);
    }
    return result;
}

public float getDepth(float x, float y, Vector3[] vertex) {
    // TODO HW3
    // You need to calculate the depth (z) in the triangle (vertex) based on the
    // positions x and y. and return the z value;
    
    Vector3 A = vertex[0];
    Vector3 B = vertex[1];
    Vector3 C = vertex[2];
    
    // Calculate barycentric coordinates
    float denominator = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    
    if (abs(denominator) < 1e-10) {
        return (A.z + B.z + C.z) / 3.0;
    }
    
    float u = ((B.y - C.y) * (x - C.x) + (C.x - B.x) * (y - C.y)) / denominator;
    float v = ((C.y - A.y) * (x - C.x) + (A.x - C.x) * (y - C.y)) / denominator;
    float w = 1.0 - u - v;
    
    // Interpolate z value
    float z = u * A.z + v * B.z + w * C.z;
    
    return z;
}

float[] barycentric(Vector3 P, Vector4[] verts) {

    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    Vector4 AW = verts[0];
    Vector4 BW = verts[1];
    Vector4 CW = verts[2];

    // TODO HW4
    // Calculate the barycentric coordinates of point P in the triangle verts using
    // the barycentric coordinate system.
    // Please notice that you should use Perspective-Correct Interpolation otherwise
    // you will get wrong answer.

    // Calculate barycentric coordinates in screen space
    // Using the formula with cross products
    Vector3 v0 = B.sub(A);
    Vector3 v1 = C.sub(A);
    Vector3 v2 = P.sub(A);
    
    float d00 = Vector3.dot(v0, v0);
    float d01 = Vector3.dot(v0, v1);
    float d11 = Vector3.dot(v1, v1);
    float d20 = Vector3.dot(v2, v0);
    float d21 = Vector3.dot(v2, v1);
    
    float denom = d00 * d11 - d01 * d01;
    
    // Check for degenerate triangle
    if (abs(denom) < 1e-10) {
        // Return equal weights for degenerate case
        float[] result = { 1.0/3.0, 1.0/3.0, 1.0/3.0 };
        return result;
    }
    
    // Screen space barycentric coordinates
    float beta_screen = (d11 * d20 - d01 * d21) / denom;
    float gamma_screen = (d00 * d21 - d01 * d20) / denom;
    float alpha_screen = 1.0 - beta_screen - gamma_screen;
    
    // Perspective-correct interpolation
    // The correct formula is: 
    // alpha/w_a, beta/w_b, gamma/w_c should be interpolated linearly
    // Then normalize by dividing by the sum
    float w_a = AW.w;
    float w_b = BW.w;
    float w_c = CW.w;
    
    // Calculate perspective-corrected weights
    float alpha_over_w = alpha_screen / w_a;
    float beta_over_w = beta_screen / w_b;
    float gamma_over_w = gamma_screen / w_c;
    
    float sum = alpha_over_w + beta_over_w + gamma_over_w;
    
    float alpha = alpha_over_w / sum;
    float beta = beta_over_w / sum;
    float gamma = gamma_over_w / sum;

    float[] result = { alpha, beta, gamma };

    return result;
}

Vector3 interpolation(float[] abg, Vector3[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

Vector4 interpolation(float[] abg, Vector4[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

float interpolation(float[] abg, float[] v) {
    return v[0] * abg[0] + v[1] * abg[1] + v[2] * abg[2];
}
