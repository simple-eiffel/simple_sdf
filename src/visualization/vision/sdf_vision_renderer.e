note
	description: "[
		SDF renderer embedded in simple_vision window.

		Uses EV_TITLED_WINDOW as container with a Win32 child window
		for direct buffer blitting via SetDIBitsToDevice. Runs in
		EV_APPLICATION event loop so window stays active even when not focused.

		NO EV_PIXMAP - uses native Win32 rendering for performance.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_VISION_RENDERER

inherit
	SV_ANY

create
	make

feature {NONE} -- Initialization

	make (a_title: STRING; a_width, a_height: INTEGER; a_shader: STRING)
			-- Create renderer with shader.
		require
			valid_title: not a_title.is_empty
			valid_size: a_width > 0 and a_height > 0
			valid_shader: not a_shader.is_empty
		local
			l_vk: SIMPLE_VULKAN
			l_ctx: VULKAN_CONTEXT
			l_shader: VULKAN_SHADER
			l_pipeline: VULKAN_PIPELINE
			l_out, l_par: VULKAN_BUFFER
		do
			title := a_title
			width := a_width
			height := a_height
			shader_name := a_shader

			-- Initialize camera
			camera_x := 0; camera_y := 2; camera_z := 8
			camera_yaw := 0; camera_pitch := -0.1
			move_speed := 0.3; look_speed := 0.03
			time_scale := 1.0

			-- Initialize Vulkan
			create l_vk
			vk := l_vk
			l_ctx := l_vk.create_context
			ctx := l_ctx

			if l_ctx.is_valid then
				l_shader := l_vk.load_shader (l_ctx, shader_directory + a_shader)
				shader := l_shader

				if l_shader.is_valid then
					l_pipeline := l_vk.create_pipeline (l_ctx, l_shader)
					pipeline := l_pipeline

					if l_pipeline.is_valid then
						l_out := l_vk.create_buffer (l_ctx, (a_width * a_height * 4).to_integer_64,
							l_vk.Buffer_storage | l_vk.Buffer_transfer)
						l_par := l_vk.create_buffer (l_ctx, 32, l_vk.Buffer_storage)
						output_buffer := l_out
						params_buffer := l_par

						if l_out.is_valid and l_par.is_valid then
							l_pipeline.bind_buffer (0, l_out).do_nothing
							l_pipeline.bind_buffer (1, l_par).do_nothing
							is_ready := True
						end
					end
				end
			end

			-- Create pixel buffer and params
			create pixels.make (width * height * 4)
			create params.make (32)

			-- Create BITMAPINFO for SetDIBitsToDevice
			create bitmap_info.make (40 + 12) -- BITMAPINFOHEADER = 40, plus 3 DWORD masks
			init_bitmap_info

			-- Initialize other attributes
			create key_states.make (20)
			full_title := a_title
		end

feature -- Access

	title: STRING
	width, height: INTEGER
	shader_name: STRING
	is_ready: BOOLEAN

	gpu_name: STRING
		do
			if attached ctx as c then
				Result := c.device_name
			else
				Result := "Unknown"
			end
		end

feature -- Camera

	camera_x, camera_y, camera_z: REAL
	camera_yaw, camera_pitch: REAL
	move_speed, look_speed: REAL
	time_scale: REAL
	time: REAL
	is_paused: BOOLEAN

	set_camera (a_x, a_y, a_z: REAL)
		do
			camera_x := a_x
			camera_y := a_y
			camera_z := a_z
		end

feature -- Execution

	run
			-- Run in simple_vision event loop.
		local
			app: SV_APPLICATION
			win: SV_WINDOW
			l_hwnd: POINTER
		do
			if not is_ready then
				-- Silently fail for GUI app (no console)
			else

				-- Create simple_vision app and window
				create app.make
				full_title := title + " - " + gpu_name
				create win.make_with_title (full_title)
				win.set_size (width + 16, height + 39).do_nothing -- Account for window chrome
				win.centered.do_nothing

				-- Store references
				sv_app := app
				sv_window := win

				-- Initialize key state
				create key_states.make (20)

				-- Set up keyboard handler via the EV_TITLED_WINDOW
				win.ev_titled_window.key_press_actions.extend (agent on_key_press)
				win.ev_titled_window.key_release_actions.extend (agent on_key_release)

				-- Add window and show it
				app.add_window (win)
				win.show_now

				-- Process events to ensure window is created
				app.ev_application.process_events

				-- Get native window handle now that window exists
				l_hwnd := c_find_window (full_title)
				parent_hwnd := l_hwnd

				-- Create child window for rendering
				if l_hwnd /= default_pointer then
					child_hwnd := create_render_child (l_hwnd, width, height)
				end

				-- Set up idle action for render loop
				app.ev_application.add_idle_action (agent on_idle (app))

				running := True
				app.launch
			end
		end

