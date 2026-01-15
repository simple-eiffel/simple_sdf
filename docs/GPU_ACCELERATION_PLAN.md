# GPU Acceleration Plan for simple_sdf

## Executive Summary

Move SDF ray marching from CPU to GPU to achieve 60+ FPS at 4K resolution.

**Current State:** CPU ray marching via C code with OpenMP parallelization
- 1920x1080: 40 FPS
- Limited by CPU throughput (~2M pixels × 48 iterations × 7 SDF evaluations = 672M operations/frame)

**Target State:** GPU ray marching via fragment/compute shaders
- 4K (3840x2160): 60+ FPS
- Leverage RTX 5070 Ti's thousands of CUDA cores

---

## Architecture Decision

### Option Analysis

| Approach | Pros | Cons | Effort |
|----------|------|------|--------|
| **A. Raylib Fragment Shader** | Simple, works now, Shadertoy-proven | Scene in GLSL, no dynamic SDF | Low |
| **B. OpenGL Compute Shader** | More flexible, buffer access | Raylib rlgl complexity | Medium |
| **C. New simple_vulkan Library** | Cross-platform (AMD/NVIDIA/Intel), reusable | Complex, new library | High |
| **D. CUDA via simple_cuda** | Fastest on NVIDIA, dynamic scenes | NVIDIA-only | High |

### Recommendation: Phased Approach

**Phase 3a (Immediate):** Raylib fragment shader for GPU ray marching
- Fastest path to 4K @ 60 FPS
- Works with existing raylib integration
- Scene defined in GLSL (like Shadertoy)

**Phase 3b (Future):** simple_vulkan library for advanced GPU compute
- Cross-platform (AMD + NVIDIA + Intel)
- Reusable by voxcraft, simple_sdf, other projects
- Dynamic scene support via SSBO

---

## Phase 3a: Fragment Shader GPU Rendering

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRAGMENT SHADER APPROACH                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Eiffel (SIMPLE_RAYLIB)                                        │
│         │                                                        │
│         ▼                                                        │
│   ┌─────────────────┐                                           │
│   │ Load SDF Shader │  sdf_raymarcher.frag                      │
│   └────────┬────────┘                                           │
│            │                                                     │
│            ▼                                                     │
│   ┌─────────────────┐     ┌─────────────────┐                   │
│   │ Set Uniforms    │────▶│ camera_pos      │                   │
│   │                 │     │ camera_yaw      │                   │
│   │                 │     │ camera_pitch    │                   │
│   │                 │     │ resolution      │                   │
│   │                 │     │ time            │                   │
│   └────────┬────────┘     └─────────────────┘                   │
│            │                                                     │
│            ▼                                                     │
│   ┌─────────────────┐                                           │
│   │ Draw Fullscreen │  Single quad covers entire screen         │
│   │ Quad            │  Fragment shader runs for EVERY pixel     │
│   └────────┬────────┘                                           │
│            │                                                     │
│            ▼                                                     │
│   ┌─────────────────────────────────────────┐                   │
│   │           GPU (RTX 5070 Ti)              │                   │
│   │                                          │                   │
│   │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │                   │
│   │   │Core │ │Core │ │Core │ │Core │ ...  │  Thousands of     │
│   │   │ 1   │ │ 2   │ │ 3   │ │ 4   │      │  cores in parallel│
│   │   └─────┘ └─────┘ └─────┘ └─────┘      │                   │
│   │      │       │       │       │          │                   │
│   │      ▼       ▼       ▼       ▼          │                   │
│   │   ┌─────────────────────────────┐      │                   │
│   │   │    SDF Ray Marching         │      │                   │
│   │   │    (in GLSL shader)         │      │                   │
│   │   └─────────────────────────────┘      │                   │
│   │                │                        │                   │
│   │                ▼                        │                   │
│   │   ┌─────────────────────────────┐      │                   │
│   │   │    Framebuffer (4K)         │      │                   │
│   │   └─────────────────────────────┘      │                   │
│   └─────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation Steps

#### Step 1: Create SDF Fragment Shader (sdf_raymarcher.frag)

