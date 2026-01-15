note
	description: "[
		SDF primitive: Sphere.

		Distance formula (Inigo Quilez):
		d = length(p - center) - radius

		The simplest SDF primitive - exact distance to surface.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_SPHERE

inherit
	SDF_SHAPE

create
	make

feature {NONE} -- Initialization

	make (a_radius: REAL_64)
			-- Create sphere with `a_radius' at origin.
		require
			positive_radius: a_radius > 0.0
		do
			make_at_origin
			radius := a_radius
		ensure
			radius_set: radius = a_radius
			at_origin: position.is_zero_vector
		end

feature -- Access

	radius: REAL_64
			-- Sphere radius

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to sphere surface.
			-- Formula: length(p - center) - radius
		do
			Result := p.minus (position).length - radius
		end

feature -- Element change (fluent API)

	set_radius (a_radius: REAL_64): like Current
			-- Set radius and return self
		require
			positive_radius: a_radius > 0.0
		do
			radius := a_radius
			Result := Current
		ensure
			radius_set: radius = a_radius
			result_is_current: Result = Current
		end

invariant
	positive_radius: radius > 0.0

end
