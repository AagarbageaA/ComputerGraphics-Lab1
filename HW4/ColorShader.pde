public class PhongVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));
        }

        Vector4[][] result = { gl_Position, w_position, w_normal };

        return result;
    }
}

public class PhongFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 albedo = (Vector3) varying[3];
        Vector3 kdksm = (Vector3) varying[4];
        Camera cam = main_camera;

        // TODO HW4
        // In this section, we have passed in all the variables you need.
        // Please use these variables to calculate the result of Phong shading
        // for that point and return it to GameObject for rendering

        // Extract material properties
        float Kd = kdksm.x;  // Diffuse coefficient
        float Ks = kdksm.y;  // Specular coefficient
        float m = kdksm.z;   // Shininess exponent
        
        // Normalize the normal vector
        Vector3 N = w_normal.unit_vector();
        
        // View direction (from surface to camera)
        Vector3 V = cam.transform.position.sub(w_position).unit_vector();
        
        // MULTIPLE LIGHT SOURCES SUPPORT
        // Accumulate lighting from all lights in the scene
        Vector3 totalDiffuse = new Vector3(0, 0, 0);
        Vector3 totalSpecular = new Vector3(0, 0, 0);
        Vector3 ambient = new Vector3(0, 0, 0);
        
        for (Light light : lights) {
            // Light direction (from surface to light)
            Vector3 L = light.transform.position.sub(w_position).unit_vector();
            
            // Reflection direction
            Vector3 R = N.mult(2.0 * Vector3.dot(N, L)).sub(L).unit_vector();
            
            // Ambient (only add once from first light to avoid over-brightening)
            if (lights.indexOf(light) == 0) {
                ambient = albedo.product(light.light_color).mult(0.3);
            }
            
            // Diffuse component
            float diffuse_factor = max(0, Vector3.dot(N, L));
            Vector3 diffuse = albedo.product(light.light_color).mult(Kd * diffuse_factor * light.intensity);
            
            // Specular component
            float specular_factor = pow(max(0, Vector3.dot(R, V)), m);
            Vector3 specular = light.light_color.mult(Ks * specular_factor * light.intensity);
            
            totalDiffuse = totalDiffuse.add(diffuse);
            totalSpecular = totalSpecular.add(specular);
        }
        
        // Combine all components
        Vector3 finalColor = ambient.add(totalDiffuse).add(totalSpecular);
        
        // Clamp to [0, 1]
        float r = min(1.0, max(0.0, finalColor.x));
        float g = min(1.0, max(0.0, finalColor.y));
        float b = min(1.0, max(0.0, finalColor.z));

        return new Vector4(r, g, b, 1.0);
    }
}

