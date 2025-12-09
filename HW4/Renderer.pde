public class Renderer {
    private Box box;
    private ArrayList<GameObject> gameObject;

    public Renderer() {
        box = new Box(renderer_size.x, renderer_size.y, renderer_size.z - renderer_size.x,
                renderer_size.w - renderer_size.y);
        box.setBoxColor(250);
        gameObject = new ArrayList<GameObject>();
    }

    public void run() {
        box.show();
        gameObject.forEach(GameObject::Draw);
        image(renderBuffer, renderer_size.x, renderer_size.y, renderer_size.z - renderer_size.x,
                renderer_size.w - renderer_size.y);
        if (debug)
            gameObject.forEach(GameObject::debugDraw);
    }

    public void addGameObject(GameObject go) {
        gameObject.add(go);
        engine.hierarchy.addButton(go);
    }

    public boolean checkInBox(Vector3 v) {
        return box.checkInSide(v);
    }

    public void popShape() {
        if (gameObject.size() <= 0)
            return;
        gameObject.remove(gameObject.size() - 1);
    }

    public void clear() {
        gameObject.clear();
    }
}

public class Hierarchy {
    private Box box;
    ArrayList<GameObject> gameObject;
    ArrayList<HierarchyButton> buttons;

    public Hierarchy(ArrayList<GameObject> go) {
        box = new Box(500 + 40, 50, 200, height - 100);
        box.setBoxColor(250);
        gameObject = go;
        buttons = new ArrayList<HierarchyButton>();
    }

    public void addButton(GameObject go) {
        float y = buttons.size() * 30;
        HierarchyButton hb = new HierarchyButton(box.pos.x, box.pos.y + y, 200, 30);
        hb.name = go.getGameObjectName();
        hb.setBoxAndClickColor(color(250), color(150));
        hb.gameObject = go;
        buttons.add(hb);
    }
    
    public void removeButton(GameObject go) {
        // Find and remove the button associated with this GameObject
        for (int i = buttons.size() - 1; i >= 0; i--) {
            if (buttons.get(i).gameObject == go) {
                buttons.remove(i);
                break;
            }
        }
        // Reposition remaining buttons
        for (int i = 0; i < buttons.size(); i++) {
            buttons.get(i).pos.y = box.pos.y + i * 30;
        }
    }
    
    public void refreshButtons() {
        // Rebuild button list from current gameObject list
        buttons.clear();
        for (GameObject go : gameObject) {
            addButton(go);
        }
    }

    public void run() {
        textAlign(LEFT, CENTER);
        textSize(18);
        fill(0);
        text("Hierarchy", box.pos.x, box.pos.y - 10);
        box.show();

        for (HierarchyButton hb : buttons) {
            hb.run(() -> {
                engine.inspector.setGameObject(hb.gameObject);
            });
        }
    }
}

public class Inspector {
    private Box box;
    GameObject gameObject;
    Slider[] position_slider = new Slider[3];
    Slider[] rotation_slider = new Slider[3];
    Slider[] scale_slider = new Slider[3];

    Slider[] object_color_slider = new Slider[3];

    Slider[] light_color_slider = new Slider[3];
    Slider light_intensity_slider;
    
    String inspectName = "xyz";
    MaterialButton materialButton;

    public Inspector() {

        box = new Box(740 + 20, 50, 200, height - 100);
        box.setBoxColor(250);
    }

    public void setGameObject(GameObject go) {
        gameObject = go;
        for (int i = 0; i < position_slider.length; i++) {
            position_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(-50, 50, 0), true);
        }
        position_slider[0].setValue(gameObject.transform.position.x);
        position_slider[1].setValue(gameObject.transform.position.y);
        position_slider[2].setValue(gameObject.transform.position.z);