```glsl
#version 330 core

// Inputs from vertex shader
in vec2 fragTexCoord;

// Output color
out vec4 finalColor;

// Uniforms from Eiffel
uniform vec2 resolution;
uniform vec3 cameraPos;
uniform float cameraYaw;
uniform float cameraPitch;
uniform float time;

// SDF Primitives
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

// Smooth minimum
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// Scene SDF
float sceneSDF(vec3 p) {
    float sphere = sdSphere(p, vec3(0.0), 1.0);
    float box = sdBox(p, vec3(2.0, 0.0, 0.0), vec3(0.4));
    float ground = sdPlane(p, -1.5);

    float shapes = smin(sphere, box, 0.3);
    return min(shapes, ground);
}

// Normal calculation
vec3 calcNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(p + vec3(eps, 0, 0)) - sceneSDF(p - vec3(eps, 0, 0)),
        sceneSDF(p + vec3(0, eps, 0)) - sceneSDF(p - vec3(0, eps, 0)),
        sceneSDF(p + vec3(0, 0, eps)) - sceneSDF(p - vec3(0, 0, eps))
    ));
}

void main() {
    // Normalized pixel coordinates
    vec2 uv = (fragTexCoord * 2.0 - 1.0);
    uv.x *= resolution.x / resolution.y;

    // Camera rotation matrices
    float cy = cos(cameraYaw), sy = sin(cameraYaw);
    float cp = cos(cameraPitch), sp = sin(cameraPitch);

    // Ray direction
    vec3 rd = normalize(vec3(uv.x, uv.y, -1.0));
    rd.yz = mat2(cp, -sp, sp, cp) * rd.yz;  // Pitch
    rd.xz = mat2(cy, -sy, sy, cy) * rd.xz;  // Yaw

    // Ray march
    float depth = 0.0;
    vec3 p;
    bool hit = false;

    for (int i = 0; i < 64; i++) {
        p = cameraPos + rd * depth;
        float d = sceneSDF(p);
        if (d < 0.001) {
            hit = true;
            break;
        }
        depth += d;
        if (depth > 50.0) break;
    }

    // Shading
    vec3 color;
    if (hit) {
        vec3 normal = calcNormal(p);
        vec3 lightDir = normalize(vec3(0.5, 0.8, 0.3));
        float diffuse = max(dot(normal, lightDir), 0.0);
        float intensity = 0.15 + diffuse * 0.85;
        color = vec3(0.86, 0.47, 0.31) * intensity;  // Warm orange
    } else {
        // Background gradient
        float t = (uv.y + 1.0) * 0.5;
        color = mix(vec3(0.1, 0.1, 0.16), vec3(0.16, 0.18, 0.27), t);
    }

    finalColor = vec4(color, 1.0);
}
```

#### Step 2: Add Shader Support to C Wrapper

Add to `simple_raylib_impl.c`:

```c
/* Shader Management */
static Shader sdf_shader;
static int shader_loaded = 0;

int srl_load_sdf_shader(const char* frag_path) {
    sdf_shader = LoadShader(0, frag_path);  // 0 = default vertex shader
    shader_loaded = IsShaderReady(sdf_shader) ? 1 : 0;
    return shader_loaded;
}

void srl_unload_sdf_shader(void) {
    if (shader_loaded) {
        UnloadShader(sdf_shader);
        shader_loaded = 0;
    }
}

void srl_set_shader_camera(float x, float y, float z, float yaw, float pitch) {
    if (!shader_loaded) return;
    float pos[3] = {x, y, z};
    SetShaderValue(sdf_shader, GetShaderLocation(sdf_shader, "cameraPos"), pos, SHADER_UNIFORM_VEC3);
    SetShaderValue(sdf_shader, GetShaderLocation(sdf_shader, "cameraYaw"), &yaw, SHADER_UNIFORM_FLOAT);
    SetShaderValue(sdf_shader, GetShaderLocation(sdf_shader, "cameraPitch"), &pitch, SHADER_UNIFORM_FLOAT);
}

void srl_set_shader_resolution(float width, float height) {
    if (!shader_loaded) return;
    float res[2] = {width, height};
    SetShaderValue(sdf_shader, GetShaderLocation(sdf_shader, "resolution"), res, SHADER_UNIFORM_VEC2);
}

void srl_render_sdf_gpu(int width, int height) {
    if (!shader_loaded) return;
    BeginShaderMode(sdf_shader);
    DrawRectangle(0, 0, width, height, WHITE);  // Fullscreen quad
    EndShaderMode();
}
```