public class FlatVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector3 albedo = (Vector3) uniform[2];
        Vector3 kdksm = (Vector3) uniform[3];
        Camera cam = main_camera;
        
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] flat_color = new Vector4[3];

        // TODO HW4
        // Here you have to complete Flat shading.
        // Calculate face normal from the triangle edges
        Vector3 A = M.mult(aVertexPosition[0].getVector4(1.0)).xyz();
        Vector3 B = M.mult(aVertexPosition[1].getVector4(1.0)).xyz();
        Vector3 C = M.mult(aVertexPosition[2].getVector4(1.0)).xyz();
        
        // Face normal = normalize(cross(B-A, C-A))
        Vector3 face_normal = Vector3.cross(B.sub(A), C.sub(A)).unit_vector();
        
        // Face center for lighting calculation
        Vector3 face_center = A.add(B).add(C).mult(1.0/3.0);
        
        // Calculate lighting ONCE for the entire triangle
        float Kd = kdksm.x;
        float Ks = kdksm.y;
        float m = kdksm.z;
        
        Vector3 N = face_normal;
        Vector3 V = cam.transform.position.sub(face_center).unit_vector();
        
        // MULTIPLE LIGHT SOURCES SUPPORT
        Vector3 totalDiffuse = new Vector3(0, 0, 0);
        Vector3 totalSpecular = new Vector3(0, 0, 0);
        Vector3 ambient = new Vector3(0, 0, 0);
        
        for (Light light : lights) {
            Vector3 L = light.transform.position.sub(face_center).unit_vector();
            Vector3 R = N.mult(2.0 * Vector3.dot(N, L)).sub(L).unit_vector();
            
            if (lights.indexOf(light) == 0) {
                ambient = albedo.product(light.light_color).mult(0.3);
            }
            
            float diffuse_factor = max(0, Vector3.dot(N, L));
            Vector3 diffuse = albedo.product(light.light_color).mult(Kd * diffuse_factor * light.intensity);
            float specular_factor = pow(max(0, Vector3.dot(R, V)), m);
            Vector3 specular = light.light_color.mult(Ks * specular_factor * light.intensity);
            
            totalDiffuse = totalDiffuse.add(diffuse);
            totalSpecular = totalSpecular.add(specular);
        }
        
        Vector3 finalColor = ambient.add(totalDiffuse).add(totalSpecular);
        
        float r = min(1.0, max(0.0, finalColor.x));
        float g = min(1.0, max(0.0, finalColor.y));
        float b = min(1.0, max(0.0, finalColor.z));
        Vector4 triangleColor = new Vector4(r, g, b, 1.0);
        
        // Transform vertices to clip space and assign SAME color to all three vertices
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            flat_color[i] = triangleColor;  // Same color for all vertices
        }

        Vector4[][] result = { gl_Position, flat_color };
        return result;
    }
}

public class FlatFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector4 flat_color = (Vector4) varying[1];
        
        // TODO HW4
        // Flat shading: just return the pre-calculated color
        // No per-pixel lighting calculation!
        // The color was already calculated once in the vertex shader
        // All three vertices have the same color, so after interpolation,
        // all fragments in this triangle will have the same color
        
        return flat_color;
    }
}

public class GouraudVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector3 albedo = (Vector3) uniform[2];
        Vector3 kdksm = (Vector3) uniform[3];
        Camera cam = main_camera;

        Vector4[] gl_Position = new Vector4[3];
        Vector4[] vertex_colors = new Vector4[3];

        // TODO HW4
        // Here you have to complete Gouraud shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note: Here the first variable must return the position of the vertex.
        // Subsequent variables will be interpolated and passed to the fragment shader.
        // The return value must be a Vector4.

        // Calculate lighting for each vertex
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            
            // World position and normal
            Vector3 w_position = M.mult(aVertexPosition[i].getVector4(1.0)).xyz();
            Vector3 w_normal = M.mult(aVertexNormal[i].getVector4(0.0)).xyz().unit_vector();
            
            // Extract material properties
            float Kd = kdksm.x;
            float Ks = kdksm.y;
            float m = kdksm.z;
            
            // View direction
            Vector3 V = cam.transform.position.sub(w_position).unit_vector();
            
            // MULTIPLE LIGHT SOURCES SUPPORT
            Vector3 totalDiffuse = new Vector3(0, 0, 0);
            Vector3 totalSpecular = new Vector3(0, 0, 0);
            Vector3 ambient = new Vector3(0, 0, 0);
            
            for (Light light : lights) {
                // Light direction
                Vector3 L = light.transform.position.sub(w_position).unit_vector();
                
                // Reflection direction
                Vector3 R = w_normal.mult(2.0 * Vector3.dot(w_normal, L)).sub(L).unit_vector();
                
                // Ambient (only from first light)
                if (lights.indexOf(light) == 0) {
                    ambient = albedo.product(light.light_color).mult(0.3);
                }
                
                // Diffuse
                float diffuse_factor = max(0, Vector3.dot(w_normal, L));
                Vector3 diffuse = albedo.product(light.light_color).mult(Kd * diffuse_factor * light.intensity);
                
                // Specular
                float specular_factor = pow(max(0, Vector3.dot(R, V)), m);
                Vector3 specular = light.light_color.mult(Ks * specular_factor * light.intensity);
                
                totalDiffuse = totalDiffuse.add(diffuse);
                totalSpecular = totalSpecular.add(specular);
            }
            
            // Combine
            Vector3 vertexColor = ambient.add(totalDiffuse).add(totalSpecular);
            
            // Store as Vector4
            vertex_colors[i] = new Vector4(vertexColor.x, vertexColor.y, vertexColor.z, 1.0);
        }

        Vector4[][] result = { gl_Position, vertex_colors };

        return result;
    }
}

