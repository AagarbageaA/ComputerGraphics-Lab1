class SprayShape implements Shape {
    private ArrayList<Vector3> points;
    private color shapeColor; // Store the color when the shape is created

    public SprayShape(ArrayList<Vector3> points) {
        this.points = new ArrayList<>(points);
        this.shapeColor = selectedColor; // Capture current color
    }

    @Override
    public void drawShape() {
        for (Vector3 point : points) {
            drawPoint(point.x, point.y, shapeColor); // Use shape's color
        }
    }
}