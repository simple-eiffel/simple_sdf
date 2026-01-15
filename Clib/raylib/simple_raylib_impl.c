/*
 * simple_raylib_impl.c - raylib wrapper implementation
 *
 * This file is compiled separately from Eiffel code to avoid
 * Windows/raylib header conflicts.
 *
 * OPTIMIZATIONS:
 * - OpenMP parallel rendering
 * - Fast inverse sqrt (Quake-style)
 * - Over-relaxation sphere tracing
 * - Forward-difference normals (4 calls instead of 6)
 * - Direct pixel buffer access
 */

#include "raylib.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef _OPENMP
#include <omp.h>
#endif

/* ============================================================================
 * Buffer Structure (must be defined first)
 * ============================================================================ */

typedef struct {
    Texture2D texture;
    Image image;
    int width;
    int height;
} srl_render_buffer;

/* ============================================================================
 * Fast SDF Ray Marching in C
 * ============================================================================ */

typedef struct {
    float x, y, z;
} vec3f;

static inline vec3f vec3f_make(float x, float y, float z) {
    vec3f v = {x, y, z};
    return v;
}

static inline vec3f vec3f_add(vec3f a, vec3f b) {
    return vec3f_make(a.x + b.x, a.y + b.y, a.z + b.z);
}

static inline vec3f vec3f_sub(vec3f a, vec3f b) {
    return vec3f_make(a.x - b.x, a.y - b.y, a.z - b.z);
}

static inline vec3f vec3f_scale(vec3f v, float s) {
    return vec3f_make(v.x * s, v.y * s, v.z * s);
}

