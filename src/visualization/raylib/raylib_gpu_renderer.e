note
	description: "[
		GPU-accelerated SDF ray marching renderer.

		Uses GLSL fragment shaders to perform ray marching entirely on the GPU,
		achieving 60+ FPS at 4K resolution on modern graphics cards.

		Usage:
			local
				gpu: RAYLIB_GPU_RENDERER
			do
				create gpu.make ("shaders/sdf_raymarcher.frag")
				if gpu.is_ready then
					gpu.set_resolution (1920, 1080)
					-- In render loop:
					gpu.set_camera (cam_pos.x, cam_pos.y, cam_pos.z, yaw, pitch)
					gpu.render (1920, 1080)
				end
				gpu.dispose
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	RAYLIB_GPU_RENDERER

create
	make

feature {NONE} -- Initialization

	make (a_shader_path: STRING)
			-- Load GPU shader from path.
		require
			path_attached: a_shader_path /= Void
			path_not_empty: not a_shader_path.is_empty
		local
			l_c_path: C_STRING
		do
			create l_c_path.make (a_shader_path)
			is_ready := c_load_sdf_shader (l_c_path.item) /= 0
		end

feature -- Status

	is_ready: BOOLEAN
			-- Is the shader loaded and ready for rendering?

feature -- Camera

	set_camera (a_x, a_y, a_z: REAL_64; a_yaw, a_pitch: REAL_64)
			-- Set camera position and orientation.
		require
			shader_ready: is_ready
		do
			c_set_shader_camera (
				a_x.truncated_to_real,
				a_y.truncated_to_real,
				a_z.truncated_to_real,
				a_yaw.truncated_to_real,
				a_pitch.truncated_to_real
			)
		end

	set_camera_vec3 (a_pos: SDF_VEC3; a_yaw, a_pitch: REAL_64)
			-- Set camera position from SDF_VEC3 and orientation.
		require
			shader_ready: is_ready
			pos_attached: a_pos /= Void
		do
			set_camera (a_pos.x, a_pos.y, a_pos.z, a_yaw, a_pitch)
		end

feature -- Resolution

	set_resolution (a_width, a_height: INTEGER)
			-- Set rendering resolution.
		require
			shader_ready: is_ready
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			c_set_shader_resolution (a_width.to_real, a_height.to_real)
		end

feature -- Time (for animations)

	set_time (a_time: REAL_64)
			-- Set shader time uniform for animations.
		require
			shader_ready: is_ready
		do
			c_set_shader_time (a_time.truncated_to_real)
		end

feature -- Rendering

	render (a_width, a_height: INTEGER)
			-- Render SDF scene using GPU shader.
			-- Call between begin_drawing/end_drawing.
		require
			shader_ready: is_ready
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			c_render_sdf_gpu (a_width, a_height)
		end

feature -- Memory Management

	dispose
			-- Unload shader resources.
		do
			if is_ready then
				c_unload_sdf_shader
				is_ready := False
			end
		ensure
			not_ready: not is_ready
		end

feature {NONE} -- C Externals

	c_load_sdf_shader (a_path: POINTER): INTEGER
		external
			"C inline use %"simple_raylib.h%""
		alias
			"return srl_load_sdf_shader((const char*)$a_path);"
		end

	c_unload_sdf_shader
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_unload_sdf_shader();"
		end

	c_set_shader_resolution (a_w, a_h: REAL_32)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_set_shader_resolution((float)$a_w, (float)$a_h);"
		end

	c_set_shader_camera (a_x, a_y, a_z, a_yaw, a_pitch: REAL_32)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_set_shader_camera((float)$a_x, (float)$a_y, (float)$a_z, (float)$a_yaw, (float)$a_pitch);"
		end

	c_set_shader_time (a_t: REAL_32)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_set_shader_time((float)$a_t);"
		end

	c_render_sdf_gpu (a_w, a_h: INTEGER)
		external
			"C inline use %"simple_raylib.h%""
		alias
			"srl_render_sdf_gpu((int)$a_w, (int)$a_h);"
		end

end