        for (int i = 0; i < rotation_slider.length; i++) {
            // Limit rotation range to avoid numerical issues near ±π/2
            // X rotation: -1.4 to 1.4 (avoid looking straight up/down)
            // Y,Z rotation: 0 to 2π (full rotation)
            Vector3 rotRange = (i == 0) ? new Vector3(-1.4, 1.4, 0) : new Vector3(0, 6.28, 0);
            rotation_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 100, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), rotRange, true);
        }
        rotation_slider[0].setValue(gameObject.transform.rotation.x);
        rotation_slider[1].setValue(gameObject.transform.rotation.y);
        rotation_slider[2].setValue(gameObject.transform.rotation.z);

        for (int i = 0; i < scale_slider.length; i++) {
            scale_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 200, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0.1, 15, 0), true);
        }
        scale_slider[0].setValue(gameObject.transform.scale.x);
        scale_slider[1].setValue(gameObject.transform.scale.y);
        scale_slider[2].setValue(gameObject.transform.scale.z);

        for (int i = 0; i < object_color_slider.length; i++) {
            object_color_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 300, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0, 1, 0), true);
        }
        // Only set object color if the object has a material
        if (gameObject.material != null) {
            object_color_slider[0].setValue(gameObject.material.albedo.x);
            object_color_slider[1].setValue(gameObject.material.albedo.y);
            object_color_slider[2].setValue(gameObject.material.albedo.z);
        } else {
            // Default values for objects without material (Camera, Light)
            object_color_slider[0].setValue(0.5);
            object_color_slider[1].setValue(0.5);
            object_color_slider[2].setValue(0.5);
        }

        for (int i = 0; i < scale_slider.length; i++) {
            light_color_slider[i] = new Slider(box.pos.add(new Vector3(40, 30 + i * 20 + 300, 0)),
                    new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0, 1, 0), true);
        }
        
        // Initialize light sliders based on selected light (if it's a Light object)
        if (gameObject.getClass() == Light.class) {
            Light selectedLight = (Light) gameObject;
            light_color_slider[0].setValue(selectedLight.light_color.x);
            light_color_slider[1].setValue(selectedLight.light_color.y);
            light_color_slider[2].setValue(selectedLight.light_color.z);
            
            light_intensity_slider = new Slider(box.pos.add(new Vector3(40, 30 + 20 + 400, 0)),
                        new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0, 5, 0), true);
            light_intensity_slider.setValue(selectedLight.intensity);
        } else {
            // Default values for non-light objects
            light_color_slider[0].setValue(0.8);
            light_color_slider[1].setValue(0.8);
            light_color_slider[2].setValue(0.8);
            
            light_intensity_slider = new Slider(box.pos.add(new Vector3(40, 30 + 20 + 400, 0)),
                        new Vector3(box.pos.x + 40, box.pos.x + 150, 0), new Vector3(0, 5, 0), true);
            light_intensity_slider.setValue(1.0);
        }

        materialButton = new MaterialButton(box.pos.add(new Vector3(40, 30 + 3 * 20 + 350, 0)),
                new Vector3(120, 40, 0));
        materialButton.setBoxAndClickColor(color(150), color(100));
    }

    public void run() {
        textAlign(LEFT, CENTER);
        textSize(18);
        fill(0);
        text("Inspector", box.pos.x, box.pos.y - 10);
        box.show();
        
        // Display light count info at top
        textAlign(LEFT, CENTER);
        textSize(12);
        fill(100, 100, 200);
        text("Lights: " + lights.size(), box.pos.x, box.pos.y + 5);
        
        if (gameObject != null) {
            textAlign(LEFT, CENTER);
            textSize(15);
            fill(0);
            text("position", box.pos.x, box.pos.y + 15);
            for (int i = 0; i < position_slider.length; i++) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text(inspectName.charAt(i), box.pos.x, position_slider[i].pos.y + 5);
                text(position_slider[i].value(), box.pos.x + 170, position_slider[i].pos.y + 5);
                position_slider[i].show();
                position_slider[i].click();
            }
            gameObject.transform.position = new Vector3(position_slider[0].value(), position_slider[1].value(),
                    position_slider[2].value());

            textAlign(LEFT, CENTER);
            textSize(15);
            fill(0);
            text("rotation", box.pos.x, box.pos.y + 15 + 100);
            for (int i = 0; i < rotation_slider.length; i++) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text(inspectName.charAt(i), box.pos.x, rotation_slider[i].pos.y + 5);
                text(rotation_slider[i].value(), box.pos.x + 170, rotation_slider[i].pos.y + 5);
                rotation_slider[i].show();
                rotation_slider[i].click();
            }
            gameObject.transform.rotation = new Vector3(rotation_slider[0].value(), rotation_slider[1].value(),
                    rotation_slider[2].value());

            // Only show scale for non-Camera objects
            if (gameObject.getClass() != Camera.class) {
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text("scale", box.pos.x, box.pos.y + 15 + 200);
                for (int i = 0; i < scale_slider.length; i++) {
                    textAlign(LEFT, CENTER);
                    textSize(15);
                    fill(0);
                    text(inspectName.charAt(i), box.pos.x, scale_slider[i].pos.y + 5);
                    text(scale_slider[i].value(), box.pos.x + 170, scale_slider[i].pos.y + 5);
                    scale_slider[i].show();
                    scale_slider[i].click();
                }
                gameObject.transform.scale = new Vector3(scale_slider[0].value(), scale_slider[1].value(),
                        scale_slider[2].value());
            }
            
            // Camera-specific display
            if (gameObject.getClass() == Camera.class) {
                Camera cam = (Camera) gameObject;
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text("Camera", box.pos.x, box.pos.y + 15 + 200);
                text("FOV: " + GH_FOV, box.pos.x, box.pos.y + 35 + 200);
                text("Near: " + cam.near, box.pos.x, box.pos.y + 55 + 200);
                text("Far: " + cam.far, box.pos.x, box.pos.y + 75 + 200);
            }
            
            // Only show material controls if object has a material (not Camera or Light)
            if (gameObject.getClass() == GameObject.class && gameObject.material != null) {

                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text("Color", box.pos.x, box.pos.y + 15 + 300);
                String rgb = "rgb";
                for (int i = 0; i < object_color_slider.length; i++) {
                    textAlign(LEFT, CENTER);
                    textSize(15);
                    fill(0);
                    text(rgb.charAt(i), box.pos.x, light_color_slider[i].pos.y + 5);
                    text(object_color_slider[i].value(), box.pos.x + 170, object_color_slider[i].pos.y + 5);
                    object_color_slider[i].show();
                    object_color_slider[i].click();
                }
                gameObject.material.albedo = new Vector3(object_color_slider[0].value(), object_color_slider[1].value(),
                        object_color_slider[2].value());

                // Update button to show current material
                switch (gameObject.me) {
                    case FM:
                        materialButton.setName("FlatMaterial");
                        break;
                    case GM:
                        materialButton.setName("GouraudMaterial");
                        break;
                    case PM:
                        materialButton.setName("PhongMaterial");
                        break;
                    case TM:
                        materialButton.setName("TextureMaterial");
                        break;
                }
                
                materialButton.run(() -> {
                    switch (gameObject.me) {
                        case FM:
                            gameObject.me = MaterialEnum.GM;
                            gameObject.material = new GouraudMaterial();
                            break;
                        case GM:
                            gameObject.me = MaterialEnum.PM;
                            gameObject.material = new PhongMaterial();
                            break;
                        case PM:
                            gameObject.me = MaterialEnum.TM;
                            String texturePath = selectTexture();
                            if (!texturePath.equals("")) {
                                gameObject.material = new TextureMaterial(texturePath);
                            } else {
                                // If user cancels, use default texture
                                gameObject.material = new TextureMaterial("data/Textures/Elon_Musk_head.bmp");
                            }
                            break;
                        case TM:
                            gameObject.me = MaterialEnum.FM;
                            gameObject.material = new FlatMaterial();
                            break;
                    }
                });
            } else if (gameObject.getClass() == Light.class) {
                Light selectedLight = (Light) gameObject;  // Cast to Light
                
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text("Light", box.pos.x, box.pos.y + 15 + 300);
                String rgb = "rgb";
                for (int i = 0; i < light_color_slider.length; i++) {
                    textAlign(LEFT, CENTER);
                    textSize(15);
                    fill(0);
                    text(rgb.charAt(i), box.pos.x, light_color_slider[i].pos.y + 5);
                    text(light_color_slider[i].value(), box.pos.x + 170, light_color_slider[i].pos.y + 5);
                    light_color_slider[i].show();
                    light_color_slider[i].click();
                }
                // Update ONLY the selected light, not basic_light
                selectedLight.light_color = new Vector3(light_color_slider[0].value(), light_color_slider[1].value(),
                        light_color_slider[2].value());
                
                textAlign(LEFT, CENTER);
                textSize(15);
                fill(0);
                text("Intensity", box.pos.x, box.pos.y + 15 + 400);  
                text("I", box.pos.x, light_intensity_slider.pos.y + 5);
                text(light_intensity_slider.value(), box.pos.x + 170, light_intensity_slider.pos.y + 5);
                light_intensity_slider.show();
                light_intensity_slider.click();
                // Update ONLY the selected light, not basic_light
                selectedLight.intensity = light_intensity_slider.value();
            }
        }
    }
}