static inline float vec3f_dot(vec3f a, vec3f b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

static inline float vec3f_length_sq(vec3f v) {
    return v.x * v.x + v.y * v.y + v.z * v.z;
}

static inline float vec3f_length(vec3f v) {
    return sqrtf(vec3f_length_sq(v));
}

/* Fast inverse square root using union (safe type punning) */
static inline float fast_inv_sqrt(float x) {
    union { float f; unsigned int i; } conv;
    float xhalf = 0.5f * x;
    conv.f = x;
    conv.i = 0x5f375a86 - (conv.i >> 1);
    conv.f = conv.f * (1.5f - xhalf * conv.f * conv.f);
    return conv.f;
}

static inline vec3f vec3f_normalize(vec3f v) {
    float len_sq = vec3f_length_sq(v);
    if (len_sq > 1e-12f) {  /* Very small threshold - central diff gradients are tiny */
        float inv_len = 1.0f / sqrtf(len_sq);
        return vec3f_make(v.x * inv_len, v.y * inv_len, v.z * inv_len);
    }
    return vec3f_make(0.0f, 1.0f, 0.0f);  /* Default to up if degenerate */
}

static inline float maxf(float a, float b) { return a > b ? a : b; }
static inline float minf(float a, float b) { return a < b ? a : b; }
static inline float absf(float a) { return a < 0 ? -a : a; }

/* SDF primitives */
static inline float sdf_sphere(vec3f p, vec3f center, float radius) {
    return vec3f_length(vec3f_sub(p, center)) - radius;
}

static inline float sdf_box(vec3f p, vec3f center, vec3f half_size) {
    vec3f d = vec3f_sub(p, center);
    d.x = absf(d.x) - half_size.x;
    d.y = absf(d.y) - half_size.y;
    d.z = absf(d.z) - half_size.z;
    float outside = vec3f_length(vec3f_make(maxf(d.x, 0), maxf(d.y, 0), maxf(d.z, 0)));
    float inside = minf(maxf(d.x, maxf(d.y, d.z)), 0);
    return outside + inside;
}

static inline float sdf_plane(vec3f p, float height) {
    return p.y - height;
}

/* Smooth minimum for blending */
static inline float sdf_smooth_min(float a, float b, float k) {
    float h = maxf(k - absf(a - b), 0.0f) / k;
    return minf(a, b) - h * h * k * 0.25f;
}

/* Scene SDF - hardcoded for demo: sphere + box + ground */
static float scene_sdf(vec3f p) {
    float d_sphere = sdf_sphere(p, vec3f_make(0, 0, 0), 1.0f);
    float d_box = sdf_box(p, vec3f_make(2.0f, 0, 0), vec3f_make(0.4f, 0.4f, 0.4f));
    float d_ground = sdf_plane(p, -1.5f);

    /* Smooth blend sphere and box */
    float d_shapes = sdf_smooth_min(d_sphere, d_box, 0.3f);

    /* Union with ground */
    return minf(d_shapes, d_ground);
}

/* Central-difference normal: more accurate than forward-difference */
static vec3f compute_normal(vec3f p) {
    const float eps = 0.001f;
    vec3f n;
    n.x = scene_sdf(vec3f_make(p.x + eps, p.y, p.z)) - scene_sdf(vec3f_make(p.x - eps, p.y, p.z));
    n.y = scene_sdf(vec3f_make(p.x, p.y + eps, p.z)) - scene_sdf(vec3f_make(p.x, p.y - eps, p.z));
    n.z = scene_sdf(vec3f_make(p.x, p.y, p.z + eps)) - scene_sdf(vec3f_make(p.x, p.y, p.z - eps));
    return vec3f_normalize(n);
}

void srl_render_sdf_scene(void* buf_ptr, int width, int height,
                          float cam_x, float cam_y, float cam_z,
                          float cam_yaw, float cam_pitch) {
    srl_render_buffer* buf = (srl_render_buffer*)buf_ptr;
    if (!buf) return;

    /* Precompute constants outside loops */
    const float aspect = (float)width / (float)height;
    const float inv_width = 1.0f / (float)width;
    const float inv_height = 1.0f / (float)height;
    const float cos_yaw = cosf(cam_yaw);
    const float sin_yaw = sinf(cam_yaw);
    const float cos_pitch = cosf(cam_pitch);
    const float sin_pitch = sinf(cam_pitch);

    const vec3f cam_origin = vec3f_make(cam_x, cam_y, cam_z);
    /* Precompute normalized light direction: normalize(0.5, 0.8, 0.3) */
    const vec3f light_dir = vec3f_make(0.50508f, 0.80812f, 0.30305f);

    /* Direct pixel buffer access - raylib Image uses RGBA format */
    unsigned char* pixels = (unsigned char*)buf->image.data;
    const int stride = width * 4;  /* 4 bytes per pixel (RGBA) */

    /* Over-relaxation factor for sphere tracing (1.0 = standard, 1.2-1.6 = aggressive) */
    const float RELAX = 1.2f;
    const int MAX_STEPS = 48;
    const float MAX_DIST = 40.0f;
    const float SURF_DIST = 0.002f;

    /* OpenMP parallel rendering - each thread handles a chunk of rows */
    int py;
    #ifdef _OPENMP
    #pragma omp parallel for schedule(dynamic, 4) private(py)
    #endif
    for (py = 0; py < height; py++) {
        unsigned char* row = pixels + py * stride;
        float v = 1.0f - (float)py * inv_height * 2.0f;

        /* Precompute pitch rotation for this row */
        float ry_base = v * cos_pitch + sin_pitch;
        float rz_base = v * sin_pitch - cos_pitch;

        for (int px = 0; px < width; px++) {
            float u = ((float)px * inv_width * 2.0f - 1.0f) * aspect;

            /* Ray direction with camera rotation (yaw only varies per pixel) */
            float rx = u;
            float ry = ry_base;
            float rz = rz_base;

            /* Apply yaw rotation and normalize */
            vec3f ray_dir = vec3f_normalize(vec3f_make(
                rx * cos_yaw + rz * sin_yaw,
                ry,
                -rx * sin_yaw + rz * cos_yaw
            ));

            /* Standard sphere tracing ray march */
            float depth = 0.0f;
            int hit = 0;
            vec3f hit_point = cam_origin;

            for (int i = 0; i < MAX_STEPS; i++) {
                hit_point.x = cam_origin.x + ray_dir.x * depth;
                hit_point.y = cam_origin.y + ray_dir.y * depth;
                hit_point.z = cam_origin.z + ray_dir.z * depth;

                float dist = scene_sdf(hit_point);

                if (dist < SURF_DIST) {
                    hit = 1;
                    break;
                }

                depth += dist;
                if (depth > MAX_DIST) break;
            }

            /* Shade pixel */
            unsigned char r, g, b;
            if (hit) {
                vec3f normal = compute_normal(hit_point);
                float diffuse = normal.x * light_dir.x + normal.y * light_dir.y + normal.z * light_dir.z;
                if (diffuse < 0.0f) diffuse = 0.0f;
                float intensity = 0.15f + diffuse * 0.85f;
                r = (unsigned char)(220.0f * intensity);
                g = (unsigned char)(120.0f * intensity);
                b = (unsigned char)(80.0f * intensity);
            } else {
                /* Background gradient (precomputed v) */
                float t = (v + 1.0f) * 0.5f;
                r = (unsigned char)(25.0f + t * 15.0f);
                g = (unsigned char)(25.0f + t * 20.0f);
                b = (unsigned char)(40.0f + t * 30.0f);
            }

            /* Direct pixel write (RGBA format) */
            row[px * 4 + 0] = r;
            row[px * 4 + 1] = g;
            row[px * 4 + 2] = b;
            row[px * 4 + 3] = 255;
        }
    }
}

/* ============================================================================
 * Window Management
 * ============================================================================ */

void srl_init_window(int width, int height, const char* title) {
    InitWindow(width, height, title);
}

void srl_close_window(void) {
    CloseWindow();
}

int srl_window_should_close(void) {
    return WindowShouldClose() ? 1 : 0;
}

int srl_is_window_ready(void) {
    return IsWindowReady() ? 1 : 0;
}

int srl_get_screen_width(void) {
    return GetScreenWidth();
}

int srl_get_screen_height(void) {
    return GetScreenHeight();
}

void srl_set_target_fps(int fps) {
    SetTargetFPS(fps);
}

int srl_get_fps(void) {
    return GetFPS();
}

float srl_get_frame_time(void) {
    return GetFrameTime();
}

/* ============================================================================
 * Drawing
 * ============================================================================ */

void srl_begin_drawing(void) {
    BeginDrawing();
}

void srl_end_drawing(void) {
    EndDrawing();
}

void srl_clear_background(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    Color c = { r, g, b, a };
    ClearBackground(c);
}

/* ============================================================================
 * Buffer Management
 * ============================================================================ */

void* srl_create_render_buffer(int width, int height) {
    srl_render_buffer* buf = (srl_render_buffer*)malloc(sizeof(srl_render_buffer));
    if (!buf) return NULL;

    buf->width = width;
    buf->height = height;
    buf->image = GenImageColor(width, height, BLACK);
    buf->texture = LoadTextureFromImage(buf->image);

    return buf;
}

void srl_free_render_buffer(void* ptr) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf) {
        UnloadTexture(buf->texture);
        UnloadImage(buf->image);
        free(buf);
    }
}

