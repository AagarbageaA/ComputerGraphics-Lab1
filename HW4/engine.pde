public class Engine {
    Renderer renderer;
    Inspector inspector;
    Hierarchy hierarchy;

    Vector3[] boundary = { new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0), new Vector3(1, -1, 0) };

    ArrayList<ShapeButton> shapeButton = new ArrayList<ShapeButton>();
    ShapeButton selctFileButton;
    ShapeButton DegubButton;
    ShapeButton addLightButton;
    ShapeButton removeLightButton;

    public Engine(){
        renderer = new Renderer();
        inspector = new Inspector();
        hierarchy = new Hierarchy(renderer.gameObject);
        main_camera.setSize(int(renderer_size.z - renderer_size.x) , int(renderer_size.w - renderer_size.y) , GH_NEAR_MAX , GH_FAR);
        main_camera.setPositionOrientation();
        // basic_light is created in HW4.pde setup() and added to renderer there
        initButton();        
        
    }

    public void initButton() {
        selctFileButton = new ShapeButton(20, 10, 30, 30) {

        };

        selctFileButton.setBoxAndClickColor(color(250), color(150));
        selctFileButton.setImage(loadImage("cube.png"));
        shapeButton.add(selctFileButton);

        DegubButton = new ShapeButton(60, 10, 30, 30);
        DegubButton.setBoxAndClickColor(color(250), color(150));
        DegubButton.setImage(loadImage("debug.png"));
        
        // Add Light Button
        addLightButton = new ShapeButton(100, 10, 30, 30);
        addLightButton.setBoxAndClickColor(color(255, 255, 150), color(200, 200, 100));
        addLightButton.setText("+L");
        
        // Remove Light Button
        removeLightButton = new ShapeButton(140, 10, 30, 30);
        removeLightButton.setBoxAndClickColor(color(255, 150, 150), color(200, 100, 100));
        removeLightButton.setText("-L");

    }

    void run() {
        setDepthBuffer();
        renderer.run();
        inspector.run();
        hierarchy.run();

        for (ShapeButton sb : shapeButton) {
            sb.run(() -> {
                String path = selectFile();
                // try{
                renderer.addGameObject(new GameObject(path));
                // }catch(Exception ex){
                // println("Occure some error. Please change another files");
                // }
            });
        }

        DegubButton.run(() -> {
            debug = !debug;
        });
        
        // Add new light to scene
        addLightButton.run(() -> {
            Light newLight = new Light();
            // Position new light at different location
            newLight.transform.position = new Vector3(
                random(-15, 15), 
                random(5, 15), 
                random(-15, 15)
            );
            // Random color for visual distinction
            newLight.light_color = new Vector3(
                random(0.5, 1.0),
                random(0.5, 1.0),
                random(0.5, 1.0)
            );
            
            // Generate unique name
            int lightNumber = lights.size();
            String candidateName = "Light " + lightNumber;
            
            // Check for duplicate names and increment until unique
            boolean nameExists = true;
            while (nameExists) {
                nameExists = false;
                for (Light existingLight : lights) {
                    if (existingLight.name.equals(candidateName)) {
                        nameExists = true;
                        lightNumber++;
                        candidateName = "Light " + lightNumber;
                        break;
                    }
                }
            }
            
            newLight.name = candidateName;
            lights.add(newLight);
            renderer.addGameObject(newLight);
            println("Added light: " + newLight.name + " at " + newLight.transform.position);
            println("Total lights: " + lights.size());
        });
        
        // Remove selected light (or last light if none selected)
        removeLightButton.run(() -> {
            if (lights.size() > 1) {
                Light lightToRemove = null;
                
                // Check if currently selected object in inspector is a Light
                if (inspector.gameObject != null && inspector.gameObject.getClass() == Light.class) {
                    lightToRemove = (Light) inspector.gameObject;
                } else {
                    // If no light is selected, remove the last one
                    lightToRemove = lights.get(lights.size() - 1);
                }
                
                // Remove from both lists
                lights.remove(lightToRemove);
                renderer.gameObject.remove(lightToRemove);
                
                // Remove from Hierarchy UI
                hierarchy.removeButton(lightToRemove);
                
                // Clear inspector if the removed light was selected
                if (inspector.gameObject == lightToRemove) {
                    inspector.gameObject = null;
                }
                
                println("Removed light: " + lightToRemove.name);
                println("Total lights: " + lights.size());
            } else {
                println("Cannot remove the last light!");
            }
        });
        
        main_camera.setPositionOrientation();

    }

}