feature {NONE} -- Event Handlers

	on_idle (app: SV_APPLICATION)
			-- Called when event loop is idle - render a frame.
		do
			if running and is_ready then
				process_input
				render_frame
				blit_to_child_window
			end
		end

	on_key_press (key: EV_KEY)
			-- Handle key press.
		do
			key_states.force (True, key.code)

			-- Check for ESC
			if key.code = {EV_KEY_CONSTANTS}.key_escape then
				running := False
				if attached sv_app as app then
					app.quit
				end
			end

			-- P for pause
			if key.code = {EV_KEY_CONSTANTS}.key_p then
				is_paused := not is_paused
			end
		end

	on_key_release (key: EV_KEY)
			-- Handle key release.
		do
			key_states.force (False, key.code)
		end

feature {NONE} -- Input Processing

	process_input
			-- Process keyboard input for camera movement.
		local
			m: DOUBLE_MATH
			cy, sy: REAL_64
		do
			create m
			cy := m.cosine (camera_yaw)
			sy := m.sine (camera_yaw)

			if is_key_down ({EV_KEY_CONSTANTS}.key_w) then
				camera_x := camera_x - (sy * move_speed).truncated_to_real
				camera_z := camera_z - (cy * move_speed).truncated_to_real
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_s) then
				camera_x := camera_x + (sy * move_speed).truncated_to_real
				camera_z := camera_z + (cy * move_speed).truncated_to_real
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_a) then
				camera_x := camera_x - (cy * move_speed).truncated_to_real
				camera_z := camera_z + (sy * move_speed).truncated_to_real
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_d) then
				camera_x := camera_x + (cy * move_speed).truncated_to_real
				camera_z := camera_z - (sy * move_speed).truncated_to_real
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_space) then
				camera_y := camera_y + move_speed
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_shift) then
				camera_y := camera_y - move_speed
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_left) then
				camera_yaw := camera_yaw - look_speed
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_right) then
				camera_yaw := camera_yaw + look_speed
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_up) then
				camera_pitch := (camera_pitch + look_speed).min (1.5)
			end
			if is_key_down ({EV_KEY_CONSTANTS}.key_down) then
				camera_pitch := (camera_pitch - look_speed).max (-1.5)
			end
		end

