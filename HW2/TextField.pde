class TextField {
    float x, y, w, h;
    String text = "";
    boolean selected = false;
    boolean isFloat = true;
    float minValue = -999;
    float maxValue = 999;
    color boxColor = color(255);
    color selectedColor = color(200, 220, 255);
    color textColor = color(0);
    boolean valueChanged = false;  // Track if value has changed
    
    TextField(float x, float y, float w, float h) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
    }
    
    void setRange(float min, float max) {
        this.minValue = min;
        this.maxValue = max;
    }
    
    void setValue(float value) {
        // Constrain value to range
        value = constrain(value, minValue, maxValue);
        text = nf(value, 0, 2);
    }
    
    float getValue() {
        if (text.equals("") || text.equals("-") || text.equals(".")) {
            return constrain(0, minValue, maxValue);
        }
        try {
            float value = float(text);
            // Constrain to range and update text if out of bounds
            value = constrain(value, minValue, maxValue);
            // Update text to show constrained value
            if (float(text) != value) {
                text = nf(value, 0, 2);
            }
            return value;
        } catch (Exception e) {
            return constrain(0, minValue, maxValue);
        }
    }
    
    void show() {
        // Draw box
        stroke(selected ? color(0, 100, 255) : color(150));
        strokeWeight(selected ? 2 : 1);
        fill(selected ? selectedColor : boxColor);
        rect(x, y, w, h);
        
        // Draw text
        fill(textColor);
        textAlign(LEFT, CENTER);
        textSize(12);
        text(text, x + 5, y + h/2);
        
        // Draw cursor if selected
        if (selected && frameCount % 30 < 15) {
            float cursorX = x + 5 + textWidth(text);
            stroke(0);
            line(cursorX, y + 3, cursorX, y + h - 3);
        }
    }
    
    void click() {
        if (mousePressed) {
            // Check if clicked inside
            if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
                selected = true;
            } else {
                if (selected) {
                    // Lost focus
                    selected = false;
                    clampAndUpdateText();
                    valueChanged = true;
                }
            }
        }
    }
    
    void handleKey(char key, int keyCode) {
        if (!selected) return;
        
        if (key == BACKSPACE || keyCode == BACKSPACE) {
            if (text.length() > 0) {
                text = text.substring(0, text.length() - 1);
            }
        } else if (key == ENTER || key == RETURN || keyCode == ENTER) {
            selected = false;
            clampAndUpdateText();  // Clamp value when pressing Enter
            valueChanged = true;  // Mark that value has changed
        } else if (key >= '0' && key <= '9') {
            text += key;
        } else if (key == '.' && isFloat && text.indexOf('.') == -1) {
            text += key;
        } else if (key == '-' && text.length() == 0) {
            text += key;
        }
    }
    
    void clampAndUpdateText() {
        // Get current value (which will be clamped)
        float value = getValue();
        // Update text to show clamped value
        text = nf(value, 0, 2);
    }
    
    boolean hasChanged() {
        if (valueChanged) {
            valueChanged = false;
            return true;
        }
        return false;
    }
    
    boolean isSelected() {
        return selected;
    }
}
