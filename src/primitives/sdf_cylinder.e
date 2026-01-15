note
	description: "[
		SDF primitive: Cylinder (capped, vertical).

		Distance formula (Inigo Quilez):
		d_radial = length(p.xz) - radius
		d_vertical = abs(p.y) - half_height
		d = max(d_radial, d_vertical)

		The cylinder is aligned along the Y axis.
		Height is the full height, not half-height.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_CYLINDER

inherit
	SDF_SHAPE

create
	make

feature {NONE} -- Initialization

	make (a_height, a_radius: REAL_64)
			-- Create cylinder with given height and radius at origin.
		require
			positive_height: a_height > 0.0
			positive_radius: a_radius > 0.0
		do
			make_at_origin
			half_height := a_height / 2.0
			radius := a_radius
		ensure
			half_height_set: half_height = a_height / 2.0
			radius_set: radius = a_radius
		end

feature -- Access

	half_height: REAL_64
			-- Half the cylinder height

	radius: REAL_64
			-- Cylinder radius

	height: REAL_64
			-- Full height
		do
			Result := half_height * 2.0
		end

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to cylinder surface.
		local
			l_local: SDF_VEC3
			d_radial, d_caps: REAL_64
			d_outer: SDF_VEC2
			l_zero: SDF_VEC2
		do
			-- Transform to cylinder-local coordinates
			l_local := p - position

			-- Radial distance (XZ plane)
			d_radial := l_local.xz.length - radius

			-- Cap distance (Y axis)
			d_caps := l_local.y.abs - half_height

			-- For exact SDF, combine radial and cap distances
			create l_zero.make_zero
			create d_outer.make (d_radial, d_caps)

			-- Outside: distance to nearest surface element
			-- Inside: negative of minimum penetration
			Result := d_outer.max (l_zero).length + d_outer.max_component.min (0.0)
		end

feature -- Element change (fluent API)

	set_height (a_height: REAL_64): like Current
			-- Set full height and return self
		require
			positive_height: a_height > 0.0
		do
			half_height := a_height / 2.0
			Result := Current
		ensure
			half_height_updated: half_height = a_height / 2.0
			result_is_current: Result = Current
		end

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
	positive_half_height: half_height > 0.0
	positive_radius: radius > 0.0

end
