import java.util.ArrayList;

public class FillShape implements Shape {
    private ArrayList<Vector3> points;
    private color fillColor;

    public FillShape(ArrayList<Vector3> points, color fillColor) {
        this.points = points;
        this.fillColor = fillColor;
    }

    @Override
    public void drawShape() {
        for (Vector3 point : points) {
            stroke(fillColor);
            point(point.x, point.y);
        }
    }
}