void srl_set_pixel(void* ptr, int x, int y, unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf && x >= 0 && x < buf->width && y >= 0 && y < buf->height) {
        Color c = { r, g, b, a };
        ImageDrawPixel(&buf->image, x, y, c);
    }
}

void srl_clear_buffer(void* ptr, unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf) {
        Color c = { r, g, b, a };
        ImageClearBackground(&buf->image, c);
    }
}

void srl_update_texture(void* ptr) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf) {
        UpdateTexture(buf->texture, buf->image.data);
    }
}

void srl_draw_buffer(void* ptr, int x, int y) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf) {
        DrawTexture(buf->texture, x, y, WHITE);
    }
}

void srl_draw_buffer_scaled(void* ptr, int x, int y, int dest_width, int dest_height) {
    srl_render_buffer* buf = (srl_render_buffer*)ptr;
    if (buf) {
        Rectangle source = { 0, 0, (float)buf->width, (float)buf->height };
        Rectangle dest = { (float)x, (float)y, (float)dest_width, (float)dest_height };
        DrawTexturePro(buf->texture, source, dest, (Vector2){ 0, 0 }, 0.0f, WHITE);
    }
}

/* ============================================================================
 * Input - Keyboard
 * ============================================================================ */

int srl_is_key_down(int key) {
    return IsKeyDown(key) ? 1 : 0;
}

