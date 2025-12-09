public class Shader {
    VertexShader vertex;
    FragmentShader fragment;

    public Shader(VertexShader v, FragmentShader f) {
        vertex = v;
        fragment = f;
    }
}

public abstract class VertexShader {
    abstract Vector4[][] main(Object[] attribute, Object[] uniform);
}

public abstract class FragmentShader {
    abstract Vector4 main(Object[] varying);
}

public class DepthVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];
        Vector4[] gl_Position = new Vector4[3];
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
        }

        Vector4[][] result = { gl_Position };

        return result;
    }
}

public class DepthFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];

        // Map depth from NDC space to visible grayscale range
        // NDC z is in [-1, 1] where -1 is near, 1 is far
        // Map to [0, 1] where 0 is far (black), 1 is near (white)
        float depth = (position.z + 1.0) / 2.0;  // Convert [-1, 1] to [0, 1]
        depth = 1.0 - depth;  // Invert: near = white, far = black
        
        // Enhance contrast for better visibility
        depth = pow(depth, 0.5);  // Apply gamma correction to spread values
        
        // Clamp to [0, 1]
        depth = max(0.0, min(1.0, depth));
        
        return new Vector4(depth, depth, depth, 1.0);
    }
}
