public void CGLine(float x1, float y1, float x2, float y2) {
    CGLine(x1, y1, x2, y2, color(0));
}

public void CGLine(float x1, float y1, float x2, float y2, color c) {
    int dx = (int)Math.abs(x2 - x1);
    int dy = (int)Math.abs(y2 - y1);
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
        drawPoint((int)x1, (int)y1, c); // Draw pixel with selected color

        if (x1 == x2 && y1 == y2) break;

        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
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
    // You need to check the coordinate p(x,v) if inside the vertices. 
    // If yes return true, vice versa.
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
    
    
    // TODO HW2 
    // You need to find the bounding box of the vertices v.
    // r1 -------
    //   |   /\  |
    //   |  /  \ |
    //   | /____\|
    //    ------- r2

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

    // TODO HW2
    // You need to implement the Sutherland Hodgman Algorithm in this section.
    // The function you pass 2 parameter. One is the vertexes of the shape "points".
    // And the other is the vertices of the "boundary".
    // The output is the vertices of the polygon.

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
    if (abs(denom) < 1e-6) return a;  // Return point a instead of null
    float t = ((p1.x - a.x) * dy2 - (p1.y - a.y) * dx2) / denom;
    return new Vector3(a.x + t * dx1, a.y + t * dy1, 0);
}

public void CGLine_cache(PGraphics pg, float x1, float y1, float x2, float y2) {
    CGLine_cache(pg, x1, y1, x2, y2, color(0));
}

public void CGLine_cache(PGraphics pg, float x1, float y1, float x2, float y2, color c) {
    int dx = (int)Math.abs(x2 - x1);
    int dy = (int)Math.abs(y2 - y1);
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
        drawPoint_cache(pg, (int)x1, (int)y1, c);

        if (x1 == x2 && y1 == y2) break;

        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
}

public void drawPoint_cache(PGraphics pg, float x, float y, color c) {
    int index = (int) y * pg.width + (int) x;
    if (x < 0 || x >= pg.width || y < 0 || y >= pg.height)
        return;
    pg.pixels[index] = c;
}
