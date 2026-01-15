#version 330 core

// Input from vertex shader (raylib's default)
in vec2 fragTexCoord;

// Output color
out vec4 finalColor;

// Uniforms set from Eiffel/C
uniform vec2 resolution;
uniform vec3 cameraPos;
uniform float cameraYaw;
uniform float cameraPitch;
uniform float time;

// ============================================================================
// SDF Primitives
// ============================================================================

float sdSphere(vec3 p, vec3 center, float radius) {
    return length(p - center) - radius;
}

float sdBox(vec3 p, vec3 center, vec3 halfSize) {
    vec3 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdPlane(vec3 p, float height) {
    return p.y - height;
}

// Smooth minimum for organic blending
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// ============================================================================
// Scene Definition (matches CPU version)
// ============================================================================

float sceneSDF(vec3 p) {
    // Sphere at origin
    float sphere = sdSphere(p, vec3(0.0, 0.0, 0.0), 1.0);

    // Box to the right
    float box = sdBox(p, vec3(2.0, 0.0, 0.0), vec3(0.4, 0.4, 0.4));

    // Ground plane
    float ground = sdPlane(p, -1.5);

    // Smooth blend sphere and box
    float shapes = smin(sphere, box, 0.3);

    // Union with ground
    return min(shapes, ground);
}

// ============================================================================
// Normal Calculation
// ============================================================================

vec3 calcNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(p + vec3(eps, 0.0, 0.0)) - sceneSDF(p - vec3(eps, 0.0, 0.0)),
        sceneSDF(p + vec3(0.0, eps, 0.0)) - sceneSDF(p - vec3(0.0, eps, 0.0)),
        sceneSDF(p + vec3(0.0, 0.0, eps)) - sceneSDF(p - vec3(0.0, 0.0, eps))
    ));
}

// ============================================================================
// Main Ray Marching
// ============================================================================

void main() {
    // Convert fragment coordinates to normalized device coordinates
    // fragTexCoord is 0-1, we need -1 to 1
    vec2 uv = fragTexCoord * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;  // Aspect ratio correction

    // Camera rotation
    float cy = cos(cameraYaw);
    float sy = sin(cameraYaw);
    float cp = cos(cameraPitch);
    float sp = sin(cameraPitch);

    // Ray direction (looking down -Z)
    vec3 rd = normalize(vec3(uv.x, uv.y, -1.0));

    // Apply pitch rotation (around X axis)
    float ry = rd.y * cp - rd.z * sp;
    float rz = rd.y * sp + rd.z * cp;
    rd.y = ry;
    rd.z = rz;

    // Apply yaw rotation (around Y axis)
    float rx = rd.x * cy + rd.z * sy;
    rz = -rd.x * sy + rd.z * cy;
    rd.x = rx;
    rd.z = rz;

    // Ray marching
    const int MAX_STEPS = 64;
    const float MAX_DIST = 50.0;
    const float SURF_DIST = 0.001;

    float depth = 0.0;
    vec3 p;
    bool hit = false;

    for (int i = 0; i < MAX_STEPS; i++) {
        p = cameraPos + rd * depth;
        float d = sceneSDF(p);

        if (d < SURF_DIST) {
            hit = true;
            break;
        }

        depth += d;
        if (depth > MAX_DIST) break;
    }

    // Shading
    vec3 color;

    if (hit) {
        // Calculate normal
        vec3 normal = calcNormal(p);

        // Light direction (from upper right front)
        vec3 lightDir = normalize(vec3(0.5, 0.8, 0.3));

        // Diffuse lighting
        float diffuse = max(dot(normal, lightDir), 0.0);
        float intensity = 0.15 + diffuse * 0.85;

        // Warm orange base color (220, 120, 80) / 255
        color = vec3(0.863, 0.471, 0.314) * intensity;
    } else {
        // Background gradient (matches CPU version)
        float t = (uv.y + 1.0) * 0.5;
        vec3 bottomColor = vec3(0.098, 0.098, 0.157);  // (25, 25, 40) / 255
        vec3 topColor = vec3(0.157, 0.176, 0.275);     // (40, 45, 70) / 255
        color = mix(bottomColor, topColor, t);
    }

    finalColor = vec4(color, 1.0);
}
