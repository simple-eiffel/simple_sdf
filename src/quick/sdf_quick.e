note
	description: "[
		SDF_QUICK - 80% of SDF power with 20% of code.

		Generic GPU-accelerated 3D visualization. Handles Vulkan, windowing,
		camera, screenshots, and animation automatically.
		You provide the shader - SDF_QUICK handles everything else.

		MINIMAL EXAMPLE:
			class MY_APP create make feature
				make
					local sdf: SDF_QUICK
					do
						create sdf.make_with_shader ("My Scene", 1920, 1080, "my_shader.spv")
						sdf.set_camera (0, 5, 20)
						sdf.run
					end
			end

		CREATION:
			make_with_shader (title, width, height, shader_path)  -- Any shader
			make / make_720p / make_1080p / make_4k               -- Default shader

		CAMERA:
			sdf.set_camera (x, y, z)                   -- Position
			sdf.look_at (x, y, z)                      -- Point at target
			sdf.orbit_around (x, y, z, radius)         -- Auto-orbit mode

		ANIMATION:
			sdf.pause / sdf.resume                     -- Freeze/unfreeze time
			sdf.set_time_scale (0.5)                   -- Slow motion

		SCREENSHOTS:
			sdf.screenshot ("frame.bmp")              -- Save frame (F12 key)

		CALLBACKS:
			sdf.set_on_frame (agent my_update)        -- Per-frame logic

		CONTROLS (built-in):
			WASD, Space/Ctrl    - Move
			Arrows              - Look
			P                   - Pause
			F12                 - Screenshot
			ESC                 - Exit
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_QUICK

create
	make, make_720p, make_1080p, make_4k, make_with_shader

feature {NONE} -- Initialization

	make (a_title: STRING; a_width, a_height: INTEGER)
			-- Create with default shader.
		require
			title_not_empty: not a_title.is_empty
			valid_size: a_width > 0 and a_height > 0
		do
			initialize (a_title, a_width, a_height, Default_shader)
		end

	make_720p (a_title: STRING) do initialize (a_title, 1280, 720, Default_shader) end
	make_1080p (a_title: STRING) do initialize (a_title, 1920, 1080, Default_shader) end
	make_4k (a_title: STRING) do initialize (a_title, 3840, 2160, Default_shader) end

	make_with_shader (a_title: STRING; a_width, a_height: INTEGER; a_shader: STRING)
			-- Create with custom shader (path relative to $SIMPLE_EIFFEL/simple_vulkan/shaders/).
		require
			valid: not a_title.is_empty and a_width > 0 and a_height > 0 and not a_shader.is_empty
		do
			initialize (a_title, a_width, a_height, a_shader)
		end

feature -- Status

	title: STRING
	width, height: INTEGER
	is_ready: BOOLEAN
	fps: INTEGER
	time: REAL
	real_time: REAL
	frame_count: INTEGER

	gpu_name: STRING
		do
			if attached ctx as c then Result := c.device_name else Result := "Unknown" end
		end

feature -- Camera Position

	camera_x, camera_y, camera_z: REAL
	camera_yaw, camera_pitch: REAL
	move_speed: REAL assign set_move_speed
	look_speed: REAL assign set_look_speed

	set_camera (a_x, a_y, a_z: REAL)
		do
			camera_x := a_x; camera_y := a_y; camera_z := a_z
			orbit_mode := False
		end

	set_camera_rotation (a_yaw, a_pitch: REAL)
		do
			camera_yaw := a_yaw
			camera_pitch := a_pitch.max (-1.5).min (1.5)
		end

	look_at (a_x, a_y, a_z: REAL)
			-- Point camera at target.
		local
			dx, dy, dz: REAL_64
			m: DOUBLE_MATH
		do
			create m
			dx := a_x - camera_x; dy := a_y - camera_y; dz := a_z - camera_z
			camera_yaw := m.arc_tangent ((-dx) / (-dz).max (0.0001)).truncated_to_real
			camera_pitch := m.arc_tangent (dy / m.sqrt (dx*dx + dz*dz).max (0.0001)).truncated_to_real.max (-1.5).min (1.5)
		end

	set_move_speed (a_speed: REAL) require a_speed > 0 do move_speed := a_speed end
	set_look_speed (a_speed: REAL) require a_speed > 0 do look_speed := a_speed end

