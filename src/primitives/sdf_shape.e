note
	description: "[
		Deferred base class for all SDF primitive shapes.

		Each shape must implement distance calculation. Shapes can be
		positioned in 3D space and support basic transformations.

		The distance function returns:
		- Positive values for points outside the shape
		- Negative values for points inside the shape
		- Zero for points on the surface

		Design by Contract:
		- Position is always attached
		- Distance calculation must handle any point
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SDF_SHAPE

feature {NONE} -- Initialization

	make_at_origin
			-- Create shape at origin (0, 0, 0).
		do
			create position.make_zero
		ensure
			at_origin: position.is_zero_vector
		end

	make_at (a_position: SDF_VEC3)
			-- Create shape at specified position.
		require
			position_attached: a_position /= Void
		do
			position := a_position
		ensure
			position_set: position = a_position
		end

feature -- Access

	position: SDF_VEC3
			-- Center/origin position of the shape

feature -- Distance (deferred)

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to this shape surface.
			-- Positive = outside, negative = inside, zero = on surface.
		require
			point_attached: p /= Void
		deferred
		end

	distance_at (a_x, a_y, a_z: REAL_64): REAL_64
			-- Convenience: distance from point (x, y, z)
		local
			l_point: SDF_VEC3
		do
			create l_point.make (a_x, a_y, a_z)
			Result := distance (l_point)
		end

feature -- Status report

	is_inside (p: SDF_VEC3): BOOLEAN
			-- Is point `p' inside this shape?
		require
			point_attached: p /= Void
		do
			Result := distance (p) < 0.0
		end

	is_outside (p: SDF_VEC3): BOOLEAN
			-- Is point `p' outside this shape?
		require
			point_attached: p /= Void
		do
			Result := distance (p) > 0.0
		end

	is_on_surface (p: SDF_VEC3): BOOLEAN
			-- Is point `p' approximately on the surface?
		require
			point_attached: p /= Void
		do
			Result := distance (p).abs < Surface_epsilon
		end

feature -- Element change (fluent API)

	set_position (a_position: SDF_VEC3): like Current
			-- Set position and return self
		require
			position_attached: a_position /= Void
		do
			position := a_position
			Result := Current
		ensure
			position_set: position = a_position
			result_is_current: Result = Current
		end

feature -- Transformation (fluent API)

	translate (offset: SDF_VEC3): like Current
			-- Translate by offset and return self
		require
			offset_attached: offset /= Void
		do
			position := position + offset
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	translate_xyz (dx, dy, dz: REAL_64): like Current
			-- Translate by (dx, dy, dz) and return self
		local
			l_offset: SDF_VEC3
		do
			create l_offset.make (dx, dy, dz)
			Result := translate (l_offset)
		ensure
			result_is_current: Result = Current
		end

feature {NONE} -- Constants

	Surface_epsilon: REAL_64 = 0.0001
			-- Tolerance for surface detection

invariant
	position_attached: position /= Void

end
