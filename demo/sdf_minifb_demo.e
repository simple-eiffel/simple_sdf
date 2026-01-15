note
	description: "[
		SDF Ray Marching Visualization Demo using MiniFB.

		Demonstrates simple_sdf capabilities with real-time CPU rendering.
		Features:
		- Interactive camera (WASD + mouse)
		- Multiple SDF primitives
		- Boolean operations
		- Smooth blending
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_MINIFB_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the demo.
		do
			create sdf
			create mfb
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
			ray_marcher := sdf.ray_marcher_custom (64, 50.0, 0.005)

			-- Camera setup
			camera_origin := sdf.vec3 (0.0, 1.0, 5.0)
			camera_yaw := 0.0
			camera_pitch := -0.1
		end

feature {NONE} -- Render Loop

	run_render_loop
			-- Main render loop.
		local
			l_win: MINIFB_WINDOW
			l_buf: MINIFB_BUFFER
			l_state: INTEGER
		do
			l_win := mfb.open ("SDF Ray Marching Demo - MiniFB", Window_width, Window_height)
			l_buf := mfb.buffer (Window_width, Window_height)
			mfb.set_target_fps (30)

			from
				l_state := 0
			until
				l_win.should_close or l_state < 0
			loop
				-- Handle input
				handle_input (l_win)

				-- Render scene
				render_scene (l_buf)

				-- Display
				l_state := l_win.update (l_buf)
				l_win.wait_sync.do_nothing
			end

			-- Cleanup
			l_buf.dispose
			l_win.close

			print ("Demo finished.%N")
		end

feature {NONE} -- Input Handling

	handle_input (a_win: MINIFB_WINDOW)
			-- Process keyboard and mouse input.
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
			if a_win.is_key_down (a_win.Key_w) then
				camera_origin := camera_origin + (l_forward * l_move_speed)
			end
			if a_win.is_key_down (a_win.Key_s) then
				camera_origin := camera_origin - (l_forward * l_move_speed)
			end
			if a_win.is_key_down (a_win.Key_a) then
				camera_origin := camera_origin - (l_right * l_move_speed)
			end
			if a_win.is_key_down (a_win.Key_d) then
				camera_origin := camera_origin + (l_right * l_move_speed)
			end

			-- Arrow keys for rotation
			if a_win.is_key_down (a_win.Key_left) then
				camera_yaw := camera_yaw - 0.03
			end
			if a_win.is_key_down (a_win.Key_right) then
				camera_yaw := camera_yaw + 0.03
			end
			if a_win.is_key_down (a_win.Key_up) then
				camera_pitch := (camera_pitch + 0.03).min (1.5)
			end
			if a_win.is_key_down (a_win.Key_down) then
				camera_pitch := (camera_pitch - 0.03).max (-1.5)
			end

			-- Space/Q for up/down
			if a_win.is_key_down (a_win.Key_space) then
				camera_origin := sdf.vec3 (camera_origin.x, camera_origin.y + l_move_speed, camera_origin.z)
			end
			if a_win.is_key_down (a_win.Key_q) then
				camera_origin := sdf.vec3 (camera_origin.x, camera_origin.y - l_move_speed, camera_origin.z)
			end
		end

feature {NONE} -- Rendering

	render_scene (a_buf: MINIFB_BUFFER)
			-- Render SDF scene to buffer via ray marching.
		local
			px, py: INTEGER
			l_u, l_v: REAL_64
			l_ray_dir: SDF_VEC3
			l_hit: SDF_RAY_HIT
			l_color: NATURAL_32
			l_aspect: REAL_64
			l_fov: REAL_64
		do
			l_aspect := Window_width / Window_height
			l_fov := 1.0  -- Field of view factor

			-- Clear to background
			a_buf.clear (mfb.color_background)

			from py := 0 until py >= Window_height loop
				from px := 0 until px >= Window_width loop
					-- Normalized screen coordinates (-1 to 1)
					l_u := ((px / Window_width) * 2.0 - 1.0) * l_aspect * l_fov
					l_v := (1.0 - (py / Window_height) * 2.0) * l_fov

					-- Calculate ray direction with camera rotation
					l_ray_dir := compute_ray_direction (l_u, l_v)

					-- Ray march
					l_hit := ray_marcher.march (scene, camera_origin, l_ray_dir)

					-- Shade pixel
					if l_hit.is_hit then
						l_color := shade_hit (l_hit)
					else
						l_color := shade_background (l_v)
					end

					a_buf.set_pixel (px, py, l_color)
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

	shade_hit (a_hit: SDF_RAY_HIT): NATURAL_32
			-- Shade a ray hit with simple lighting.
		local
			l_light_dir: SDF_VEC3
			l_diffuse: REAL_64
			l_ambient: REAL_64
			l_intensity: REAL_64
			l_r, l_g, l_b: INTEGER
		do
			-- Light direction (from upper right)
			l_light_dir := sdf.vec3 (0.5, 0.8, 0.3).normalized

			-- Diffuse lighting
			l_diffuse := (a_hit.normal.dot (l_light_dir)).max (0.0)
			l_ambient := 0.15
			l_intensity := l_ambient + l_diffuse * 0.85

			-- Base color (warm orange)
			l_r := (220 * l_intensity).truncated_to_integer.min (255).max (0)
			l_g := (120 * l_intensity).truncated_to_integer.min (255).max (0)
			l_b := (80 * l_intensity).truncated_to_integer.min (255).max (0)

			Result := mfb.rgb (l_r.as_natural_8, l_g.as_natural_8, l_b.as_natural_8)
		end

	shade_background (a_v: REAL_64): NATURAL_32
			-- Shade background with vertical gradient.
		local
			l_t: REAL_64
			l_r, l_g, l_b: INTEGER
		do
			-- Gradient from dark blue (bottom) to slightly lighter (top)
			l_t := (a_v + 1.0) / 2.0  -- 0 at bottom, 1 at top

			l_r := (25 + (l_t * 15)).truncated_to_integer
			l_g := (25 + (l_t * 20)).truncated_to_integer
			l_b := (40 + (l_t * 30)).truncated_to_integer

			Result := mfb.rgb (l_r.as_natural_8, l_g.as_natural_8, l_b.as_natural_8)
		end

feature {NONE} -- Implementation

	sdf: SIMPLE_SDF
			-- SDF facade

	mfb: SIMPLE_MINIFB
			-- MiniFB facade

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

	Window_width: INTEGER = 320
			-- Render width (lower for CPU rendering)

	Window_height: INTEGER = 240
			-- Render height

end
