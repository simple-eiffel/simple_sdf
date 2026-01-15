note
	description: "[
		SDF primitive: Torus (donut shape).

		Distance formula (Inigo Quilez):
		q = (length(p.xz) - major_radius, p.y)
		d = length(q) - minor_radius

		The torus is centered at position, lying in the XZ plane.
		Major radius is from center to tube center.
		Minor radius is the tube radius.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_TORUS

inherit
	SDF_SHAPE

create
	make

feature {NONE} -- Initialization

	make (a_major_radius, a_minor_radius: REAL_64)
			-- Create torus with given radii at origin.
		require
			positive_major: a_major_radius > 0.0
			positive_minor: a_minor_radius > 0.0
			minor_less_than_major: a_minor_radius < a_major_radius
		do
			make_at_origin
			major_radius := a_major_radius
			minor_radius := a_minor_radius
		ensure
			major_set: major_radius = a_major_radius
			minor_set: minor_radius = a_minor_radius
		end

feature -- Access

	major_radius: REAL_64
			-- Distance from center to tube center

	minor_radius: REAL_64
			-- Tube radius

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to torus surface.
		local
			l_local: SDF_VEC3
			q: SDF_VEC2
		do
			-- Transform to torus-local coordinates
			l_local := p - position

			-- Project onto XZ plane, get distance to ring center
			-- q.x = distance from ring center in XZ
			-- q.y = height (Y coordinate)
			create q.make (l_local.xz.length - major_radius, l_local.y)

			-- Distance to tube surface
			Result := q.length - minor_radius
		end

feature -- Element change (fluent API)

	set_major_radius (a_radius: REAL_64): like Current
			-- Set major radius and return self
		require
			positive_radius: a_radius > 0.0
			greater_than_minor: a_radius > minor_radius
		do
			major_radius := a_radius
			Result := Current
		ensure
			radius_set: major_radius = a_radius
			result_is_current: Result = Current
		end

	set_minor_radius (a_radius: REAL_64): like Current
			-- Set minor radius and return self
		require
			positive_radius: a_radius > 0.0
			less_than_major: a_radius < major_radius
		do
			minor_radius := a_radius
			Result := Current
		ensure
			radius_set: minor_radius = a_radius
			result_is_current: Result = Current
		end

invariant
	positive_major: major_radius > 0.0
	positive_minor: minor_radius > 0.0
	minor_less_than_major: minor_radius < major_radius

end
