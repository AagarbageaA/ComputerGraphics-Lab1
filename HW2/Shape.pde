
public class Shape{   
    Vector3[] vertex = new Vector3[0];
    Transform transform = new Transform();
    PGraphics cache;
    Transform lastTransform;
    boolean cacheValid = false;
    
    public void drawShape(){    
        drawShape(false);
    }
    
    public void drawShape(boolean outlineOnly){    
        if (vertex.length == 0) return;
        
        loadPixels();
        
        // Apply transform per-vertex around centroid to avoid matrix-order pivot issues
        Vector3[] t_pos = new Vector3[vertex.length];
        // compute centroid in local coordinates
        float cx = 0;
        float cy = 0;
        for (int i = 0; i < vertex.length; i++){
            cx += vertex[i].x;
            cy += vertex[i].y;
        }
        cx /= vertex.length;
        cy /= vertex.length;

        float a = transform.rotation.z;
        float ca = cos(a);
        float sa = sin(a);
        float sx = transform.scale.x;
        float sy = transform.scale.y;
        for (int i = 0; i < vertex.length; i++){
            float lx = vertex[i].x - cx;
            float ly = vertex[i].y - cy;
            // scale
            lx *= sx;
            ly *= sy;
            // rotate
            float rx = lx * ca - ly * sa;
            float ry = lx * sa + ly * ca;
            // translate back and apply position
            float wx = rx + cx + transform.position.x;
            float wy = ry + cy + transform.position.y;
            t_pos[i] = new Vector3(wx, wy, 0);
        }
        
    t_pos = Sutherland_Hodgman_algorithm(t_pos,engine.boundary);
        
        if (t_pos.length == 0) {
            updatePixels();
            return;
        }
        
        for(int i=0;i<t_pos.length;i++){
            t_pos[i] = new Vector3(map(t_pos[i].x,-1,1,20,520),map(t_pos[i].y,-1,1,50,height-50),0);
        }

        // Fill the polygon with SSAA (2x2 super sampling)
        Vector3[] minmax = findBoundBox(t_pos);
        int minX = max(20, int(minmax[0].x));
        int maxX = min(520, int(minmax[1].x));
        int minY = max(50, int(minmax[0].y));
        int maxY = min(height-50, int(minmax[1].y));
        for(int i = minX; i <= maxX; i++){
            for(int j = minY; j <= maxY; j++){
                int count = 0;
                // Check 4 sub-samples per pixel (2x2 grid)
                if(pnpoly(i + 0.25, j + 0.25, t_pos)) count++;
                if(pnpoly(i + 0.75, j + 0.25, t_pos)) count++;
                if(pnpoly(i + 0.25, j + 0.75, t_pos)) count++;
                if(pnpoly(i + 0.75, j + 0.75, t_pos)) count++;
                
                float coverage = count / 4.0;
                if(coverage > 0){
                    // Blend background (255) and fill color (100) based on coverage
                    float blended = 255 * (1 - coverage) + 100 * coverage;
                    drawPoint(i, j, color(blended));
                }
            }
        }
        
        updatePixels();
        
    };
    
    public Matrix4 localToWorld(){
        // Rotate and scale around the shape's local centroid, then translate to world position.
        // This ensures rotation pivots around the shape's own center instead of a canvas origin.
        if (vertex.length == 0) return Matrix4.Trans(transform.position);

        // compute centroid in local coordinates
        float cx = 0;
        float cy = 0;
        for (int i = 0; i < vertex.length; i++){
            cx += vertex[i].x;
            cy += vertex[i].y;
        }
        cx /= vertex.length;
        cy /= vertex.length;
        Vector3 centroid = new Vector3(cx, cy, 0);

    // Build matrix: T(position) * T(centroid) * Rz * S * T(-centroid)
    return Matrix4.Trans(transform.position)
        .mult(Matrix4.Trans(centroid))
        .mult(Matrix4.RotZ(transform.rotation.z))
        .mult(Matrix4.Scale(transform.scale))
        .mult(Matrix4.Trans(new Vector3(-centroid.x, -centroid.y, -centroid.z)));
    }
    
    public String getShapeName(){
        return "";
    }
    
}

public class Rectangle extends Shape{
    
    public Rectangle(){
        vertex = new Vector3[]{new Vector3(-0.1,-0.1,0),new Vector3(-0.1,0.1,0),new Vector3(0.1,0.1,0),new Vector3(0.1,-0.1,0)};    
    }
    @Override
    public String getShapeName(){
        return "Rectangle";
    }
    
   
}

public class Star extends Shape{
    
    public Star(){
        vertex = new Vector3[]{new Vector3(0.1,0,0),new Vector3(0.0309,0.02244,0),
                               new Vector3(0.0309,0.0951,0),new Vector3(-0.01195,0.03637,0),
                               new Vector3(-0.0809,0.05877,0),new Vector3(-0.03834,0.0002,0),
                               new Vector3(-0.0809,-0.05811,0),new Vector3(-0.012,-0.03599,0),
                               new Vector3(0.0309,-0.0951,0),new Vector3(0.0309,-0.02219,0)};    

    }
    @Override
    public String getShapeName(){
        return "Star";
    }
    
   
}


public class Line extends Shape{
    Vector3 point1;
    Vector3 point2;
    
    public Line(){};
    public Line(Vector3 v1,Vector3 v2){
        point1 = v1;
        point2 = v2;
    }
    
    @Override
    public void drawShape(){
        CGLine(point1.x,point1.y,point2.x,point2.y);
    }
    
   
}



public class Polygon extends Shape{
    ArrayList<Vector3> verties = new ArrayList<Vector3>();
     public Polygon(ArrayList<Vector3> v){
        verties= v;
    }
    
    @Override
    public void drawShape(){
        if(verties.size()<=0) return;
        for(int i=0;i<=verties.size();i++){
              Vector3 p1 = verties.get(i%verties.size());
              Vector3 p2 = verties.get((i+1)%verties.size());
              CGLine(p1.x,p1.y,p2.x,p2.y);
         }
    } 
}