#### Step 3: Add Eiffel API

New class `RAYLIB_GPU_RENDERER`:

```eiffel
class RAYLIB_GPU_RENDERER

feature -- Initialization
    load_shader (a_frag_path: STRING): BOOLEAN
        -- Load SDF fragment shader.

    dispose
        -- Unload shader resources.

feature -- Rendering
    set_camera (a_pos: SDF_VEC3; a_yaw, a_pitch: REAL_64)
        -- Set camera uniforms.

    set_resolution (a_width, a_height: INTEGER)
        -- Set resolution uniform.

    render (a_width, a_height: INTEGER)
        -- Render SDF scene using GPU shader.
```

#### Step 4: Update Demo for GPU Mode

```eiffel
class SDF_RAYLIB_DEMO

feature -- Render Mode
    use_gpu_rendering: BOOLEAN
        -- True = GPU shader, False = CPU ray marching

feature -- Render Loop
    render_frame
        do
            if use_gpu_rendering then
                gpu_renderer.set_camera (camera_origin, camera_yaw, camera_pitch)
                gpu_renderer.render (Window_width, Window_height)
            else
                render_scene_cpu (buffer)
                buffer.update_texture
                buffer.draw_scaled (0, 0, Window_width, Window_height)
            end
        end
```

### File Structure After Phase 3a

```
D:\prod\simple_sdf\
├── Clib\raylib\
│   ├── simple_raylib_impl.c      # Updated with shader functions
│   └── simple_raylib.h           # Updated declarations
├── shaders\
│   ├── sdf_raymarcher.frag       # GPU SDF ray marching shader
│   └── sdf_raymarcher.vert       # Simple passthrough vertex shader
├── src\visualization\raylib\
│   ├── simple_raylib.e           # Existing facade
│   ├── raylib_buffer.e           # Existing buffer
│   └── raylib_gpu_renderer.e     # NEW: GPU rendering wrapper
└── demo\
    └── sdf_raylib_demo.e         # Updated with GPU mode toggle
```

---

## Phase 3b: simple_vulkan Library (Future)

### Purpose

A dedicated GPU compute library for the simple_* ecosystem, enabling:
- Cross-platform GPU compute (Vulkan: AMD, NVIDIA, Intel)
- Reusable by multiple projects (voxcraft, simple_sdf, etc.)
- Dynamic SDF scenes via SSBO (Shader Storage Buffer Objects)

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     simple_vulkan Library                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Eiffel API Layer                       │   │
│  │                                                           │   │
│  │  SIMPLE_VULKAN (facade)                                  │   │
│  │    ├── create_context: VULKAN_CONTEXT                    │   │
│  │    ├── create_buffer: VULKAN_BUFFER                      │   │
│  │    └── create_compute_pipeline: VULKAN_PIPELINE          │   │
│  │                                                           │   │
│  │  VULKAN_CONTEXT                                          │   │
│  │    ├── device_name: STRING                               │   │
│  │    ├── is_nvidia, is_amd, is_intel: BOOLEAN             │   │
│  │    └── max_workgroup_size: INTEGER                       │   │
│  │                                                           │   │
│  │  VULKAN_BUFFER                                           │   │
│  │    ├── upload (data: MANAGED_POINTER)                    │   │
│  │    ├── download: MANAGED_POINTER                         │   │
│  │    └── size: INTEGER                                     │   │
│  │                                                           │   │
│  │  VULKAN_PIPELINE                                         │   │
│  │    ├── load_shader (spv_path: STRING)                    │   │
│  │    ├── bind_buffer (index: INTEGER; buf: VULKAN_BUFFER) │   │
│  │    ├── set_push_constant (name: STRING; value: ANY)     │   │
│  │    └── dispatch (x, y, z: INTEGER)                       │   │
│  │                                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    C Wrapper Layer                        │   │
│  │                                                           │   │
│  │  simple_vulkan.h / simple_vulkan_impl.c                  │   │
│  │    - svk_create_context()                                │   │
│  │    - svk_create_buffer()                                 │   │
│  │    - svk_upload_buffer()                                 │   │
│  │    - svk_create_pipeline()                               │   │
│  │    - svk_dispatch_compute()                              │   │
│  │    - svk_wait_idle()                                     │   │
│  │                                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Vulkan SDK                             │   │
│  │                                                           │   │
│  │  vulkan-1.lib / vulkan-1.dll                             │   │
│  │                                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### SDF Compute Shader Example