feature -- Camera Orbit

	orbit_mode: BOOLEAN
	orbit_center_x, orbit_center_y, orbit_center_z, orbit_radius, orbit_speed: REAL

	orbit_around (a_x, a_y, a_z, a_radius: REAL)
			-- Auto-orbit camera around point.
		require
			positive_radius: a_radius > 0
		do
			orbit_center_x := a_x; orbit_center_y := a_y; orbit_center_z := a_z
			orbit_radius := a_radius; orbit_speed := 0.5; orbit_mode := True
		end

	set_orbit_speed (a_speed: REAL) do orbit_speed := a_speed end
	stop_orbit do orbit_mode := False end

feature -- Animation Control

	is_paused: BOOLEAN
	time_scale: REAL

	pause do is_paused := True end
	resume do is_paused := False end
	toggle_pause do is_paused := not is_paused end

	set_time_scale (a_scale: REAL)
			-- Set time multiplier (0.5 = slow motion, 2.0 = fast).
		require
			positive: a_scale > 0
		do
			time_scale := a_scale
		end

feature -- Screenshots

	screenshot (a_path: STRING)
			-- Save current frame as BMP.
		require
			not_empty: not a_path.is_empty
		do
			screenshot_pending := True
			screenshot_path := a_path
		end

feature -- Callbacks

	on_frame: detachable PROCEDURE [REAL]
	set_on_frame (a_cb: PROCEDURE [REAL]) do on_frame := a_cb end

feature -- Execution

	run
			-- Start render loop. Returns on ESC or window close.
		do
			if is_ready then
				print ("GPU: " + gpu_name + "%N")
				print ("Resolution: " + width.out + "x" + height.out + "%N")
				print ("Controls: WASD=move, Arrows=look, P=pause, F12=screenshot, ESC=exit%N%N")
				render_loop
				cleanup
			else
				print ("ERROR: GPU initialization failed%N")
			end
		end

	stop do running := False end

feature -- Constants

	Default_shader: STRING = "sdf_buffer_output.spv"
			-- Default shader used when no custom shader specified.

