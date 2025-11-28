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
    // Find the bounding box (min and max corners) of vertices
    if (v.length == 0) {
        Vector3 recordminV = new Vector3(0);
        Vector3 recordmaxV = new Vector3(0);
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
    
    Vector3 recordminV = new Vector3(minX, minY, 0);
    Vector3 recordmaxV = new Vector3(maxX, maxY, 0);
    Vector3[] result = { recordminV, recordmaxV };
    return result;
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i += 1) {
        input.add(points[i]);
    }

    // Sutherland Hodgman Algorithm implementation
    // Clip polygon against each edge of the boundary
    ArrayList<Vector3> current = new ArrayList<>(input);
    for (int i = 0; i < boundary.length; i++) {
        Vector3 p1 = boundary[i];
        Vector3 p2 = boundary[(i + 1) % boundary.length];
        current = clipToEdge(current, p1, p2);
    }
    output = current;

    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i += 1) {
        result[i] = output.get(i);
    }
    return result;
}

ArrayList<Vector3> clipToEdge(ArrayList<Vector3> input, Vector3 p1, Vector3 p2) {
    ArrayList<Vector3> output = new ArrayList<>();
    if (input.size() == 0) return output;
    
    for (int i = 0; i < input.size(); i++) {
        Vector3 s = input.get(i);
        Vector3 prev = input.get((i + input.size() - 1) % input.size());
        boolean s_inside = isInside(s, p1, p2);
        boolean prev_inside = isInside(prev, p1, p2);
        if (s_inside) {
            if (!prev_inside) {
                Vector3 inter = intersection(prev, s, p1, p2);
                output.add(inter);
            }
            output.add(s);
        } else if (prev_inside) {
            Vector3 inter = intersection(prev, s, p1, p2);
            output.add(inter);
        }
    }
    return output;
}

boolean isInside(Vector3 s, Vector3 p1, Vector3 p2) {
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    float cross = (s.x - p1.x) * dy - (s.y - p1.y) * dx;
    return cross >= 0;
}

Vector3 intersection(Vector3 a, Vector3 b, Vector3 p1, Vector3 p2) {
    float dx1 = b.x - a.x;
    float dy1 = b.y - a.y;
    float dx2 = p2.x - p1.x;
    float dy2 = p2.y - p1.y;
    float denom = dx1 * dy2 - dy1 * dx2;
    if (abs(denom) < 1e-6) return a;
    float t = ((p1.x - a.x) * dy2 - (p1.y - a.y) * dx2) / denom;
    return new Vector3(a.x + t * dx1, a.y + t * dy1, 0);
}

public float getDepth(float x, float y, Vector3[] vertex) {
    // Calculate depth (z) using barycentric interpolation
    // Given a point (x, y) and triangle vertices, interpolate the z value
    
    Vector3 A = vertex[0];
    Vector3 B = vertex[1];
    Vector3 C = vertex[2];
    
    // Calculate barycentric coordinates
    // Using the formula: P = u*A + v*B + w*C where u + v + w = 1
    float denominator = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    
    if (abs(denominator) < 1e-10) {
        // Degenerate triangle, return average z
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

    // TODO HW4
    // Calculate the barycentric coordinates of point P in the triangle verts using
    // the barycentric coordinate system.

    float[] result = { 0.0, 0.0, 0.0 };

    return result;
}
