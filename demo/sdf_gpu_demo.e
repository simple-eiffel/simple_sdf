note
	description: "[
		SDF GPU Ray Marching Demo using raylib shaders.

		Demonstrates GPU-accelerated SDF rendering at 4K resolution.
		All ray marching happens on the GPU via fragment shader.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_GPU_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the GPU demo.
		do
			create sdf
			create rl
			run_gpu_render_loop
		end

feature {NONE} -- Render Loop

	run_gpu_render_loop
			-- Main GPU render loop.
		local
			l_gpu: RAYLIB_GPU_RENDERER
		do
			rl.init_window (Window_width, Window_height, "SDF GPU Ray Marching - 4K Demo")
			rl.set_target_fps (60)

			-- Load GPU shader
			create l_gpu.make ("shaders/sdf_raymarcher.frag")

			if l_gpu.is_ready then
				print ("GPU shader loaded successfully!%N")
				l_gpu.set_resolution (Window_width, Window_height)

				-- Initialize camera
				camera_x := 0.0
				camera_y := 1.0
				camera_z := 5.0
				camera_yaw := 0.0
				camera_pitch := -0.1

				from until rl.should_close loop
					-- Handle input
					handle_input

					-- Update shader uniforms
					l_gpu.set_camera (camera_x, camera_y, camera_z, camera_yaw, camera_pitch)

					-- Render
					rl.begin_drawing
					rl.clear (25, 25, 40)
					l_gpu.render (Window_width, Window_height)
					rl.draw_fps (10, 10)
					rl.draw_text ("GPU MODE - WASD: Move, Arrows: Look, ESC: Exit", 10, Window_height - 30, 20, 200, 200, 200)
					rl.end_drawing
				end

				l_gpu.dispose
			else
				print ("ERROR: Failed to load GPU shader!%N")
			end

			rl.close_window
			print ("GPU Demo finished.%N")
		end

feature {NONE} -- Input Handling

	handle_input
			-- Process keyboard input.
		local
			l_move_speed: REAL_64
			l_fx, l_fz, l_rx, l_rz: REAL_64
		do
			l_move_speed := 0.1

			-- Calculate forward and right vectors
			l_fx := -{DOUBLE_MATH}.sine (camera_yaw)
			l_fz := -{DOUBLE_MATH}.cosine (camera_yaw)
			l_rx := {DOUBLE_MATH}.cosine (camera_yaw)
			l_rz := -{DOUBLE_MATH}.sine (camera_yaw)

			-- WASD movement
			if rl.is_key_down (rl.Key_w) then
				camera_x := camera_x + l_fx * l_move_speed
				camera_z := camera_z + l_fz * l_move_speed
			end
			if rl.is_key_down (rl.Key_s) then
				camera_x := camera_x - l_fx * l_move_speed
				camera_z := camera_z - l_fz * l_move_speed
			end
			if rl.is_key_down (rl.Key_a) then
				camera_x := camera_x - l_rx * l_move_speed
				camera_z := camera_z - l_rz * l_move_speed
			end
			if rl.is_key_down (rl.Key_d) then
				camera_x := camera_x + l_rx * l_move_speed
				camera_z := camera_z + l_rz * l_move_speed
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
				camera_y := camera_y + l_move_speed
			end
			if rl.is_key_down (rl.Key_q) then
				camera_y := camera_y - l_move_speed
			end
		end

feature {NONE} -- Implementation

	sdf: SIMPLE_SDF
	rl: SIMPLE_RAYLIB

	camera_x, camera_y, camera_z: REAL_64
	camera_yaw, camera_pitch: REAL_64

feature {NONE} -- Constants

	Window_width: INTEGER = 1920
	Window_height: INTEGER = 1080

end