feature {NONE} -- Implementation

	running, screenshot_pending: BOOLEAN
	screenshot_path: STRING

	vk: detachable SIMPLE_VULKAN
	ctx: detachable VULKAN_CONTEXT
	shader: detachable VULKAN_SHADER
	pipeline: detachable VULKAN_PIPELINE
	output_buffer, params_buffer: detachable VULKAN_BUFFER
	mfb: detachable SIMPLE_MINIFB
	window: detachable MINIFB_WINDOW
	display_buffer: detachable MINIFB_BUFFER

	initialize (a_title: STRING; a_w, a_h: INTEGER; a_shader: STRING)
		local
			l_vk: SIMPLE_VULKAN; l_ctx: VULKAN_CONTEXT; l_sh: VULKAN_SHADER
			l_pipe: VULKAN_PIPELINE; l_out, l_par: VULKAN_BUFFER
			l_mfb: SIMPLE_MINIFB; l_win: MINIFB_WINDOW; l_buf: MINIFB_BUFFER
		do
			title := a_title; width := a_w; height := a_h; is_ready := False
			camera_x := 0; camera_y := 2; camera_z := 8; camera_pitch := -0.1
			move_speed := 0.3; look_speed := 0.03; time_scale := 1.0
			screenshot_path := ""

			create l_vk; vk := l_vk; l_ctx := l_vk.create_context; ctx := l_ctx
			if l_ctx.is_valid then
				l_sh := l_vk.load_shader (l_ctx, shader_directory + a_shader); shader := l_sh
				if l_sh.is_valid then
					l_pipe := l_vk.create_pipeline (l_ctx, l_sh); pipeline := l_pipe
					if l_pipe.is_valid then
						l_out := l_vk.create_buffer (l_ctx, (a_w * a_h * 4).to_integer_64, l_vk.Buffer_storage | l_vk.Buffer_transfer)
						l_par := l_vk.create_buffer (l_ctx, 32, l_vk.Buffer_storage)
						output_buffer := l_out; params_buffer := l_par
						if l_out.is_valid and l_par.is_valid then
							l_pipe.bind_buffer (0, l_out).do_nothing
							l_pipe.bind_buffer (1, l_par).do_nothing
							create l_mfb; l_win := l_mfb.open (a_title + " - " + l_ctx.device_name, a_w, a_h)
							l_buf := l_mfb.buffer (a_w, a_h)
							mfb := l_mfb; window := l_win; display_buffer := l_buf
							is_ready := True
						end
					end
				else
					print ("Shader not found: " + shader_directory + a_shader + "%N")
				end
			end
		end

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

	render_loop
		local
			params, pixels: MANAGED_POINTER
			fps_count: INTEGER; fps_time, dt: REAL
			lw: MINIFB_WINDOW; lb: MINIFB_BUFFER; lc: VULKAN_CONTEXT
			lp: VULKAN_PIPELINE; lo, lpa: VULKAN_BUFFER
			m: DOUBLE_MATH
		do
			if attached window as w and attached display_buffer as b and attached ctx as c and
			   attached pipeline as p and attached output_buffer as ob and attached params_buffer as pb then
				lw := w; lb := b; lc := c; lp := p; lo := ob; lpa := pb
				create params.make (32); create pixels.make (width * height * 4); create m
				running := True; time := 0; real_time := 0; fps_time := 0; dt := 0.016

				from until not running or lw.should_close loop
					handle_input (lw)

					-- Orbit camera
					if orbit_mode then
						camera_x := orbit_center_x + (m.cosine (real_time * orbit_speed) * orbit_radius).truncated_to_real
						camera_z := orbit_center_z + (m.sine (real_time * orbit_speed) * orbit_radius).truncated_to_real
						camera_y := orbit_center_y + orbit_radius * 0.3
						look_at (orbit_center_x, orbit_center_y, orbit_center_z)
					end

					real_time := real_time + dt
					if not is_paused then time := time + dt * time_scale end
					if attached on_frame as cb then cb.call ([time]) end

					params.put_real_32 (camera_x, 0); params.put_real_32 (camera_y, 4)
					params.put_real_32 (camera_z, 8); params.put_real_32 (camera_yaw, 12)
					params.put_real_32 (camera_pitch, 16); params.put_real_32 (time, 20)
					params.put_natural_32 (width.to_natural_32, 24); params.put_natural_32 (height.to_natural_32, 28)

					lpa.upload (params.item, 32, 0).do_nothing
					lp.dispatch (lc, (width + 15) // 16, (height + 15) // 16, 1).do_nothing
					lp.wait_idle (lc)
					lo.download (pixels.item, (width * height * 4).to_integer_64, 0).do_nothing

					if screenshot_pending then
						save_bmp (pixels, screenshot_path); screenshot_pending := False
						print ("Saved: " + screenshot_path + "%N")
					end

					lb.copy_from (pixels.item, width * height * 4); lw.update (lb).do_nothing

					frame_count := frame_count + 1; fps_count := fps_count + 1; fps_time := fps_time + dt
					if fps_time >= 1.0 then
						fps := fps_count; print ("FPS: " + fps.out + "%R"); fps_count := 0; fps_time := 0
					end
					if lw.is_key_down (lw.Key_escape) then running := False end
				end
				print ("%N"); lw.close
			end
		end

	handle_input (w: MINIFB_WINDOW)
		local
			cy, sy: REAL_64; m: DOUBLE_MATH
		do
			create m; cy := m.cosine (camera_yaw); sy := m.sine (camera_yaw)
			if not orbit_mode then
				if w.is_key_down (w.Key_w) then camera_x := camera_x - (sy * move_speed).truncated_to_real; camera_z := camera_z - (cy * move_speed).truncated_to_real end
				if w.is_key_down (w.Key_s) then camera_x := camera_x + (sy * move_speed).truncated_to_real; camera_z := camera_z + (cy * move_speed).truncated_to_real end
				if w.is_key_down (w.Key_a) then camera_x := camera_x - (cy * move_speed).truncated_to_real; camera_z := camera_z + (sy * move_speed).truncated_to_real end
				if w.is_key_down (w.Key_d) then camera_x := camera_x + (cy * move_speed).truncated_to_real; camera_z := camera_z - (sy * move_speed).truncated_to_real end
				if w.is_key_down (w.Key_space) then camera_y := camera_y + move_speed end
				if w.is_key_down (w.Key_left_control) or w.is_key_down (w.Key_right_control) then camera_y := camera_y - move_speed end
				if w.is_key_down (w.Key_left) then camera_yaw := camera_yaw - look_speed end
				if w.is_key_down (w.Key_right) then camera_yaw := camera_yaw + look_speed end
				if w.is_key_down (w.Key_up) then camera_pitch := (camera_pitch + look_speed).min (1.5) end
				if w.is_key_down (w.Key_down) then camera_pitch := (camera_pitch - look_speed).max (-1.5) end
			end
			key_toggle (w, 80, agent toggle_pause)  -- P
			key_toggle (w, 301, agent auto_screenshot)  -- F12
		end

	key_states: HASH_TABLE [BOOLEAN, INTEGER] once create Result.make (10) end

	key_toggle (w: MINIFB_WINDOW; k: INTEGER; act: PROCEDURE)
		local
			cur, was: BOOLEAN
		do
			cur := w.is_key_down (k); was := key_states.has (k) and then key_states [k]
			if cur and not was then act.call ([]) end
			key_states.force (cur, k)
		end

	auto_screenshot do screenshot ("screenshot_" + pad (frame_count, 6) + ".bmp") end

	pad (n, w: INTEGER): STRING
		do
			Result := n.out
			from until Result.count >= w loop Result.prepend ("0") end
		end

	save_bmp (pix: MANAGED_POINTER; path: STRING)
		local
			f: RAW_FILE; h: MANAGED_POINTER
			rs, pd, y, x, off: INTEGER
		do
			rs := width * 3; pd := (4 - (rs \\ 4)) \\ 4; rs := rs + pd
			create h.make (54)
			h.put_natural_8 (0x42, 0); h.put_natural_8 (0x4D, 1)
			h.put_natural_32_le ((54 + rs * height).to_natural_32, 2)
			h.put_natural_32_le (0, 6); h.put_natural_32_le (54, 10)
			h.put_natural_32_le (40, 14); h.put_integer_32_le (width, 18)
			h.put_integer_32_le (-height, 22); h.put_natural_16_le (1, 26)
			h.put_natural_16_le (24, 28); h.put_natural_32_le (0, 30)
			h.put_natural_32_le ((rs * height).to_natural_32, 34)
			h.put_natural_32_le (2835, 38); h.put_natural_32_le (2835, 42)
			h.put_natural_32_le (0, 46); h.put_natural_32_le (0, 50)

			create f.make_create_read_write (path)
			f.put_managed_pointer (h, 0, 54)
			from y := 0 until y >= height loop
				from x := 0 until x >= width loop
					off := (y * width + x) * 4
					f.put_natural_8 (pix.read_natural_8 (off)); f.put_natural_8 (pix.read_natural_8 (off + 1)); f.put_natural_8 (pix.read_natural_8 (off + 2))
					x := x + 1
				end
				from x := 0 until x >= pd loop f.put_natural_8 (0); x := x + 1 end
				y := y + 1
			end
			f.close
		end

	cleanup
		do
			if attached output_buffer as b then b.dispose end
			if attached params_buffer as b then b.dispose end
			if attached pipeline as p then p.dispose end
			if attached shader as s then s.dispose end
			if attached ctx as c then c.dispose end
		end

invariant
	valid_title: title /= Void
	valid_dimensions: width > 0 and height > 0

end
