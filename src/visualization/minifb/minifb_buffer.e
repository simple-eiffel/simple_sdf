note
	description: "[
		Pixel buffer for MiniFB rendering.

		Provides direct pixel manipulation for CPU-based SDF ray marching.
		Buffer is in ARGB format (32-bit per pixel).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	MINIFB_BUFFER

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

	set_pixel (a_x, a_y: INTEGER; a_color: NATURAL_32)
			-- Set pixel at (x, y) to color.
		require
			valid_x: a_x >= 0 and a_x < width
			valid_y: a_y >= 0 and a_y < height
		do
			c_set_pixel (handle, a_x, a_y, a_color)
		end

	pixel (a_x, a_y: INTEGER): NATURAL_32
			-- Get pixel color at (x, y).
		require
			valid_x: a_x >= 0 and a_x < width
			valid_y: a_y >= 0 and a_y < height
		do
			Result := c_get_pixel (handle, a_x, a_y)
		end

	clear (a_color: NATURAL_32)
			-- Clear entire buffer with color.
		do
			c_clear (handle, a_color)
		end

	fill_rect (a_x, a_y, a_width, a_height: INTEGER; a_color: NATURAL_32)
			-- Fill rectangle with color.
		do
			c_fill_rect (handle, a_x, a_y, a_width, a_height, a_color)
		end

feature -- Color Helpers

	rgb (a_r, a_g, a_b: NATURAL_8): NATURAL_32
			-- Create RGB color (alpha = 255).
		do
			Result := c_rgb (a_r, a_g, a_b)
		end

	argb (a_a, a_r, a_g, a_b: NATURAL_8): NATURAL_32
			-- Create ARGB color.
		do
			Result := c_argb (a_a, a_r, a_g, a_b)
		end

	hex_color (a_hex: INTEGER): NATURAL_32
			-- Convert hex color (0xRRGGBB) to ARGB format.
		do
			Result := c_hex_to_argb (a_hex.as_natural_32)
		end

feature -- Bulk Copy

	copy_from (a_source: POINTER; a_byte_count: INTEGER)
			-- Copy raw pixel data from source pointer.
			-- Source must be ARGB format, same dimensions as buffer.
		require
			source_attached: a_source /= default_pointer
			valid_size: a_byte_count = width * height * 4
		do
			c_copy_from (handle, a_source, a_byte_count)
		end

	data_pointer: POINTER
			-- Direct pointer to pixel data (use with caution).
		do
			Result := c_get_data (handle)
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
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_create_buffer((int)$a_w, (int)$a_h);"
		end

	c_free_buffer (a_buf: POINTER)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_free_buffer((smfb_buffer*)$a_buf);"
		end

	c_set_pixel (a_buf: POINTER; a_x, a_y: INTEGER; a_color: NATURAL_32)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_set_pixel((smfb_buffer*)$a_buf, (int)$a_x, (int)$a_y, (uint32_t)$a_color);"
		end

	c_get_pixel (a_buf: POINTER; a_x, a_y: INTEGER): NATURAL_32
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_pixel((smfb_buffer*)$a_buf, (int)$a_x, (int)$a_y);"
		end

	c_clear (a_buf: POINTER; a_color: NATURAL_32)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_clear((smfb_buffer*)$a_buf, (uint32_t)$a_color);"
		end

	c_fill_rect (a_buf: POINTER; a_x, a_y, a_w, a_h: INTEGER; a_color: NATURAL_32)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_fill_rect((smfb_buffer*)$a_buf, (int)$a_x, (int)$a_y, (int)$a_w, (int)$a_h, (uint32_t)$a_color);"
		end

	c_rgb (a_r, a_g, a_b: NATURAL_8): NATURAL_32
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_rgb((uint8_t)$a_r, (uint8_t)$a_g, (uint8_t)$a_b);"
		end

	c_argb (a_a, a_r, a_g, a_b: NATURAL_8): NATURAL_32
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_argb((uint8_t)$a_a, (uint8_t)$a_r, (uint8_t)$a_g, (uint8_t)$a_b);"
		end

	c_hex_to_argb (a_hex: NATURAL_32): NATURAL_32
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_hex_to_argb((uint32_t)$a_hex);"
		end

	c_copy_from (a_buf, a_src: POINTER; a_size: INTEGER)
		external
			"C inline use %"simple_minifb.h%", <string.h>"
		alias
			"[
				smfb_buffer* buf = (smfb_buffer*)$a_buf;
				if (buf && buf->data) {
					memcpy(buf->data, $a_src, (size_t)$a_size);
				}
			]"
		end

	c_get_data (a_buf: POINTER): POINTER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"[
				smfb_buffer* buf = (smfb_buffer*)$a_buf;
				return buf ? buf->data : NULL;
			]"
		end

invariant
	positive_dimensions: width > 0 and height > 0

end
