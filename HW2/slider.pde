class Slider extends Button {
    boolean vertical = false;
    Vector3 start_end_point;
    Vector3 min_max_value;

    Slider(Vector3 p, Vector3 sep, Vector3 mmv, boolean v) {
        super(p, null);
        vertical = v;
        Vector3 s = vertical ? new Vector3(20, 10, 0) : new Vector3(10, 20, 0);
        start_end_point = sep;
        min_max_value = mmv;
        size = s;
        setBoxAndClickColor(color(100), color(70));
    }

    @Override
    public void show() {
        if (vertical) {
            fill(150);
            // Draw horizontal track
            rect(start_end_point.x, pos.y, start_end_point.y - start_end_point.x, 10);
        } else {
            fill(150);
            // Draw vertical track
            rect(pos.x, start_end_point.x, 10, start_end_point.y - start_end_point.x);
        }
        super.show();

    }

    public void click() {
        // Check if mouse is in the slider track area or on the button
        boolean inTrack = false;
        if (vertical) {
            // Horizontal slider: check if mouse is in the horizontal track area
            inTrack = mouseX >= start_end_point.x && mouseX <= start_end_point.y && 
                     mouseY >= pos.y - 5 && mouseY <= pos.y + size.y + 5;
        } else {
            // Vertical slider: check if mouse is in the vertical track area
            inTrack = mouseY >= start_end_point.x && mouseY <= start_end_point.y && 
                     mouseX >= pos.x - 5 && mouseX <= pos.x + size.x + 5;
        }
        
        if (!inTrack && !checkInSide() && !press)
            return;
            
        if (mousePressed) {
            press = true;
            if (vertical) {
                float newX = max(start_end_point.x, min(start_end_point.y, mouseX));
                pos = new Vector3(newX, pos.y, pos.z);
            } else {
                float newY = max(start_end_point.x, min(start_end_point.y, mouseY));
                pos = new Vector3(pos.x, newY, pos.z);
            }
        } else {
            press = false;
            once = false;
        }
    }

    public float value() {
        return map(vertical ? pos.x : pos.y, start_end_point.x, start_end_point.y, min_max_value.x, min_max_value.y);
    }

    public void setValue(float v) {
        if (vertical) {
            pos.x = map(v, min_max_value.x, min_max_value.y, start_end_point.x, start_end_point.y);
        } else {
            pos.y = map(v, min_max_value.x, min_max_value.y, start_end_point.x, start_end_point.y);
        }
    }

}
