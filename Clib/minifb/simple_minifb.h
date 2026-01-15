/*
 * simple_minifb.h - Eiffel wrapper for MiniFB
 *
 * This header provides static inline functions that wrap MiniFB
 * for use with Eiffel's inline C externals.
 */

#ifndef SIMPLE_MINIFB_H
#define SIMPLE_MINIFB_H

#include "MiniFB.h"
#include <stdlib.h>
#include <string.h>

/* ============================================================================
 * Buffer Management
 * ============================================================================ */

typedef struct {
    uint32_t* data;
    int width;
    int height;
    int stride;
} smfb_buffer;

static smfb_buffer* smfb_create_buffer(int width, int height) {
    smfb_buffer* buf;
    if (width <= 0 || height <= 0) return NULL;

    buf = (smfb_buffer*)malloc(sizeof(smfb_buffer));
    if (!buf) return NULL;

    buf->data = (uint32_t*)malloc(width * height * sizeof(uint32_t));
    if (!buf->data) {
        free(buf);
        return NULL;
    }

    buf->width = width;
    buf->height = height;
    buf->stride = width * sizeof(uint32_t);
    memset(buf->data, 0, width * height * sizeof(uint32_t));
    return buf;
}

static void smfb_free_buffer(smfb_buffer* buf) {
    if (buf) {
        if (buf->data) free(buf->data);
        free(buf);
    }
}

static int smfb_buffer_width(smfb_buffer* buf) {
    return buf ? buf->width : 0;
}

static int smfb_buffer_height(smfb_buffer* buf) {
    return buf ? buf->height : 0;
}

static uint32_t* smfb_buffer_data(smfb_buffer* buf) {
    return buf ? buf->data : NULL;
}

/* ============================================================================
 * Pixel Operations
 * ============================================================================ */

static void smfb_set_pixel(smfb_buffer* buf, int x, int y, uint32_t color) {
    if (buf && buf->data && x >= 0 && x < buf->width && y >= 0 && y < buf->height) {
        buf->data[y * buf->width + x] = color;
    }
}

static uint32_t smfb_get_pixel(smfb_buffer* buf, int x, int y) {
    if (buf && buf->data && x >= 0 && x < buf->width && y >= 0 && y < buf->height) {
        return buf->data[y * buf->width + x];
    }
    return 0;
}

static void smfb_clear(smfb_buffer* buf, uint32_t color) {
    if (buf && buf->data) {
        int count = buf->width * buf->height;
        uint32_t* p = buf->data;
        while (count--) {
            *p++ = color;
        }
    }
}

static void smfb_fill_rect(smfb_buffer* buf, int x, int y, int w, int h, uint32_t color) {
    int x1, y1, x2, y2, px, py;
    if (!buf || !buf->data) return;

    x1 = (x < 0) ? 0 : x;
    y1 = (y < 0) ? 0 : y;
    x2 = (x + w > buf->width) ? buf->width : (x + w);
    y2 = (y + h > buf->height) ? buf->height : (y + h);

    for (py = y1; py < y2; py++) {
        for (px = x1; px < x2; px++) {
            buf->data[py * buf->width + px] = color;
        }
    }
}

/* ============================================================================
 * Color Helpers
 * ============================================================================ */

static uint32_t smfb_rgb(uint8_t r, uint8_t g, uint8_t b) {
    return MFB_RGB(r, g, b);
}

static uint32_t smfb_argb(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
    return MFB_ARGB(a, r, g, b);
}

static uint32_t smfb_hex_to_argb(uint32_t hex) {
    /* Convert 0xRRGGBB to ARGB format */
    uint8_t r = (hex >> 16) & 0xFF;
    uint8_t g = (hex >> 8) & 0xFF;
    uint8_t b = hex & 0xFF;
    return MFB_ARGB(255, r, g, b);
}

/* ============================================================================
 * Window Management Wrappers
 * ============================================================================ */

static struct mfb_window* smfb_open(const char* title, int width, int height) {
    return mfb_open(title, width, height);
}

static struct mfb_window* smfb_open_ex(const char* title, int width, int height, unsigned int flags) {
    return mfb_open_ex(title, width, height, flags);
}

static int smfb_update(struct mfb_window* window, smfb_buffer* buf) {
    if (!window || !buf || !buf->data) return STATE_INVALID_BUFFER;
    return mfb_update(window, buf->data);
}

static int smfb_update_events(struct mfb_window* window) {
    return mfb_update_events(window);
}

static void smfb_close(struct mfb_window* window) {
    if (window) mfb_close(window);
}

static int smfb_wait_sync(struct mfb_window* window) {
    return mfb_wait_sync(window) ? 1 : 0;
}

/* ============================================================================
 * Window Properties
 * ============================================================================ */

static int smfb_is_window_active(struct mfb_window* window) {
    return window ? mfb_is_window_active(window) : 0;
}

static int smfb_get_window_width(struct mfb_window* window) {
    return window ? mfb_get_window_width(window) : 0;
}

static int smfb_get_window_height(struct mfb_window* window) {
    return window ? mfb_get_window_height(window) : 0;
}

/* ============================================================================
 * Input - Mouse
 * ============================================================================ */

static int smfb_get_mouse_x(struct mfb_window* window) {
    return window ? mfb_get_mouse_x(window) : 0;
}

static int smfb_get_mouse_y(struct mfb_window* window) {
    return window ? mfb_get_mouse_y(window) : 0;
}

static float smfb_get_mouse_scroll_x(struct mfb_window* window) {
    return window ? mfb_get_mouse_scroll_x(window) : 0.0f;
}

static float smfb_get_mouse_scroll_y(struct mfb_window* window) {
    return window ? mfb_get_mouse_scroll_y(window) : 0.0f;
}

static const uint8_t* smfb_get_mouse_button_buffer(struct mfb_window* window) {
    return window ? mfb_get_mouse_button_buffer(window) : NULL;
}

static int smfb_is_mouse_button_down(struct mfb_window* window, int button) {
    const uint8_t* buf;
    if (!window || button < 0 || button > 7) return 0;
    buf = mfb_get_mouse_button_buffer(window);
    return buf ? buf[button] : 0;
}

/* ============================================================================
 * Input - Keyboard
 * ============================================================================ */

static const uint8_t* smfb_get_key_buffer(struct mfb_window* window) {
    return window ? mfb_get_key_buffer(window) : NULL;
}

static int smfb_is_key_down(struct mfb_window* window, int key) {
    const uint8_t* buf;
    if (!window || key < 0 || key > 512) return 0;
    buf = mfb_get_key_buffer(window);
    return buf ? buf[key] : 0;
}

/* ============================================================================
 * Timing / FPS
 * ============================================================================ */

static void smfb_set_target_fps(uint32_t fps) {
    mfb_set_target_fps(fps);
}

static uint32_t smfb_get_target_fps(void) {
    return mfb_get_target_fps();
}

#endif /* SIMPLE_MINIFB_H */
