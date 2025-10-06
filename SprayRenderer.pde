class SprayRenderer implements Renderer {
    private ArrayList<Vector3> sprayPoints = new ArrayList<>();

    @Override
    public void render() {
        if (!shapeRenderer.checkInBox(new Vector3(mouseX, mouseY, 0))) return;
        if (mousePressed) {
            int radius = 20; // Spray radius
            int density = 50; // Number of points in the spray
            ArrayList<Vector3> currentSprayPoints = new ArrayList<>();
            for (int i = 0; i < density; i++) {
                float angle = random(0, TWO_PI);
                float distance = random(0, radius);
                float sprayX = mouseX + cos(angle) * distance;
                float sprayY = mouseY + sin(angle) * distance;
                Vector3 point = new Vector3(sprayX, sprayY, 0);
                currentSprayPoints.add(point);
                drawPoint(sprayX, sprayY, color(0, 0, 0));
            }
            shapeRenderer.addShape(new SprayShape(currentSprayPoints));
        }
    }
}