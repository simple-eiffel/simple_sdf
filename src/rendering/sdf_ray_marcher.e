note
	description: "[
		Ray marcher for SDF rendering.

		Ray marching algorithm:
		1. Start at ray origin
		2. Evaluate SDF distance at current position
		3. If distance < threshold, we hit the surface
		4. Otherwise, march forward by the distance value
		5. Repeat until hit, max distance, or max steps

		Surface normals are computed via numerical gradient.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_RAY_MARCHER

create
	make,
	make_default

feature {NONE} -- Initialization

	make (a_max_steps: INTEGER; a_max_distance, a_surface_threshold: REAL_64)
			-- Create ray marcher with custom settings.
		require
			positive_steps: a_max_steps > 0
			positive_distance: a_max_distance > 0.0
			positive_threshold: a_surface_threshold > 0.0
		do
			max_steps := a_max_steps
			max_distance := a_max_distance
			surface_threshold := a_surface_threshold
			normal_epsilon := 0.0001
		ensure
			max_steps_set: max_steps = a_max_steps
			max_distance_set: max_distance = a_max_distance
			threshold_set: surface_threshold = a_surface_threshold
		end

	make_default
			-- Create ray marcher with default settings.
		do
			max_steps := Default_max_steps
			max_distance := Default_max_distance
			surface_threshold := Default_surface_threshold
			normal_epsilon := 0.0001
		ensure
			default_steps: max_steps = Default_max_steps
			default_distance: max_distance = Default_max_distance
			default_threshold: surface_threshold = Default_surface_threshold
		end

feature -- Access

	max_steps: INTEGER
			-- Maximum number of march steps

	max_distance: REAL_64
			-- Maximum ray travel distance

	surface_threshold: REAL_64
			-- Distance considered "on surface"

	normal_epsilon: REAL_64
			-- Epsilon for normal computation

feature -- Element change

	set_max_steps (a_value: INTEGER): like Current
			-- Set max steps and return self.
		require
			positive: a_value > 0
		do
			max_steps := a_value
			Result := Current
		ensure
			max_steps_set: max_steps = a_value
			result_is_current: Result = Current
		end

	set_max_distance (a_value: REAL_64): like Current
			-- Set max distance and return self.
		require
			positive: a_value > 0.0
		do
			max_distance := a_value
			Result := Current
		ensure
			max_distance_set: max_distance = a_value
			result_is_current: Result = Current
		end

	set_surface_threshold (a_value: REAL_64): like Current
			-- Set surface threshold and return self.
		require
			positive: a_value > 0.0
		do
			surface_threshold := a_value
			Result := Current
		ensure
			threshold_set: surface_threshold = a_value
			result_is_current: Result = Current
		end

	set_normal_epsilon (a_value: REAL_64): like Current
			-- Set epsilon for normal computation.
		require
			positive: a_value > 0.0
		do
			normal_epsilon := a_value
			Result := Current
		ensure
			epsilon_set: normal_epsilon = a_value
			result_is_current: Result = Current
		end

