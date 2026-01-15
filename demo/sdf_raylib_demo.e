note
	description: "[
		SDF Ray Marching Visualization Demo using raylib.

		Demonstrates simple_sdf capabilities with hardware-accelerated rendering.
		CPU ray marching to buffer, GPU texture scaling for display.

		Features:
		- Interactive camera (WASD + mouse)
		- Multiple SDF primitives
		- Boolean operations
		- Smooth blending
		- GPU-accelerated texture scaling
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_RAYLIB_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the demo.
		do
			create sdf
			create rl
			setup_scene
			run_render_loop
		end

feature {NONE} -- Scene Setup

	setup_scene
			-- Create SDF scene with primitives.
		local
			l_sphere: SDF_SPHERE
			l_box: SDF_BOX
			l_ground: SDF_PLANE
		do
			create scene.make

			-- Main sphere at origin
			l_sphere := sdf.sphere (1.0)
			scene.add (l_sphere).do_nothing

			-- Cube to the right, smooth blended
			l_box := sdf.cube (0.8)
			l_box.set_position (sdf.vec3 (2.0, 0.0, 0.0)).do_nothing
			scene.add_smooth_union (l_box, 0.3).do_nothing

			-- Ground plane
			l_ground := sdf.ground_plane (-1.5)
			scene.add (l_ground).do_nothing

			-- Ray marcher with quality settings
			ray_marcher := sdf.ray_marcher_custom (64, 50.0, 0.001)

			-- Camera setup
			camera_origin := sdf.vec3 (0.0, 1.0, 5.0)
			camera_yaw := 0.0
			camera_pitch := -0.1
		end

feature {NONE} -- Render Loop

	run_render_loop
			-- Main render loop.
		local
			l_buf: RAYLIB_BUFFER
		do
			rl.init_window (Window_width, Window_height, "SDF Ray Marching Demo - raylib")
			l_buf := rl.buffer (Render_width, Render_height)
			rl.set_target_fps (60)

			from until rl.should_close loop
				-- Handle input
				handle_input

				-- Render scene to buffer using fast C ray marcher
				c_render_sdf_scene (l_buf.handle, Render_width, Render_height,
					camera_origin.x.truncated_to_real, camera_origin.y.truncated_to_real, camera_origin.z.truncated_to_real,
					camera_yaw.truncated_to_real, camera_pitch.truncated_to_real)

				-- Upload to GPU and display
				l_buf.update_texture

				rl.begin_drawing
				rl.clear (25, 25, 40)
				l_buf.draw_scaled (0, 0, Window_width, Window_height)
				rl.draw_fps (10, 10)
				rl.draw_text ("WASD: Move, Arrows: Look, Space/Q: Up/Down, ESC: Exit", 10, Window_height - 30, 20, 200, 200, 200)
				rl.end_drawing
			end

			-- Cleanup
			l_buf.dispose
			rl.close_window

			print ("Demo finished.%N")
		end

feature {NONE} -- Input Handling

	handle_input
			-- Process keyboard input.
		local
			l_move_speed: REAL_64
			l_forward, l_right: SDF_VEC3
		do
			l_move_speed := 0.1

			-- Calculate forward and right vectors based on yaw
			l_forward := sdf.vec3 (
				-{DOUBLE_MATH}.sine (camera_yaw),
				0.0,
				-{DOUBLE_MATH}.cosine (camera_yaw)
			)
			l_right := sdf.vec3 (
				{DOUBLE_MATH}.cosine (camera_yaw),
				0.0,
				-{DOUBLE_MATH}.sine (camera_yaw)
			)

			-- WASD movement
			if rl.is_key_down (rl.Key_w) then
				camera_origin := camera_origin + (l_forward * l_move_speed)
			end
			if rl.is_key_down (rl.Key_s) then
				camera_origin := camera_origin - (l_forward * l_move_speed)
			end
			if rl.is_key_down (rl.Key_a) then
				camera_origin := camera_origin - (l_right * l_move_speed)
			end
			if rl.is_key_down (rl.Key_d) then
				camera_origin := camera_origin + (l_right * l_move_speed)
			end

			-- Arrow keys for rotation
			if rl.is_key_down (rl.Key_left) then
				camera_yaw := camera_yaw - 0.03
			end
			if rl.is_key_down (rl.Key_right) then
				camera_yaw := camera_yaw + 0.03
			end
			if rl.is_key_down (rl.Key_up) then
				camera_pitch := (camera_pitch + 0.03).min (1.5)
			end
			if rl.is_key_down (rl.Key_down) then
				camera_pitch := (camera_pitch - 0.03).max (-1.5)
			end

			-- Space/Q for up/down
			if rl.is_key_down (rl.Key_space) then
				camera_origin := sdf.vec3 (camera_origin.x, camera_origin.y + l_move_speed, camera_origin.z)
			end
			if rl.is_key_down (rl.Key_q) then
				camera_origin := sdf.vec3 (camera_origin.x, camera_origin.y - l_move_speed, camera_origin.z)
			end
		end

