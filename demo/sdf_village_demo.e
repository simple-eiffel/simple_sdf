note
	description: "[
		Medieval Village Demo - GPU-accelerated SDF ray marching.

		A procedural medieval European village scene featuring:
		- Half-timbered houses with pitched roofs
		- Stone church with steeple
		- Watchtower
		- Village well
		- Trees
		- Cobblestone ground
		- Perimeter wall

		Controls:
			WASD - Move camera
			Space/Ctrl - Up/Down
			Arrow keys - Look around
			ESC - Exit
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_VILLAGE_DEMO

create
	make

feature {NONE} -- Initialization

	make
			-- Run the Medieval Village demo.
		do
			print ("Medieval Village Demo%N")
			print ("=====================%N%N")
			print ("A procedural medieval European village%N")
			print ("rendered in real-time using GPU ray marching.%N%N")

			initialize_vulkan
			if vulkan_ready and attached ctx as l_ctx then
				print ("Vulkan initialized: " + l_ctx.device_name + "%N")
				print ("Resolution: " + width.out + "x" + height.out + "%N%N")
				print ("Controls:%N")
				print ("  WASD - Move camera%N")
				print ("  Space/Ctrl - Up/Down%N")
				print ("  Arrow keys - Look around%N")
				print ("  ESC - Exit%N%N")
				run_demo
				cleanup
			else
				print ("ERROR: Vulkan initialization failed%N")
				print ("Ensure you have a Vulkan-compatible GPU and drivers.%N")
			end
		end

feature {NONE} -- Vulkan

	vk: detachable SIMPLE_VULKAN
	ctx: detachable VULKAN_CONTEXT
	shader: detachable VULKAN_SHADER
	pipeline: detachable VULKAN_PIPELINE
	output_buffer: detachable VULKAN_BUFFER
	params_buffer: detachable VULKAN_BUFFER

	vulkan_ready: BOOLEAN

	width: INTEGER = 1920
	height: INTEGER = 1080

	initialize_vulkan
			-- Set up Vulkan context, shader, and pipeline.
		local
			shader_path: STRING
			l_vk: SIMPLE_VULKAN
			l_ctx: VULKAN_CONTEXT
			l_shader: VULKAN_SHADER
			l_pipeline: VULKAN_PIPELINE
			l_output_buf: VULKAN_BUFFER
			l_params_buf: VULKAN_BUFFER
		do
			vulkan_ready := False

			create l_vk
			vk := l_vk
			l_ctx := l_vk.create_context
			ctx := l_ctx

			if l_ctx.is_valid then
				-- Load the medieval village compute shader
				shader_path := shader_directory + "medieval_village.spv"
				l_shader := l_vk.load_shader (l_ctx, shader_path)
				shader := l_shader

				if l_shader.is_valid then
					-- Create pipeline
					l_pipeline := l_vk.create_pipeline (l_ctx, l_shader)
					pipeline := l_pipeline

					if l_pipeline.is_valid then
						-- Create output buffer (RGBA, 4 bytes per pixel)
						l_output_buf := l_vk.create_buffer (l_ctx,
							(width * height * 4).to_integer_64,
							l_vk.Buffer_storage | l_vk.Buffer_transfer)
						output_buffer := l_output_buf

						-- Create params buffer (8 floats = 32 bytes)
						l_params_buf := l_vk.create_buffer (l_ctx, 32, l_vk.Buffer_storage)
						params_buffer := l_params_buf

						if l_output_buf.is_valid and l_params_buf.is_valid then
							-- Bind buffers to pipeline
							l_pipeline.bind_buffer (0, l_output_buf).do_nothing
							l_pipeline.bind_buffer (1, l_params_buf).do_nothing
							vulkan_ready := True
						end
					end
				else
					print ("Shader not found: " + shader_path + "%N")
					print ("Ensure medieval_village.spv is in the shaders directory.%N")
				end
			end
		end

	shader_directory: STRING
			-- Directory containing shaders
		local
			env: EXECUTION_ENVIRONMENT
			simple_eiffel: detachable STRING_32
		do
			create env
			simple_eiffel := env.item ("SIMPLE_EIFFEL")
			if attached simple_eiffel as se then
				Result := se.to_string_8 + "/simple_vulkan/shaders/"
			else
				-- Fallback to relative path
				Result := "shaders/"
			end
		end

feature {NONE} -- MiniFB Display

	mfb: detachable SIMPLE_MINIFB
	window: detachable MINIFB_WINDOW
	display_buffer: detachable MINIFB_BUFFER

	initialize_display
			-- Set up MiniFB window.
		local
			l_mfb: SIMPLE_MINIFB
			l_window: MINIFB_WINDOW
			l_buffer: MINIFB_BUFFER
			l_title: STRING
		do
			create l_mfb
			if attached ctx as l_ctx then
				l_title := "Medieval Village - " + l_ctx.device_name
			else
				l_title := "Medieval Village Demo"
			end
			l_window := l_mfb.open (l_title, width, height)
			l_buffer := l_mfb.buffer (width, height)

			mfb := l_mfb
			window := l_window
			display_buffer := l_buffer
		end

feature {NONE} -- Camera

	-- Starting position: outside village looking in
	cam_x: REAL = 0.0
	cam_y: REAL = 5.0
	cam_z: REAL = 35.0
	cam_yaw: REAL = 0.0
	cam_pitch: REAL = -0.1

	move_speed: REAL = 0.3
	look_speed: REAL = 0.03

	current_cam_x: REAL
	current_cam_y: REAL
	current_cam_z: REAL
	current_yaw: REAL
	current_pitch: REAL

