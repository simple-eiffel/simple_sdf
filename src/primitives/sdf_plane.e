note
	description: "[
		SDF primitive: Infinite Plane.

		Distance formula:
		d = dot(p, normal) + height

		The plane extends infinitely in two dimensions.
		Normal should be a unit vector pointing away from solid.
		Height is the distance from origin along the normal.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_PLANE

inherit
	SDF_SHAPE
		redefine
			make_at_origin
		end

create
	make,
	make_at_origin,
	make_xy,
	make_xz,
	make_yz

feature {NONE} -- Initialization

	make (a_normal: SDF_VEC3; a_height: REAL_64)
			-- Create plane with given normal and height from origin.
		require
			normal_attached: a_normal /= Void
			normal_is_unit: a_normal.is_unit_vector
		do
			make_at_origin
			normal := a_normal
			height := a_height
		ensure
			normal_set: normal = a_normal
			height_set: height = a_height
		end

	make_at_origin
			-- Create horizontal plane (XZ) at origin facing up.
		do
			Precursor
			create normal.make (0.0, 1.0, 0.0)
			height := 0.0
		end

	make_xy (a_z: REAL_64)
			-- Create XY plane at z = `a_z', facing +Z.
		do
			make_at_origin
			create normal.make (0.0, 0.0, 1.0)
			height := -a_z
		end

	make_xz (a_y: REAL_64)
			-- Create XZ plane (ground) at y = `a_y', facing +Y.
		do
			make_at_origin
			create normal.make (0.0, 1.0, 0.0)
			height := -a_y
		end

	make_yz (a_x: REAL_64)
			-- Create YZ plane at x = `a_x', facing +X.
		do
			make_at_origin
			create normal.make (1.0, 0.0, 0.0)
			height := -a_x
		end

feature -- Access

	normal: SDF_VEC3
			-- Unit normal vector (points away from solid side)

	height: REAL_64
			-- Distance from origin along normal
			-- Positive = plane is offset in normal direction
			-- Negative = plane is offset opposite to normal

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to plane.
			-- Positive = on normal side, negative = opposite side.
		do
			Result := p.dot (normal) + height
		end

feature -- Element change (fluent API)

	set_normal (a_normal: SDF_VEC3): like Current
			-- Set normal vector and return self
		require
			normal_attached: a_normal /= Void
			normal_is_unit: a_normal.is_unit_vector
		do
			normal := a_normal
			Result := Current
		ensure
			normal_set: normal = a_normal
			result_is_current: Result = Current
		end

	set_height (a_height: REAL_64): like Current
			-- Set height and return self
		do
			height := a_height
			Result := Current
		ensure
			height_set: height = a_height
			result_is_current: Result = Current
		end

invariant
	normal_attached: normal /= Void
	normal_is_unit: normal.is_unit_vector

end
