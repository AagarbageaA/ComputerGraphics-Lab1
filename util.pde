import java.util.LinkedList;
import java.util.Queue;
import java.util.ArrayList;

public void CGLine(float x1, float y1, float x2, float y2) {
    int dx = (int)Math.abs(x2 - x1);
    int dy = (int)Math.abs(y2 - y1);
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
        drawPoint((int)x1, (int)y1); // Draw pixel with selected color

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

public void CGCircle(float x, float y, float r) {
    int xc = (int)x;
    int yc = (int)y;
    int radius = (int)r;

    int d = 1 - radius;
    int dx = 0;
    int dy = radius;

    while (dx <= dy) {
        drawPoint(xc + dx, yc + dy);
        drawPoint(xc - dx, yc + dy);
        drawPoint(xc + dx, yc - dy);
        drawPoint(xc - dx, yc - dy);
        drawPoint(xc + dy, yc + dx);
        drawPoint(xc - dy, yc + dx);
        drawPoint(xc + dy, yc - dx);
        drawPoint(xc - dy, yc - dx);

        if (d < 0) {
            d += 2 * dx + 3;
        } else {
            d += 2 * (dx - dy) + 5;
            dy--;
        }
        dx++;
    }
}

public void CGEllipse(float x, float y, float r1, float r2) {
    int xc = (int)x;
    int yc = (int)y;
    int rx = (int)r1;
    int ry = (int)r2;

    int rxSq = rx * rx;
    int rySq = ry * ry;
    int dx = 0;
    int dy = ry;
    int px = 0;
    int py = 2 * rxSq * dy;

    // Region 1
    int p1 = (int)(rySq - (rxSq * ry) + (0.25 * rxSq));
    while (px < py) {
        drawPoint(xc + dx, yc + dy);
        drawPoint(xc - dx, yc + dy);
        drawPoint(xc + dx, yc - dy);
        drawPoint(xc - dx, yc - dy);

        dx++;
        px += 2 * rySq;
        if (p1 < 0) {
            p1 += rySq + px;
        } else {
            dy--;
            py -= 2 * rxSq;
            p1 += rySq + px - py;
        }
    }

    // Region 2
    int p2 = (int)(rySq * (dx + 0.5) * (dx + 0.5) + rxSq * (dy - 1) * (dy - 1) - rxSq * rySq);
    while (dy >= 0) { // Changed from dy > 0 to dy >= 0 to ensure no gap
        drawPoint(xc + dx, yc + dy);
        drawPoint(xc - dx, yc + dy);
        drawPoint(xc + dx, yc - dy);
        drawPoint(xc - dx, yc - dy);

        dy--;
        py -= 2 * rxSq;
        if (p2 > 0) {
            p2 += rxSq - py;
        } else {
            dx++;
            px += 2 * rySq;
            p2 += rxSq - py + px;
        }
    }
}

public void CGCurve(Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4) {
    for (float t = 0; t <= 1; t += 0.01) {
        float x = (float) (Math.pow(1 - t, 3) * p1.x + 3 * Math.pow(1 - t, 2) * t * p2.x + 3 * (1 - t) * Math.pow(t, 2) * p3.x + Math.pow(t, 3) * p4.x);
        float y = (float) (Math.pow(1 - t, 3) * p1.y + 3 * Math.pow(1 - t, 2) * t * p2.y + 3 * (1 - t) * Math.pow(t, 2) * p3.y + Math.pow(t, 3) * p4.y);
        drawPoint(x, y);
    }
}

public void CGEraser(Vector3 p1, Vector3 p2) {
    int xStart = (int)Math.min(p1.x, p2.x);
    int xEnd = (int)Math.max(p1.x, p2.x);
    int yStart = (int)Math.min(p1.y, p2.y);
    int yEnd = (int)Math.max(p1.y, p2.y);

    for (int x = xStart; x <= xEnd; x++) {
        for (int y = yStart; y <= yEnd; y++) {
            drawPoint(x, y, color(255, 255, 255)); // Overwrite with white color (background)
        }
    }
}

public void CGSpray(float x, float y, int radius, int density) {
    for (int i = 0; i < density; i++) {
        float angle = random(0, TWO_PI); // Random angle
        float distance = random(0, radius); // Random distance within radius
        float sprayX = x + cos(angle) * distance;
        float sprayY = y + sin(angle) * distance;
        drawPoint(sprayX, sprayY); // Draw pixel with selected color
    }
}

public void CGFill(float x, float y, color targetColor, color fillColor) {
    if (targetColor == fillColor) {
        return; // Avoid infinite loop if target and fill colors are the same
    }

    Queue<Vector3> queue = new LinkedList<>();
    queue.add(new Vector3(x, y, 0));

    ArrayList<Vector3> filledPoints = new ArrayList<>(); // Store filled points

    while (!queue.isEmpty()) {
        Vector3 point = queue.poll();
        int px = (int) point.x;
        int py = (int) point.y;

        if (px < 0 || py < 0 || px >= width || py >= height) {
            continue; // Skip out-of-bounds points
        }

        color currentColor = get(px, py);
        if (currentColor == targetColor) {
            drawPoint(px, py, fillColor);
            filledPoints.add(new Vector3(px, py, 0)); // Add to filled points

            // Add neighboring points to the queue
            queue.add(new Vector3(px + 1, py, 0));
            queue.add(new Vector3(px - 1, py, 0));
            queue.add(new Vector3(px, py + 1, 0));
            queue.add(new Vector3(px, py - 1, 0));
        }
    }

    // Add the filled area as a shape to the renderer
    shapeRenderer.addShape(new FillShape(filledPoints, fillColor));
}

public void drawPoint(float x, float y) {
    stroke(selectedColor); // Use the selected color for drawing
    point(x, y);
}

public void drawPoint(float x, float y, color c) {
    stroke(c); // Use the provided color
    point(x, y);
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}
