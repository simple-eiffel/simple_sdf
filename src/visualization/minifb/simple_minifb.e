note
	description: "[
		SIMPLE_MINIFB - Facade class for MiniFB visualization.

		Provides factory methods for creating windows, buffers, and colors.
		Designed for CPU-based SDF ray marching visualization.

		Usage:
			local
				mfb: SIMPLE_MINIFB
				win: MINIFB_WINDOW
				buf: MINIFB_BUFFER
			do
				create mfb
				win := mfb.open ("SDF Demo", 800, 600)
				buf := mfb.buffer (800, 600)
				from until win.should_close loop
					buf.clear (mfb.rgb (0, 0, 0))
					-- render scene to buffer...
					win.update (buf).do_nothing
					win.wait_sync.do_nothing
				end
				buf.dispose
				win.close
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_MINIFB

create
	default_create

feature -- Window Factory

	open (a_title: STRING; a_width, a_height: INTEGER): MINIFB_WINDOW
			-- Create window with given title and dimensions.
		require
			title_attached: a_title /= Void
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			create Result.make (a_title, a_width, a_height)
		ensure
			result_attached: Result /= Void
		end

	open_ex (a_title: STRING; a_width, a_height: INTEGER; a_flags: NATURAL_32): MINIFB_WINDOW
			-- Create window with extended options.
		require
			title_attached: a_title /= Void
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			create Result.make_ex (a_title, a_width, a_height, a_flags)
		ensure
			result_attached: Result /= Void
		end

feature -- Buffer Factory

	buffer (a_width, a_height: INTEGER): MINIFB_BUFFER
			-- Create pixel buffer with given dimensions.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			create Result.make (a_width, a_height)
		ensure
			result_attached: Result /= Void
			width_correct: Result.width = a_width
			height_correct: Result.height = a_height
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

feature -- Common Colors

	color_black: NATURAL_32
			-- Black color
		once
			Result := rgb (0, 0, 0)
		end

	color_white: NATURAL_32
			-- White color
		once
			Result := rgb (255, 255, 255)
		end

	color_red: NATURAL_32
			-- Red color
		once
			Result := rgb (255, 0, 0)
		end

	color_green: NATURAL_32
			-- Green color
		once
			Result := rgb (0, 255, 0)
		end

	color_blue: NATURAL_32
			-- Blue color
		once
			Result := rgb (0, 0, 255)
		end

	color_background: NATURAL_32
			-- Default background color (dark gray)
		once
			Result := rgb (25, 25, 40)
		end

feature -- Frame Rate

	set_target_fps (a_fps: INTEGER)
			-- Set target frame rate.
		require
			positive_fps: a_fps > 0
		do
			c_set_target_fps (a_fps.as_natural_32)
		end

	target_fps: INTEGER
			-- Get target frame rate.
		do
			Result := c_get_target_fps.as_integer_32
		end

feature -- Window Flags

	Flag_resizable: NATURAL_32 = 0x01
			-- Window can be resized

	Flag_fullscreen: NATURAL_32 = 0x02
			-- Fullscreen mode

	Flag_fullscreen_desktop: NATURAL_32 = 0x04
			-- Fullscreen desktop mode

	Flag_borderless: NATURAL_32 = 0x08
			-- Borderless window

	Flag_always_on_top: NATURAL_32 = 0x10
			-- Window stays on top

feature {NONE} -- C Externals

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

	c_set_target_fps (a_fps: NATURAL_32)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_set_target_fps((uint32_t)$a_fps);"
		end

	c_get_target_fps: NATURAL_32
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_target_fps();"
		end

end
