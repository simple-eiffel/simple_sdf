note
	description: "[
		Window wrapper for MiniFB.

		Provides window management and input handling for SDF visualization.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	MINIFB_WINDOW

create
	make,
	make_ex

feature {NONE} -- Initialization

	make (a_title: STRING; a_width, a_height: INTEGER)
			-- Create window with given title and dimensions.
		require
			title_attached: a_title /= Void
			positive_width: a_width > 0
			positive_height: a_height > 0
		local
			l_c_title: C_STRING
		do
			width := a_width
			height := a_height
			create l_c_title.make (a_title)
			handle := c_open (l_c_title.item, a_width, a_height)
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

	make_ex (a_title: STRING; a_width, a_height: INTEGER; a_flags: NATURAL_32)
			-- Create window with extended options.
		require
			title_attached: a_title /= Void
			positive_width: a_width > 0
			positive_height: a_height > 0
		local
			l_c_title: C_STRING
		do
			width := a_width
			height := a_height
			create l_c_title.make (a_title)
			handle := c_open_ex (l_c_title.item, a_width, a_height, a_flags)
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

feature -- Access

	width: INTEGER
			-- Window width

	height: INTEGER
			-- Window height

	handle: POINTER
			-- Internal window handle

feature -- Status

	is_open: BOOLEAN
			-- Is window still open?
		do
			Result := handle /= default_pointer and then c_is_active (handle) /= 0
		end

	should_close: BOOLEAN
			-- Should window be closed?
		do
			Result := not is_open
		end

feature -- Window Properties

	window_width: INTEGER
			-- Current window width (may differ after resize).
		require
			is_open: is_open
		do
			Result := c_get_width (handle)
		end

	window_height: INTEGER
			-- Current window height (may differ after resize).
		require
			is_open: is_open
		do
			Result := c_get_height (handle)
		end

feature -- Update

	update (a_buffer: MINIFB_BUFFER): INTEGER
			-- Display buffer contents in window.
			-- Returns state code (negative = error, 0 = ok).
		require
			is_open: is_open
			buffer_attached: a_buffer /= Void
		do
			Result := c_update (handle, a_buffer.handle)
		end

	update_events: INTEGER
			-- Process events without updating display.
		require
			is_open: is_open
		do
			Result := c_update_events (handle)
		end

	wait_sync: BOOLEAN
			-- Wait for vertical sync.
			-- Returns True if window is still active.
		require
			is_open: is_open
		do
			Result := c_wait_sync (handle) /= 0
		end

feature -- Input: Mouse

	mouse_x: INTEGER
			-- Current mouse X position.
		require
			is_open: is_open
		do
			Result := c_get_mouse_x (handle)
		end

	mouse_y: INTEGER
			-- Current mouse Y position.
		require
			is_open: is_open
		do
			Result := c_get_mouse_y (handle)
		end

	mouse_scroll_x: REAL
			-- Horizontal scroll amount.
		require
			is_open: is_open
		do
			Result := c_get_scroll_x (handle)
		end

	mouse_scroll_y: REAL
			-- Vertical scroll amount.
		require
			is_open: is_open
		do
			Result := c_get_scroll_y (handle)
		end

	is_mouse_button_down (a_button: INTEGER): BOOLEAN
			-- Is mouse button pressed?
			-- Button: 0=left, 1=right, 2=middle
		require
			is_open: is_open
			valid_button: a_button >= 0 and a_button <= 7
		do
			Result := c_is_mouse_down (handle, a_button) /= 0
		end

feature -- Input: Keyboard

	is_key_down (a_key: INTEGER): BOOLEAN
			-- Is key currently pressed?
		require
			is_open: is_open
			valid_key: a_key >= 0 and a_key <= 512
		do
			Result := c_is_key_down (handle, a_key) /= 0
		end

feature -- Key Constants

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
	Key_space: INTEGER = 32
	Key_a: INTEGER = 65
	Key_c: INTEGER = 67
	Key_d: INTEGER = 68
	Key_e: INTEGER = 69
	Key_q: INTEGER = 81
	Key_r: INTEGER = 82
	Key_s: INTEGER = 83
	Key_w: INTEGER = 87
	Key_left_shift: INTEGER = 340
	Key_left_control: INTEGER = 341
	Key_left_alt: INTEGER = 342
	Key_right_shift: INTEGER = 344
	Key_right_control: INTEGER = 345
	Key_right_alt: INTEGER = 346

feature -- Lifecycle

	close
			-- Close and destroy window.
		do
			if handle /= default_pointer then
				c_close (handle)
				handle := default_pointer
			end
		ensure
			closed: handle = default_pointer
		end

feature {NONE} -- C Externals

	c_open (a_title: POINTER; a_w, a_h: INTEGER): POINTER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_open((const char*)$a_title, (int)$a_w, (int)$a_h);"
		end

	c_open_ex (a_title: POINTER; a_w, a_h: INTEGER; a_flags: NATURAL_32): POINTER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_open_ex((const char*)$a_title, (int)$a_w, (int)$a_h, (unsigned int)$a_flags);"
		end

	c_close (a_win: POINTER)
		external
			"C inline use %"simple_minifb.h%""
		alias
			"smfb_close((struct mfb_window*)$a_win);"
		end

	c_update (a_win, a_buf: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_update((struct mfb_window*)$a_win, (smfb_buffer*)$a_buf);"
		end

	c_update_events (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_update_events((struct mfb_window*)$a_win);"
		end

	c_wait_sync (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_wait_sync((struct mfb_window*)$a_win);"
		end

	c_is_active (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_is_window_active((struct mfb_window*)$a_win);"
		end

	c_get_width (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_window_width((struct mfb_window*)$a_win);"
		end

	c_get_height (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_window_height((struct mfb_window*)$a_win);"
		end

	c_get_mouse_x (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_mouse_x((struct mfb_window*)$a_win);"
		end

	c_get_mouse_y (a_win: POINTER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_mouse_y((struct mfb_window*)$a_win);"
		end

	c_get_scroll_x (a_win: POINTER): REAL
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_mouse_scroll_x((struct mfb_window*)$a_win);"
		end

	c_get_scroll_y (a_win: POINTER): REAL
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_get_mouse_scroll_y((struct mfb_window*)$a_win);"
		end

	c_is_mouse_down (a_win: POINTER; a_btn: INTEGER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_is_mouse_button_down((struct mfb_window*)$a_win, (int)$a_btn);"
		end

	c_is_key_down (a_win: POINTER; a_key: INTEGER): INTEGER
		external
			"C inline use %"simple_minifb.h%""
		alias
			"return smfb_is_key_down((struct mfb_window*)$a_win, (int)$a_key);"
		end

invariant
	positive_dimensions: width > 0 and height > 0

end
