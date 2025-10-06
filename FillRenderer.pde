class FillRenderer implements Renderer {
    @Override
    public void render() {
        if (!shapeRenderer.checkInBox(new Vector3(mouseX, mouseY, 0))) return;
        if (mousePressed) {
            color targetColor = get(mouseX, mouseY);
            CGFill(mouseX, mouseY, targetColor, selectedColor); // Use selected color from palette
        }
    }
}