```glsl
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D outputImage;

layout(binding = 1) buffer SceneBuffer {
    vec4 spheres[];  // x, y, z, radius
};

layout(push_constant) uniform PushConstants {
    vec3 cameraPos;
    float cameraYaw;
    float cameraPitch;
    int sphereCount;
} pc;

float sceneSDF(vec3 p) {
    float d = 1e10;
    for (int i = 0; i < pc.sphereCount; i++) {
        d = min(d, length(p - pc.spheres[i].xyz) - pc.spheres[i].w);
    }
    return d;
}

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(outputImage);
    if (pixel.x >= size.x || pixel.y >= size.y) return;

    // ... ray marching code ...

    imageStore(outputImage, pixel, vec4(color, 1.0));
}
```

### Directory Structure

```
D:\prod\simple_vulkan\
├── Clib\
│   ├── simple_vulkan.h           # C wrapper header
│   ├── simple_vulkan_impl.c      # Vulkan implementation
│   └── vulkan\                   # Vulkan SDK headers
├── lib\
│   └── vulkan-1.lib              # Vulkan loader library
├── src\
│   ├── simple_vulkan.e           # Facade
│   ├── vulkan_context.e          # Device/instance wrapper
│   ├── vulkan_buffer.e           # GPU buffer wrapper
│   ├── vulkan_pipeline.e         # Compute pipeline wrapper
│   └── vulkan_shader.e           # Shader module wrapper
├── shaders\
│   ├── sdf_raymarch.comp         # SDF compute shader
│   └── compile_shaders.bat       # SPIR-V compilation script
├── testing\
│   ├── test_app.e
│   └── lib_tests.e
├── simple_vulkan.ecf
└── README.md
```

---

## Implementation Timeline

### Phase 3a: Raylib Fragment Shader (This Session)

| Step | Task | Status |
|------|------|--------|
| 1 | Create sdf_raymarcher.frag shader | Pending |
| 2 | Add shader functions to simple_raylib_impl.c | Pending |
| 3 | Update simple_raylib.h with declarations | Pending |
| 4 | Rebuild simple_raylib_wrapper.lib | Pending |
| 5 | Create RAYLIB_GPU_RENDERER Eiffel class | Pending |
| 6 | Update demo with GPU mode | Pending |
| 7 | Test at 1920x1080 | Pending |
| 8 | Test at 4K (3840x2160) | Pending |

### Phase 3b: simple_vulkan Library (Future Session)

| Step | Task | Effort |
|------|------|--------|
| 1 | Download Vulkan SDK | 15 min |
| 2 | Create simple_vulkan project structure | 30 min |
| 3 | Implement C wrapper (context, buffer, pipeline) | 4-6 hours |
| 4 | Create Eiffel bindings | 2-3 hours |
| 5 | Write SDF compute shader | 1-2 hours |
| 6 | Integration with simple_sdf | 2-3 hours |
| 7 | Testing and optimization | 2-3 hours |

---

## Expected Performance

| Resolution | CPU (Current) | GPU Fragment (3a) | GPU Compute (3b) |
|------------|---------------|-------------------|------------------|
| 1280x960 | 59 FPS | 60 FPS | 60 FPS |
| 1920x1080 | 40 FPS | 60 FPS | 60 FPS |
| 2560x1440 | ~20 FPS | 60 FPS | 60 FPS |
| 3840x2160 | ~10 FPS | 60 FPS | 60 FPS |

---

## Summary

**Immediate (Phase 3a):** Fragment shader via raylib
- Simple implementation
- Works today
- 60 FPS at 4K for static scenes

**Future (Phase 3b):** simple_vulkan library
- Cross-platform GPU compute
- Dynamic scenes via SSBO
- Reusable across ecosystem (voxcraft, simple_sdf, etc.)
- Production-quality GPU infrastructure