feature {NONE} -- Demo Loop

	run_demo
			-- Main rendering loop.
		local
			params: MANAGED_POINTER
			pixels: MANAGED_POINTER
			running: BOOLEAN
			time: REAL
			frame_count: INTEGER
			fps_time: REAL
			l_window: MINIFB_WINDOW
			l_buffer: MINIFB_BUFFER
			l_ctx: VULKAN_CONTEXT
			l_pipeline: VULKAN_PIPELINE
			l_output_buf: VULKAN_BUFFER
			l_params_buf: VULKAN_BUFFER
		do
			initialize_display

			if attached window as w and attached display_buffer as b and
			   attached ctx as c and attached pipeline as p and
			   attached output_buffer as ob and attached params_buffer as pb then
				l_window := w
				l_buffer := b
				l_ctx := c
				l_pipeline := p
				l_output_buf := ob
				l_params_buf := pb

				-- Initialize camera
				current_cam_x := cam_x
				current_cam_y := cam_y
				current_cam_z := cam_z
				current_yaw := cam_yaw
				current_pitch := cam_pitch

				-- Allocate param buffer
				create params.make (32)
				create pixels.make (width * height * 4)

				running := True
				time := 0.0
				fps_time := 0.0
				frame_count := 0

				from
				until not running or l_window.should_close
				loop
					-- Handle input
					handle_input (l_window)

					-- Update camera params
					params.put_real_32 (current_cam_x, 0)
					params.put_real_32 (current_cam_y, 4)
					params.put_real_32 (current_cam_z, 8)
					params.put_real_32 (current_yaw, 12)
					params.put_real_32 (current_pitch, 16)
					params.put_real_32 (time, 20)
					params.put_natural_32 (width.to_natural_32, 24)
					params.put_natural_32 (height.to_natural_32, 28)

					-- Upload params
					l_params_buf.upload (params.item, 32, 0).do_nothing

					-- Dispatch compute shader
					-- 16x16 workgroups, so divide dimensions
					l_pipeline.dispatch (l_ctx, (width + 15) // 16, (height + 15) // 16, 1).do_nothing

					-- Wait for completion
					l_pipeline.wait_idle (l_ctx)

					-- Download result
					l_output_buf.download (pixels.item, (width * height * 4).to_integer_64, 0).do_nothing

					-- Copy to display buffer (bulk memcpy)
					l_buffer.copy_from (pixels.item, width * height * 4)

					-- Update display
					l_window.update (l_buffer).do_nothing

					-- FPS counter
					frame_count := frame_count + 1
					time := time + 0.016
					fps_time := fps_time + 0.016

					if fps_time >= 1.0 then
						print ("FPS: " + frame_count.out + "%R")
						frame_count := 0
						fps_time := 0.0
					end

					-- Check for ESC
					if l_window.is_key_down (l_window.Key_escape) then
						running := False
					end
				end

				print ("%N")
				l_window.close
			end
		end

	handle_input (a_window: MINIFB_WINDOW)
			-- Process keyboard input.
		local
			cy, sy: REAL_64
			math: DOUBLE_MATH
		do
			-- Calculate movement direction
			create math
			cy := math.cosine (current_yaw)
			sy := math.sine (current_yaw)

			-- Forward/backward (W/S)
			if a_window.is_key_down (a_window.Key_w) then
				current_cam_x := current_cam_x - (sy * move_speed).truncated_to_real
				current_cam_z := current_cam_z - (cy * move_speed).truncated_to_real
			end
			if a_window.is_key_down (a_window.Key_s) then
				current_cam_x := current_cam_x + (sy * move_speed).truncated_to_real
				current_cam_z := current_cam_z + (cy * move_speed).truncated_to_real
			end

			-- Strafe (A/D)
			if a_window.is_key_down (a_window.Key_a) then
				current_cam_x := current_cam_x - (cy * move_speed).truncated_to_real
				current_cam_z := current_cam_z + (sy * move_speed).truncated_to_real
			end
			if a_window.is_key_down (a_window.Key_d) then
				current_cam_x := current_cam_x + (cy * move_speed).truncated_to_real
				current_cam_z := current_cam_z - (sy * move_speed).truncated_to_real
			end

			-- Up/down (Space/Ctrl)
			if a_window.is_key_down (a_window.Key_space) then
				current_cam_y := current_cam_y + move_speed
			end
			if a_window.is_key_down (a_window.Key_left_control) or a_window.is_key_down (a_window.Key_right_control) then
				current_cam_y := current_cam_y - move_speed
			end

			-- Look (Arrow keys)
			if a_window.is_key_down (a_window.Key_left) then
				current_yaw := current_yaw - look_speed
			end
			if a_window.is_key_down (a_window.Key_right) then
				current_yaw := current_yaw + look_speed
			end
			if a_window.is_key_down (a_window.Key_up) then
				current_pitch := current_pitch + look_speed
			end
			if a_window.is_key_down (a_window.Key_down) then
				current_pitch := current_pitch - look_speed
			end

			-- Clamp pitch
			if current_pitch > 1.5 then current_pitch := 1.5 end
			if current_pitch < -1.5 then current_pitch := -1.5 end
		end

feature {NONE} -- Cleanup

	cleanup
			-- Release all resources.
		do
			if attached output_buffer as b then b.dispose end
			if attached params_buffer as b then b.dispose end
			if attached pipeline as p then p.dispose end
			if attached shader as s then s.dispose end
			if attached ctx as c then c.dispose end
		end

end
