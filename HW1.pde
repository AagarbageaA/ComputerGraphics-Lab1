ShapeButton lineButton;
ShapeButton circleButton;
ShapeButton polygonButton;
ShapeButton ellipseButton;
ShapeButton curveButton;
ShapeButton pencilButton;
ShapeButton eraserButton;
ShapeButton sprayButton;
ShapeButton fillButton;

Button clearButton;

ShapeRenderer shapeRenderer;
ArrayList<ShapeButton> shapeButton;
ArrayList<Button> colorPaletteButtons = new ArrayList<>(); // List for color palette buttons
float eraserSize = 20;
color selectedColor = color(0, 0, 0); // Default color is black

public void setup() {
    size(1000, 800);
    background(255);
    shapeRenderer = new ShapeRenderer();
    initButton();
    initColorPicker();

}

public void draw() {

    // Clear button areas and palette area to avoid visual artifacts
    fill(255);
    noStroke();
    rect(0, 0, width, 50); // Clear top bar for tool buttons
    rect(width - 200, 50, 200, height - 50); // Clear right side panel for color palette (narrower)

    for (ShapeButton sb : shapeButton) {
        sb.run(() -> {
            sb.beSelect();
            shapeRenderer.setRenderer(sb.getRendererType());
        });
    }

    clearButton.run(() -> {
        shapeRenderer.clear();
    });
    
    shapeRenderer.box.show();
    shapeRenderer.run();

    // Draw color picker buttons (always visible on the right side)
    for (Button button : colorPaletteButtons) {
        button.run(() -> {
            selectedColor = button.getClickColor(); // Update the selected color
        });
        fill(button.getClickColor()); // Set the button's color
        noStroke();
        rect(button.pos.x, button.pos.y, button.size.x, button.size.y);
    }

    // Display the currently selected color indicator
    fill(selectedColor);
    noStroke();
    rect(width - 90, 10, 30, 30); // Show current color next to clear button
    
    // Draw a label for the color palette
    fill(0);
    textAlign(LEFT);
    textSize(12);
    text("Colors:", width - 180, 50);

}

void resetButton() {
    for (ShapeButton sb : shapeButton) {
        sb.setSelected(false);
    }
}

public void initButton() {
    shapeButton = new ArrayList<ShapeButton>();
    lineButton = new ShapeButton(10, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            line(pos.x + 2, pos.y + 2, pos.x + size.x - 2, pos.y + size.y - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new LineRenderer();
        }
    };

    lineButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(lineButton);

    circleButton = new ShapeButton(45, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            circle(pos.x + size.x / 2, pos.y + size.y / 2, size.x - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new CircleRenderer();
        }
    };
    circleButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(circleButton);

    polygonButton = new ShapeButton(80, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            line(pos.x + 2, pos.y + 2, pos.x + size.x - 2, pos.y + 2);
            line(pos.x + 2, pos.y + size.y - 2, pos.x + size.x - 2, pos.y + size.y - 2);
            line(pos.x + size.x - 2, pos.y + 2, pos.x + size.x - 2, pos.y + size.y - 2);
            line(pos.x + 2, pos.y + 2, pos.x + 2, pos.y + size.y - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new PolygonRenderer();
        }

    };

    polygonButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(polygonButton);

    ellipseButton = new ShapeButton(115, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            ellipse(pos.x + size.x / 2, pos.y + size.y / 2, size.x - 2, size.y * 2 / 3);
        }

        @Override
        public Renderer getRendererType() {
            return new EllipseRenderer();
        }

    };

    ellipseButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(ellipseButton);

    curveButton = new ShapeButton(150, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            bezier(pos.x, pos.y, pos.x, pos.y + size.y, pos.x + size.x, pos.y, pos.x + size.x, pos.y + size.y);
        }

        @Override
        public Renderer getRendererType() {
            return new CurveRenderer();
        }

    };

    curveButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(curveButton);

    clearButton = new Button(width - 50, 10, 30, 30);
    clearButton.setBoxAndClickColor(color(250), color(150));
    clearButton.setImage(loadImage("clear.png"));

    pencilButton = new ShapeButton(185, 10, 30, 30) {
        @Override
        public Renderer getRendererType() {
            return new PencilRenderer();
        }
    };
    pencilButton.setImage(loadImage("pencil.png"));

    pencilButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(pencilButton);

    eraserButton = new ShapeButton(220, 10, 30, 30) {
        @Override
        public Renderer getRendererType() {
            return new EraserRenderer();
        }
    };
    eraserButton.setImage(loadImage("eraser.png"));

    eraserButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(eraserButton);

    sprayButton = new ShapeButton(255, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            PImage sprayIcon = loadImage("data/spray.png");
            image(sprayIcon, pos.x, pos.y, size.x, size.y);
        }

        @Override
        public Renderer getRendererType() {
            return new SprayRenderer();
        }
    };

    sprayButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(sprayButton);

    fillButton = new ShapeButton(290, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            PImage fillIcon = loadImage("data/fill.png");
            image(fillIcon, pos.x, pos.y, size.x, size.y);
        }

        @Override
        public Renderer getRendererType() {
            return new FillRenderer();
        }
    };

    fillButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(fillButton);

}

public void keyPressed() {
    if (key == 'z' || key == 'Z') {
        shapeRenderer.popShape();
    }

}

void mouseWheel(MouseEvent event) {
    float e = event.getCount();
    if (e < 0)
        eraserSize += 1;
    else if (e > 0)
        eraserSize -= 1;
    eraserSize = max(min(eraserSize, 30), 4);
}

public void initColorPicker() {
    // Define 16 colors for the palette
    color[] palette = {
        color(0, 0, 0), color(255, 255, 255), color(255, 0, 0), color(0, 255, 0),
        color(0, 0, 255), color(255, 255, 0), color(0, 255, 255), color(255, 0, 255),
        color(128, 128, 128), color(128, 0, 0), color(0, 128, 0), color(0, 0, 128),
        color(128, 128, 0), color(0, 128, 128), color(128, 0, 128), color(192, 192, 192)
    };

    // Create buttons for each color in the palette
    // Place them on the right side of the canvas
    int buttonSize = 35; // Slightly smaller button size
    int spacing = 3; // Smaller spacing between buttons
    int startX = width - 180; // Less margin from right edge
    int startY = 60; // Start below the top toolbar
    for (int i = 0; i < palette.length; i++) {
        int x = startX + (i % 4) * (buttonSize + spacing); // 4 columns
        int y = startY + (i / 4) * (buttonSize + spacing); // 4 rows
        color currentColor = palette[i]; // Create a final copy of the current color
        Button colorButton = new Button(x, y, buttonSize, buttonSize);
        colorButton.setClickColor(currentColor);
        colorButton.setBoxAndClickColor(currentColor, currentColor);
        colorPaletteButtons.add(colorButton);
    }
}
