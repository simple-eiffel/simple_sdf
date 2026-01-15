note
	description: "[
		SIMPLE_RAYLIB - Facade class for raylib visualization.

		Provides window management, rendering, and input handling.
		Uses raylib's hardware-accelerated texture rendering for
		efficient SDF visualization.

		Usage:
			local
				rl: SIMPLE_RAYLIB
				buf: RAYLIB_BUFFER
			do
				create rl
				rl.init_window (800, 600, "SDF Demo")
				buf := rl.buffer (320, 240)
				from until rl.should_close loop
					-- render to buffer...
					buf.update_texture
					rl.begin_drawing
					rl.clear (25, 25, 40)
					buf.draw_scaled (0, 0, 800, 600)
					rl.draw_fps (10, 10)
					rl.end_drawing
				end
				buf.dispose
				rl.close_window
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_RAYLIB

create
	default_create

feature -- Window Management

	init_window (a_width, a_height: INTEGER; a_title: STRING)
			-- Initialize window with given dimensions and title.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
			title_attached: a_title /= Void
		local
			l_c_title: C_STRING
		do
			create l_c_title.make (a_title)
			c_init_window (a_width, a_height, l_c_title.item)
		end

	close_window
			-- Close the window and cleanup resources.
		do
			c_close_window
		end

	should_close: BOOLEAN
			-- Should the window be closed?
		do
			Result := c_window_should_close /= 0
		end

	is_ready: BOOLEAN
			-- Is the window ready for rendering?
		do
			Result := c_is_window_ready /= 0
		end

	screen_width: INTEGER
			-- Current screen width.
		do
			Result := c_get_screen_width
		end

	screen_height: INTEGER
			-- Current screen height.
		do
			Result := c_get_screen_height
		end

feature -- Frame Rate

	set_target_fps (a_fps: INTEGER)
			-- Set target frame rate.
		require
			positive_fps: a_fps > 0
		do
			c_set_target_fps (a_fps)
		end

	fps: INTEGER
			-- Current frames per second.
		do
			Result := c_get_fps
		end

	frame_time: REAL
			-- Time for last frame in seconds.
		do
			Result := c_get_frame_time
		end

feature -- Drawing

	begin_drawing
			-- Begin drawing mode.
		do
			c_begin_drawing
		end

	end_drawing
			-- End drawing mode and swap buffers.
		do
			c_end_drawing
		end

	clear (a_r, a_g, a_b: NATURAL_8)
			-- Clear screen with RGB color.
		do
			c_clear_background (a_r, a_g, a_b, 255)
		end

	draw_text (a_text: STRING; a_x, a_y, a_size: INTEGER; a_r, a_g, a_b: NATURAL_8)
			-- Draw text at position with color.
		require
			text_attached: a_text /= Void
		local
			l_c_text: C_STRING
		do
			create l_c_text.make (a_text)
			c_draw_text (l_c_text.item, a_x, a_y, a_size, a_r, a_g, a_b, 255)
		end

	draw_fps (a_x, a_y: INTEGER)
			-- Draw FPS counter at position.
		do
			c_draw_fps (a_x, a_y)
		end

feature -- Buffer Factory

	buffer (a_width, a_height: INTEGER): RAYLIB_BUFFER
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

feature -- Input: Keyboard

	is_key_down (a_key: INTEGER): BOOLEAN
			-- Is key currently pressed?
		do
			Result := c_is_key_down (a_key) /= 0
		end

	is_key_pressed (a_key: INTEGER): BOOLEAN
			-- Was key pressed this frame?
		do
			Result := c_is_key_pressed (a_key) /= 0
		end

feature -- Input: Mouse

	mouse_x: INTEGER
			-- Current mouse X position.
		do
			Result := c_get_mouse_x
		end

	mouse_y: INTEGER
			-- Current mouse Y position.
		do
			Result := c_get_mouse_y
		end

	is_mouse_button_down (a_button: INTEGER): BOOLEAN
			-- Is mouse button pressed?
		do
			Result := c_is_mouse_button_down (a_button) /= 0
		end

	mouse_wheel: REAL
			-- Mouse wheel movement.
		do
			Result := c_get_mouse_wheel_move
		end

feature -- Key Constants

	Key_space: INTEGER = 32
	Key_escape: INTEGER = 256
	Key_enter: INTEGER = 257
	Key_tab: INTEGER = 258
	Key_backspace: INTEGER = 259
	Key_insert: INTEGER = 260
	Key_delete: INTEGER = 261
	Key_right: INTEGER = 262
	Key_left: INTEGER = 263
	Key_down: INTEGER = 264
	Key_up: INTEGER = 265
	Key_page_up: INTEGER = 266
	Key_page_down: INTEGER = 267
	Key_home: INTEGER = 268
	Key_end: INTEGER = 269
	Key_a: INTEGER = 65
	Key_d: INTEGER = 68
	Key_s: INTEGER = 83
	Key_w: INTEGER = 87
	Key_q: INTEGER = 81

feature -- Mouse Button Constants

	Mouse_left: INTEGER = 0
	Mouse_right: INTEGER = 1
	Mouse_middle: INTEGER = 2

feature {NONE} -- C Externals

	c_init_window (a_w, a_h: INTEGER; a_title: POINTER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_init_window((int)$a_w, (int)$a_h, (const char*)$a_title);"
		end

	c_close_window
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_close_window();"
		end

	c_window_should_close: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_window_should_close();"
		end

	c_is_window_ready: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_is_window_ready();"
		end

	c_get_screen_width: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_screen_width();"
		end

	c_get_screen_height: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_screen_height();"
		end

	c_set_target_fps (a_fps: INTEGER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_set_target_fps((int)$a_fps);"
		end

	c_get_fps: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_fps();"
		end

	c_get_frame_time: REAL
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_frame_time();"
		end

	c_begin_drawing
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_begin_drawing();"
		end

	c_end_drawing
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_end_drawing();"
		end

	c_clear_background (a_r, a_g, a_b, a_a: NATURAL_8)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_clear_background((unsigned char)$a_r, (unsigned char)$a_g, (unsigned char)$a_b, (unsigned char)$a_a);"
		end

	c_draw_text (a_text: POINTER; a_x, a_y, a_size: INTEGER; a_r, a_g, a_b, a_a: NATURAL_8)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_draw_text((const char*)$a_text, (int)$a_x, (int)$a_y, (int)$a_size, (unsigned char)$a_r, (unsigned char)$a_g, (unsigned char)$a_b, (unsigned char)$a_a);"
		end

	c_draw_fps (a_x, a_y: INTEGER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_draw_fps((int)$a_x, (int)$a_y);"
		end

	c_is_key_down (a_key: INTEGER): INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_is_key_down((int)$a_key);"
		end

	c_is_key_pressed (a_key: INTEGER): INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_is_key_pressed((int)$a_key);"
		end

	c_get_mouse_x: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_mouse_x();"
		end

	c_get_mouse_y: INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_mouse_y();"
		end

	c_is_mouse_button_down (a_btn: INTEGER): INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_is_mouse_button_down((int)$a_btn);"
		end

	c_get_mouse_wheel_move: REAL
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_get_mouse_wheel_move();"
		end

end
