/*
 * simple_raylib.h - Eiffel wrapper declarations for raylib
 *
 * This header only declares functions implemented in simple_raylib_impl.c.
 * It does NOT include raylib.h to avoid Windows header conflicts.
 */

#ifndef SIMPLE_RAYLIB_H
#define SIMPLE_RAYLIB_H

#ifdef __cplusplus
extern "C" {
#endif

/* Window Management */
void srl_init_window(int width, int height, const char* title);
void srl_close_window(void);
int srl_window_should_close(void);
int srl_is_window_ready(void);
int srl_get_screen_width(void);
int srl_get_screen_height(void);
void srl_set_target_fps(int fps);
int srl_get_fps(void);
float srl_get_frame_time(void);

/* Drawing */
void srl_begin_drawing(void);
void srl_end_drawing(void);
void srl_clear_background(unsigned char r, unsigned char g, unsigned char b, unsigned char a);

/* Buffer Management */
void* srl_create_render_buffer(int width, int height);
void srl_free_render_buffer(void* buf);
void srl_set_pixel(void* buf, int x, int y, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void srl_clear_buffer(void* buf, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void srl_update_texture(void* buf);
void srl_draw_buffer(void* buf, int x, int y);
void srl_draw_buffer_scaled(void* buf, int x, int y, int dest_width, int dest_height);

/* Fast SDF Ray Marching (entire render loop in C for performance) */
void srl_render_sdf_scene(void* buf, int width, int height,
                          float cam_x, float cam_y, float cam_z,
                          float cam_yaw, float cam_pitch);

/* Input - Keyboard */
int srl_is_key_down(int key);
int srl_is_key_pressed(int key);
int srl_get_key_pressed(void);

/* Input - Mouse */
int srl_get_mouse_x(void);
int srl_get_mouse_y(void);
int srl_is_mouse_button_down(int button);
float srl_get_mouse_wheel_move(void);

/* Text Drawing */
void srl_draw_text(const char* text, int x, int y, int font_size, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void srl_draw_fps(int x, int y);

/* GPU Shader Rendering */
int srl_load_sdf_shader(const char* frag_path);
void srl_unload_sdf_shader(void);
int srl_is_shader_ready(void);
void srl_set_shader_resolution(float width, float height);
void srl_set_shader_camera(float x, float y, float z, float yaw, float pitch);
void srl_set_shader_time(float t);
void srl_render_sdf_gpu(int width, int height);

#ifdef __cplusplus
}
#endif

#endif /* SIMPLE_RAYLIB_H */
