note
	description: "[
		SDF primitive: Capsule (line segment with radius).

		Distance formula (Inigo Quilez):
		pa = p - a
		ba = b - a
		h = clamp(dot(pa, ba) / dot(ba, ba), 0, 1)
		d = length(pa - ba * h) - radius

		A capsule is a line segment with spherical caps.
		Points a and b define the line segment endpoints.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_CAPSULE

inherit
	SDF_SHAPE
		rename
			position as point_a
		redefine
			make_at_origin
		end

create
	make,
	make_at_origin,
	make_vertical

feature {NONE} -- Initialization

	make (a_point_a, a_point_b: SDF_VEC3; a_radius: REAL_64)
			-- Create capsule between two points with given radius.
		require
			point_a_attached: a_point_a /= Void
			point_b_attached: a_point_b /= Void
			positive_radius: a_radius > 0.0
			points_different: not a_point_a.is_equal (a_point_b)
		do
			point_a := a_point_a
			point_b := a_point_b
			radius := a_radius
		ensure
			point_a_set: point_a = a_point_a
			point_b_set: point_b = a_point_b
			radius_set: radius = a_radius
		end

	make_at_origin
			-- Create vertical capsule centered at origin.
		do
			create point_a.make (0.0, -0.5, 0.0)
			create point_b.make (0.0, 0.5, 0.0)
			radius := 0.25
		end

	make_vertical (a_height, a_radius: REAL_64)
			-- Create vertical capsule centered at origin.
		require
			positive_height: a_height > 0.0
			positive_radius: a_radius > 0.0
		local
			l_half_height: REAL_64
		do
			l_half_height := a_height / 2.0
			create point_a.make (0.0, -l_half_height, 0.0)
			create point_b.make (0.0, l_half_height, 0.0)
			radius := a_radius
		ensure
			radius_set: radius = a_radius
		end

feature -- Access

	point_b: SDF_VEC3
			-- Second endpoint of the line segment

	radius: REAL_64
			-- Capsule radius

	length: REAL_64
			-- Length of the line segment (excluding caps)
		do
			Result := point_b.minus (point_a).length
		ensure
			non_negative: Result >= 0.0
		end

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to capsule surface.
		local
			pa, ba: SDF_VEC3
			h, ba_dot: REAL_64
		do
			pa := p - point_a
			ba := point_b - point_a

			-- Project p onto line segment, clamped to [0, 1]
			ba_dot := ba.dot (ba)
			if ba_dot > 0.0 then
				h := (pa.dot (ba) / ba_dot).max (0.0).min (1.0)
			else
				h := 0.0
			end

			-- Distance to nearest point on segment, minus radius
			Result := pa.minus (ba * h).length - radius
		end

feature -- Element change (fluent API)

	set_point_b (a_point_b: SDF_VEC3): like Current
			-- Set second endpoint and return self
		require
			point_attached: a_point_b /= Void
			points_different: not point_a.is_equal (a_point_b)
		do
			point_b := a_point_b
			Result := Current
		ensure
			point_b_set: point_b = a_point_b
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
	point_b_attached: point_b /= Void
	positive_radius: radius > 0.0

end