feature -- Ray marching

	march (a_scene: SDF_SCENE; a_origin, a_direction: SDF_VEC3): SDF_RAY_HIT
			-- March ray through scene, return hit info.
		require
			scene_attached: a_scene /= Void
			origin_attached: a_origin /= Void
			direction_attached: a_direction /= Void
			direction_is_unit: a_direction.is_unit_vector
		local
			l_depth: REAL_64
			l_step: INTEGER
			l_point: SDF_VEC3
			l_dist: REAL_64
			l_normal: SDF_VEC3
		do
			from
				l_depth := 0.0
				l_step := 0
			until
				l_step >= max_steps or l_depth >= max_distance
			loop
				l_point := a_origin + (a_direction * l_depth)
				l_dist := a_scene.distance (l_point)

				if l_dist.abs < surface_threshold then
					-- Hit surface
					l_normal := compute_normal (a_scene, l_point)
					create Result.make_hit (l_point, l_depth, l_normal, l_step + 1)
					l_step := max_steps  -- Exit loop
				else
					l_depth := l_depth + l_dist
					l_step := l_step + 1
				end
			end

			if Result = Void then
				-- Ray missed
				create Result.make_miss (l_step)
			end
		ensure
			result_attached: Result /= Void
		end

	march_shape (a_shape: SDF_SHAPE; a_origin, a_direction: SDF_VEC3): SDF_RAY_HIT
			-- March ray against single shape, return hit info.
		require
			shape_attached: a_shape /= Void
			origin_attached: a_origin /= Void
			direction_attached: a_direction /= Void
			direction_is_unit: a_direction.is_unit_vector
		local
			l_depth: REAL_64
			l_step: INTEGER
			l_point: SDF_VEC3
			l_dist: REAL_64
			l_normal: SDF_VEC3
		do
			from
				l_depth := 0.0
				l_step := 0
			until
				l_step >= max_steps or l_depth >= max_distance
			loop
				l_point := a_origin + (a_direction * l_depth)
				l_dist := a_shape.distance (l_point)

				if l_dist.abs < surface_threshold then
					-- Hit surface
					l_normal := compute_normal_shape (a_shape, l_point)
					create Result.make_hit (l_point, l_depth, l_normal, l_step + 1)
					l_step := max_steps  -- Exit loop
				else
					l_depth := l_depth + l_dist
					l_step := l_step + 1
				end
			end

			if Result = Void then
				-- Ray missed
				create Result.make_miss (l_step)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Normal computation

	compute_normal (a_scene: SDF_SCENE; a_point: SDF_VEC3): SDF_VEC3
			-- Compute surface normal at point using gradient.
		require
			scene_attached: a_scene /= Void
			point_attached: a_point /= Void
		local
			eps: REAL_64
			dx, dy, dz: SDF_VEC3
			nx, ny, nz: REAL_64
		do
			eps := normal_epsilon

			-- Sample SDF at offset points
			create dx.make (eps, 0.0, 0.0)
			create dy.make (0.0, eps, 0.0)
			create dz.make (0.0, 0.0, eps)

			-- Central difference gradient
			nx := a_scene.distance (a_point + dx) - a_scene.distance (a_point - dx)
			ny := a_scene.distance (a_point + dy) - a_scene.distance (a_point - dy)
			nz := a_scene.distance (a_point + dz) - a_scene.distance (a_point - dz)

			create Result.make (nx, ny, nz)
			Result := Result.normalized
		ensure
			result_attached: Result /= Void
			is_normalized: Result.is_unit_vector
		end

	compute_normal_shape (a_shape: SDF_SHAPE; a_point: SDF_VEC3): SDF_VEC3
			-- Compute surface normal at point for single shape.
		require
			shape_attached: a_shape /= Void
			point_attached: a_point /= Void
		local
			eps: REAL_64
			dx, dy, dz: SDF_VEC3
			nx, ny, nz: REAL_64
		do
			eps := normal_epsilon

			create dx.make (eps, 0.0, 0.0)
			create dy.make (0.0, eps, 0.0)
			create dz.make (0.0, 0.0, eps)

			nx := a_shape.distance (a_point + dx) - a_shape.distance (a_point - dx)
			ny := a_shape.distance (a_point + dy) - a_shape.distance (a_point - dy)
			nz := a_shape.distance (a_point + dz) - a_shape.distance (a_point - dz)

			create Result.make (nx, ny, nz)
			Result := Result.normalized
		ensure
			result_attached: Result /= Void
			is_normalized: Result.is_unit_vector
		end

feature {NONE} -- Constants

	Default_max_steps: INTEGER = 128
			-- Default maximum steps

	Default_max_distance: REAL_64 = 100.0
			-- Default maximum distance

	Default_surface_threshold: REAL_64 = 0.001
			-- Default surface threshold

invariant
	positive_max_steps: max_steps > 0
	positive_max_distance: max_distance > 0.0
	positive_threshold: surface_threshold > 0.0
	positive_epsilon: normal_epsilon > 0.0

end