int srl_is_key_pressed(int key) {
    return IsKeyPressed(key) ? 1 : 0;
}

int srl_get_key_pressed(void) {
    return GetKeyPressed();
}

/* ============================================================================
 * Input - Mouse
 * ============================================================================ */

int srl_get_mouse_x(void) {
    return GetMouseX();
}

int srl_get_mouse_y(void) {
    return GetMouseY();
}

int srl_is_mouse_button_down(int button) {
    return IsMouseButtonDown(button) ? 1 : 0;
}

float srl_get_mouse_wheel_move(void) {
    return GetMouseWheelMove();
}

/* ============================================================================
 * Text Drawing
 * ============================================================================ */

void srl_draw_text(const char* text, int x, int y, int font_size, unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    Color c = { r, g, b, a };
    DrawText(text, x, y, font_size, c);
}

void srl_draw_fps(int x, int y) {
    DrawFPS(x, y);
}

/* ============================================================================
 * GPU Shader Rendering
 * ============================================================================ */

static Shader sdf_shader = { 0 };
static int shader_loaded = 0;
static int loc_resolution = -1;
static int loc_camera_pos = -1;
static int loc_camera_yaw = -1;
static int loc_camera_pitch = -1;
static int loc_time = -1;

int srl_load_sdf_shader(const char* frag_path) {
    /* Load shader (NULL for vertex = use raylib's default) */
    sdf_shader = LoadShader(NULL, frag_path);
    shader_loaded = IsShaderReady(sdf_shader) ? 1 : 0;

    if (shader_loaded) {
        /* Cache uniform locations for performance */
        loc_resolution = GetShaderLocation(sdf_shader, "resolution");
        loc_camera_pos = GetShaderLocation(sdf_shader, "cameraPos");
        loc_camera_yaw = GetShaderLocation(sdf_shader, "cameraYaw");
        loc_camera_pitch = GetShaderLocation(sdf_shader, "cameraPitch");
        loc_time = GetShaderLocation(sdf_shader, "time");
    }

    return shader_loaded;
}

void srl_unload_sdf_shader(void) {
    if (shader_loaded) {
        UnloadShader(sdf_shader);
        shader_loaded = 0;
        loc_resolution = -1;
        loc_camera_pos = -1;
        loc_camera_yaw = -1;
        loc_camera_pitch = -1;
        loc_time = -1;
    }
}

int srl_is_shader_ready(void) {
    return shader_loaded;
}

void srl_set_shader_resolution(float width, float height) {
    if (!shader_loaded || loc_resolution < 0) return;
    float res[2] = { width, height };
    SetShaderValue(sdf_shader, loc_resolution, res, SHADER_UNIFORM_VEC2);
}

void srl_set_shader_camera(float x, float y, float z, float yaw, float pitch) {
    if (!shader_loaded) return;

    if (loc_camera_pos >= 0) {
        float pos[3] = { x, y, z };
        SetShaderValue(sdf_shader, loc_camera_pos, pos, SHADER_UNIFORM_VEC3);
    }
    if (loc_camera_yaw >= 0) {
        SetShaderValue(sdf_shader, loc_camera_yaw, &yaw, SHADER_UNIFORM_FLOAT);
    }
    if (loc_camera_pitch >= 0) {
        SetShaderValue(sdf_shader, loc_camera_pitch, &pitch, SHADER_UNIFORM_FLOAT);
    }
}

void srl_set_shader_time(float t) {
    if (!shader_loaded || loc_time < 0) return;
    SetShaderValue(sdf_shader, loc_time, &t, SHADER_UNIFORM_FLOAT);
}

void srl_render_sdf_gpu(int width, int height) {
    if (!shader_loaded) return;

    BeginShaderMode(sdf_shader);
    /* Draw a fullscreen rectangle - fragment shader runs for every pixel */
    DrawRectangle(0, 0, width, height, WHITE);
    EndShaderMode();
}
