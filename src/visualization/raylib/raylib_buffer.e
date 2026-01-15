note
	description: "[
		Pixel buffer for raylib rendering.

		Provides CPU-side pixel manipulation that gets uploaded to GPU texture.
		Supports efficient buffer-to-screen rendering with scaling.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	RAYLIB_BUFFER

create
	make

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Create buffer with specified dimensions.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			width := a_width
			height := a_height
			handle := c_create_buffer (a_width, a_height)
		ensure
			width_set: width = a_width
			height_set: height = a_height
			handle_created: handle /= default_pointer
		end

feature -- Access

	width: INTEGER
			-- Buffer width in pixels

	height: INTEGER
			-- Buffer height in pixels

	handle: POINTER
			-- Internal buffer handle

feature -- Pixel Operations

	set_pixel (a_x, a_y: INTEGER; a_r, a_g, a_b: NATURAL_8)
			-- Set pixel at (x, y) to RGB color.
		require
			valid_x: a_x >= 0 and a_x < width
			valid_y: a_y >= 0 and a_y < height
		do
			c_set_pixel (handle, a_x, a_y, a_r, a_g, a_b, 255)
		end

	set_pixel_rgba (a_x, a_y: INTEGER; a_r, a_g, a_b, a_a: NATURAL_8)
			-- Set pixel at (x, y) to RGBA color.
		require
			valid_x: a_x >= 0 and a_x < width
			valid_y: a_y >= 0 and a_y < height
		do
			c_set_pixel (handle, a_x, a_y, a_r, a_g, a_b, a_a)
		end

	clear (a_r, a_g, a_b: NATURAL_8)
			-- Clear entire buffer with RGB color.
		do
			c_clear_buffer (handle, a_r, a_g, a_b, 255)
		end

feature -- Rendering

	update_texture
			-- Upload pixel data to GPU texture.
			-- Call this after modifying pixels, before drawing.
		do
			c_update_texture (handle)
		end

	draw (a_x, a_y: INTEGER)
			-- Draw buffer at position (x, y).
		do
			c_draw_buffer (handle, a_x, a_y)
		end

	draw_scaled (a_x, a_y, a_dest_width, a_dest_height: INTEGER)
			-- Draw buffer scaled to destination dimensions.
		do
			c_draw_buffer_scaled (handle, a_x, a_y, a_dest_width, a_dest_height)
		end

feature -- Memory Management

	dispose
			-- Free buffer memory.
		do
			if handle /= default_pointer then
				c_free_buffer (handle)
				handle := default_pointer
			end
		ensure
			disposed: handle = default_pointer
		end

feature {NONE} -- C Externals

	c_create_buffer (a_w, a_h: INTEGER): POINTER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_create_render_buffer((int)$a_w, (int)$a_h);"
		end

	c_free_buffer (a_buf: POINTER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_free_render_buffer((void*)$a_buf);"
		end

	c_set_pixel (a_buf: POINTER; a_x, a_y: INTEGER; a_r, a_g, a_b, a_a: NATURAL_8)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_set_pixel((void*)$a_buf, (int)$a_x, (int)$a_y, (unsigned char)$a_r, (unsigned char)$a_g, (unsigned char)$a_b, (unsigned char)$a_a);"
		end

	c_clear_buffer (a_buf: POINTER; a_r, a_g, a_b, a_a: NATURAL_8)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_clear_buffer((void*)$a_buf, (unsigned char)$a_r, (unsigned char)$a_g, (unsigned char)$a_b, (unsigned char)$a_a);"
		end

	c_update_texture (a_buf: POINTER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_update_texture((void*)$a_buf);"
		end

	c_draw_buffer (a_buf: POINTER; a_x, a_y: INTEGER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_draw_buffer((void*)$a_buf, (int)$a_x, (int)$a_y);"
		end

	c_draw_buffer_scaled (a_buf: POINTER; a_x, a_y, a_dw, a_dh: INTEGER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_draw_buffer_scaled((void*)$a_buf, (int)$a_x, (int)$a_y, (int)$a_dw, (int)$a_dh);"
		end

invariant
	positive_dimensions: width > 0 and height > 0

end