feature {NONE} -- Rendering

	render_frame
			-- Render one frame via Vulkan compute.
		local
			dt: REAL
		do
			dt := 0.016  -- ~60 FPS target

			-- Update time
			if not is_paused then
				time := time + dt * time_scale
			end

			-- Run Vulkan compute
			if attached pipeline as p and attached ctx as c and
			   attached output_buffer as ob and attached params_buffer as pb then

				params.put_real_32 (camera_x, 0)
				params.put_real_32 (camera_y, 4)
				params.put_real_32 (camera_z, 8)
				params.put_real_32 (camera_yaw, 12)
				params.put_real_32 (camera_pitch, 16)
				params.put_real_32 (time, 20)
				params.put_natural_32 (width.to_natural_32, 24)
				params.put_natural_32 (height.to_natural_32, 28)

				pb.upload (params.item, 32, 0).do_nothing
				p.dispatch (c, (width + 15) // 16, (height + 15) // 16, 1).do_nothing
				p.wait_idle (c)
				ob.download (pixels.item, (width * height * 4).to_integer_64, 0).do_nothing
			end

			-- Update FPS counter (shown in window title)
			frame_count := frame_count + 1
			fps_time := fps_time + dt
			if fps_time >= 1.0 then
				if attached sv_window as w then
					w.ev_titled_window.set_title (full_title + " [" + frame_count.out + " FPS]")
				end
				frame_count := 0
				fps_time := 0
			end
		end

	blit_to_child_window
			-- Blit pixel buffer to child window using SetDIBitsToDevice.
		do
			if child_hwnd /= default_pointer then
				c_blit_buffer (child_hwnd, pixels.item, bitmap_info.item, width, height)
			end
		end

	is_key_down (code: INTEGER): BOOLEAN
			-- Is key currently pressed?
		do
			Result := key_states.has (code) and then key_states [code]
		end

feature {NONE} -- Win32 Native Window

	init_bitmap_info
			-- Initialize BITMAPINFO structure for 32-bit BGRA.
		do
			-- BITMAPINFOHEADER
			bitmap_info.put_integer_32 (40, 0)           -- biSize
			bitmap_info.put_integer_32 (width, 4)        -- biWidth
			bitmap_info.put_integer_32 (-height, 8)      -- biHeight (negative = top-down)
			bitmap_info.put_integer_16 (1, 12)           -- biPlanes
			bitmap_info.put_integer_16 (32, 14)          -- biBitCount
			bitmap_info.put_integer_32 (0, 16)           -- biCompression = BI_RGB
			bitmap_info.put_integer_32 (0, 20)           -- biSizeImage
			bitmap_info.put_integer_32 (0, 24)           -- biXPelsPerMeter
			bitmap_info.put_integer_32 (0, 28)           -- biYPelsPerMeter
			bitmap_info.put_integer_32 (0, 32)           -- biClrUsed
			bitmap_info.put_integer_32 (0, 36)           -- biClrImportant
		end

	c_find_window (a_title: STRING): POINTER
			-- Find window by title using ANSI version.
		local
			l_c_str: C_STRING
		do
			create l_c_str.make (a_title)
			Result := c_find_window_a (l_c_str.item)
		end

	c_find_window_a (a_title: POINTER): POINTER
			-- Find window by title (ANSI).
		external
			"C inline use <windows.h>"
		alias
			"[
				return (EIF_POINTER)FindWindowA(NULL, (LPCSTR)$a_title);
			]"
		end

	create_render_child (a_parent: POINTER; a_w, a_h: INTEGER): POINTER
			-- Create a child window for rendering.
		external
			"C inline use <windows.h>"
		alias
			"[
				HWND hwnd = CreateWindowExW(
					0,
					L"STATIC",  // Simple static control as render target
					L"",
					WS_CHILD | WS_VISIBLE | SS_BITMAP,
					0, 0, (int)$a_w, (int)$a_h,
					(HWND)$a_parent,
					NULL,
					GetModuleHandle(NULL),
					NULL
				);
				return (EIF_POINTER)hwnd;
			]"
		end

	c_blit_buffer (a_hwnd, a_pixels, a_bmi: POINTER; a_w, a_h: INTEGER)
			-- Blit pixel buffer to window using SetDIBitsToDevice.
		external
			"C inline use <windows.h>"
		alias
			"[
				HDC hdc = GetDC((HWND)$a_hwnd);
				if (hdc) {
					SetDIBitsToDevice(
						hdc,
						0, 0,                    // dest x, y
						(DWORD)$a_w, (DWORD)$a_h, // width, height
						0, 0,                    // src x, y
						0, (UINT)$a_h,           // start scan, num scans
						$a_pixels,
						(BITMAPINFO*)$a_bmi,
						DIB_RGB_COLORS
					);
					ReleaseDC((HWND)$a_hwnd, hdc);
				}
			]"
		end

feature {NONE} -- Implementation

	vk: detachable SIMPLE_VULKAN
	ctx: detachable VULKAN_CONTEXT
	shader: detachable VULKAN_SHADER
	pipeline: detachable VULKAN_PIPELINE
	output_buffer, params_buffer: detachable VULKAN_BUFFER

	pixels, params: MANAGED_POINTER
	bitmap_info: MANAGED_POINTER

	sv_app: detachable SV_APPLICATION
	sv_window: detachable SV_WINDOW
	full_title: STRING
	parent_hwnd, child_hwnd: POINTER

	key_states: HASH_TABLE [BOOLEAN, INTEGER]

	running: BOOLEAN
	frame_count: INTEGER
	fps_time: REAL

	shader_directory: STRING
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("SIMPLE_EIFFEL") as se then
				Result := se.to_string_8 + "/simple_vulkan/shaders/"
			else
				Result := "shaders/"
			end
		end

	cleanup
			-- Release Vulkan resources.
		do
			if attached output_buffer as b then b.dispose end
			if attached params_buffer as b then b.dispose end
			if attached pipeline as p then p.dispose end
			if attached shader as s then s.dispose end
			if attached ctx as c then c.dispose end
		end

end
