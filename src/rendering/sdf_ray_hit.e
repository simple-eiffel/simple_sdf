note
	description: "[
		Result of ray marching: hit or miss information.

		Contains:
		- hit: whether the ray hit a surface
		- position: 3D position of hit point (if hit)
		- distance: distance traveled along ray (if hit)
		- normal: surface normal at hit point (if hit)
		- steps: number of march steps taken
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_RAY_HIT

create
	make_hit,
	make_miss

feature {NONE} -- Initialization

	make_hit (a_position: SDF_VEC3; a_distance: REAL_64; a_normal: SDF_VEC3; a_steps: INTEGER)
			-- Create successful hit result.
		require
			position_attached: a_position /= Void
			normal_attached: a_normal /= Void
			non_negative_distance: a_distance >= 0.0
			positive_steps: a_steps > 0
		do
			hit := True
			position := a_position
			distance := a_distance
			normal := a_normal
			steps := a_steps
		ensure
			is_hit: hit
			position_set: position = a_position
			distance_set: distance = a_distance
			normal_set: normal = a_normal
			steps_set: steps = a_steps
		end

	make_miss (a_steps: INTEGER)
			-- Create miss result.
		require
			non_negative_steps: a_steps >= 0
		do
			hit := False
			create position.make_zero
			distance := 0.0
			create normal.make_zero
			steps := a_steps
		ensure
			is_miss: not hit
			steps_set: steps = a_steps
		end

feature -- Access

	hit: BOOLEAN
			-- Did the ray hit a surface?

	position: SDF_VEC3
			-- Hit position (zero if miss)

	distance: REAL_64
			-- Distance traveled (zero if miss)

	normal: SDF_VEC3
			-- Surface normal (zero if miss)

	steps: INTEGER
			-- Number of march steps taken

feature -- Status report

	is_hit: BOOLEAN
			-- Alias for `hit'
		do
			Result := hit
		end

	is_miss: BOOLEAN
			-- Opposite of `hit'
		do
			Result := not hit
		end

invariant
	position_attached: position /= Void
	normal_attached: normal /= Void
	non_negative_distance: distance >= 0.0
	non_negative_steps: steps >= 0

end