public class GouraudFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 vertex_color = (Vector3) varying[1];

        // TODO HW4
        // Here you have to complete Gouraud shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note : In the fragment shader, the first 'varying' variable must be its
        // screen position.
        // Subsequent variables will be received in order from the vertex shader.
        // Additional variables needed will be passed by the material later.

        // In Gouraud shading, colors are already calculated and interpolated from vertices
        // Just clamp and return
        float r = min(1.0, max(0.0, vertex_color.x));
        float g = min(1.0, max(0.0, vertex_color.y));
        float b = min(1.0, max(0.0, vertex_color.z));

        return new Vector4(r, g, b, 1.0);
    }
}

// BONUS: Texture Shader Implementation
public class TextureVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Vector3[] aVertexUV = (Vector3[]) attribute[2];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];
        Vector4[] uvs = new Vector4[3];

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));
            uvs[i] = aVertexUV[i].getVector4(0.0);
        }

        Vector4[][] result = { gl_Position, w_position, w_normal, uvs };

        return result;
    }
}

public class TextureFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 uv = (Vector3) varying[3];
        PImage texture = (PImage) varying[4];
        Vector3 kdksm = (Vector3) varying[5];
        Camera cam = main_camera;

        // Sample texture
        int texX = (int)(uv.x * texture.width) % texture.width;
        int texY = (int)(uv.y * texture.height) % texture.height;
        if (texX < 0) texX += texture.width;
        if (texY < 0) texY += texture.height;
        
        color texColor = texture.pixels[texY * texture.width + texX];
        Vector3 albedo = new Vector3(
            red(texColor) / 255.0,
            green(texColor) / 255.0,
            blue(texColor) / 255.0
        );
        
        // Extract material properties
        float Kd = kdksm.x;
        float Ks = kdksm.y;
        float m = kdksm.z;
        
        // Normalize the normal vector
        Vector3 N = w_normal.unit_vector();
        
        // View direction
        Vector3 V = cam.transform.position.sub(w_position).unit_vector();
        
        // MULTIPLE LIGHT SOURCES SUPPORT
        Vector3 totalDiffuse = new Vector3(0, 0, 0);
        Vector3 totalSpecular = new Vector3(0, 0, 0);
        Vector3 ambient = new Vector3(0, 0, 0);
        
        for (Light light : lights) {
            // Light direction
            Vector3 L = light.transform.position.sub(w_position).unit_vector();
            
            // Reflection direction
            Vector3 R = N.mult(2.0 * Vector3.dot(N, L)).sub(L).unit_vector();
            
            // Ambient (only from first light)
            if (lights.indexOf(light) == 0) {
                ambient = albedo.product(light.light_color).mult(0.3);
            }
            
            // Diffuse component
            float diffuse_factor = max(0, Vector3.dot(N, L));
            Vector3 diffuse = albedo.product(light.light_color).mult(Kd * diffuse_factor * light.intensity);
            
            // Specular component
            float specular_factor = pow(max(0, Vector3.dot(R, V)), m);
            Vector3 specular = light.light_color.mult(Ks * specular_factor * light.intensity);
            
            totalDiffuse = totalDiffuse.add(diffuse);
            totalSpecular = totalSpecular.add(specular);
        }
        
        // Combine all components
        Vector3 finalColor = ambient.add(totalDiffuse).add(totalSpecular);
        
        // Clamp to [0, 1]
        float r = min(1.0, max(0.0, finalColor.x));
        float g = min(1.0, max(0.0, finalColor.y));
        float b = min(1.0, max(0.0, finalColor.z));

        return new Vector4(r, g, b, 1.0);
    }
}