feature {NONE} -- Rendering

	render_scene (a_buf: RAYLIB_BUFFER)
			-- Render SDF scene to buffer via ray marching.
		local
			px, py: INTEGER
			l_u, l_v: REAL_64
			l_ray_dir: SDF_VEC3
			l_hit: SDF_RAY_HIT
			l_r, l_g, l_b: NATURAL_8
			l_aspect: REAL_64
			l_fov: REAL_64
		do
			l_aspect := Render_width / Render_height
			l_fov := 1.0  -- Field of view factor

			from py := 0 until py >= Render_height loop
				from px := 0 until px >= Render_width loop
					-- Normalized screen coordinates (-1 to 1)
					l_u := ((px / Render_width) * 2.0 - 1.0) * l_aspect * l_fov
					l_v := (1.0 - (py / Render_height) * 2.0) * l_fov

					-- Calculate ray direction with camera rotation
					l_ray_dir := compute_ray_direction (l_u, l_v)

					-- Ray march
					l_hit := ray_marcher.march (scene, camera_origin, l_ray_dir)

					-- Shade pixel
					if l_hit.is_hit then
						shade_hit (l_hit)
						l_r := last_r
						l_g := last_g
						l_b := last_b
					else
						shade_background (l_v)
						l_r := last_r
						l_g := last_g
						l_b := last_b
					end

					a_buf.set_pixel (px, py, l_r, l_g, l_b)
					px := px + 1
				end
				py := py + 1
			end
		end

	compute_ray_direction (a_u, a_v: REAL_64): SDF_VEC3
			-- Compute ray direction for screen coordinates with camera rotation.
		local
			l_dir: SDF_VEC3
			l_cos_yaw, l_sin_yaw: REAL_64
			l_cos_pitch, l_sin_pitch: REAL_64
			l_x, l_y, l_z: REAL_64
		do
			l_cos_yaw := {DOUBLE_MATH}.cosine (camera_yaw)
			l_sin_yaw := {DOUBLE_MATH}.sine (camera_yaw)
			l_cos_pitch := {DOUBLE_MATH}.cosine (camera_pitch)
			l_sin_pitch := {DOUBLE_MATH}.sine (camera_pitch)

			-- Start with forward direction
			l_x := a_u
			l_y := a_v
			l_z := -1.0

			-- Rotate by pitch (around X)
			l_y := a_v * l_cos_pitch - (-1.0) * l_sin_pitch
			l_z := a_v * l_sin_pitch + (-1.0) * l_cos_pitch

			-- Rotate by yaw (around Y)
			create l_dir.make (
				l_x * l_cos_yaw + l_z * l_sin_yaw,
				l_y,
				-l_x * l_sin_yaw + l_z * l_cos_yaw
			)

			Result := l_dir.normalized
		end

	shade_hit (a_hit: SDF_RAY_HIT)
			-- Shade a ray hit with simple lighting.
			-- Sets last_r, last_g, last_b.
		local
			l_light_dir: SDF_VEC3
			l_diffuse: REAL_64
			l_ambient: REAL_64
			l_intensity: REAL_64
		do
			-- Light direction (from upper right)
			l_light_dir := sdf.vec3 (0.5, 0.8, 0.3).normalized

			-- Diffuse lighting
			l_diffuse := (a_hit.normal.dot (l_light_dir)).max (0.0)
			l_ambient := 0.15
			l_intensity := l_ambient + l_diffuse * 0.85

			-- Base color (warm orange)
			last_r := (220 * l_intensity).truncated_to_integer.min (255).max (0).as_natural_8
			last_g := (120 * l_intensity).truncated_to_integer.min (255).max (0).as_natural_8
			last_b := (80 * l_intensity).truncated_to_integer.min (255).max (0).as_natural_8
		end

	shade_background (a_v: REAL_64)
			-- Shade background with vertical gradient.
			-- Sets last_r, last_g, last_b.
		local
			l_t: REAL_64
		do
			-- Gradient from dark blue (bottom) to slightly lighter (top)
			l_t := (a_v + 1.0) / 2.0  -- 0 at bottom, 1 at top

			last_r := (25 + (l_t * 15)).truncated_to_integer.as_natural_8
			last_g := (25 + (l_t * 20)).truncated_to_integer.as_natural_8
			last_b := (40 + (l_t * 30)).truncated_to_integer.as_natural_8
		end

	last_r, last_g, last_b: NATURAL_8
			-- Last computed color components

feature {NONE} -- Implementation

	sdf: SIMPLE_SDF
			-- SDF facade

	rl: SIMPLE_RAYLIB
			-- raylib facade

	scene: SDF_SCENE
			-- Current SDF scene

	ray_marcher: SDF_RAY_MARCHER
			-- Ray marcher for rendering

	camera_origin: SDF_VEC3
			-- Camera position

	camera_yaw: REAL_64
			-- Camera horizontal rotation (radians)

	camera_pitch: REAL_64
			-- Camera vertical rotation (radians)

feature {NONE} -- Constants

	Window_width: INTEGER = 1920
			-- Display window width

	Window_height: INTEGER = 1080
			-- Display window height

	Render_width: INTEGER = 1920
			-- Render buffer width (upscaled to window)

	Render_height: INTEGER = 1080
			-- Render buffer height

feature {NONE} -- C Externals

	c_render_sdf_scene (a_buf: POINTER; a_width, a_height: INTEGER;
			a_cam_x, a_cam_y, a_cam_z, a_cam_yaw, a_cam_pitch: REAL_32)
			-- Fast C-based SDF ray marching (entire render loop in C).
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_render_sdf_scene((void*)$a_buf, (int)$a_width, (int)$a_height, (float)$a_cam_x, (float)$a_cam_y, (float)$a_cam_z, (float)$a_cam_yaw, (float)$a_cam_pitch);"
		end

end
