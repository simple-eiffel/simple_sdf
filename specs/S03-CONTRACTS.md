# S03 - Contracts: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Date:** 2026-01-23

## SIMPLE_SDF Contracts

### Vector Factory

```eiffel
vec2 (a_x, a_y: REAL_64): SDF_VEC2
    ensure
        result_attached: Result /= Void
        x_set: Result.x = a_x
        y_set: Result.y = a_y

vec3 (a_x, a_y, a_z: REAL_64): SDF_VEC3
    ensure
        result_attached: Result /= Void
        x_set: Result.x = a_x
        y_set: Result.y = a_y
        z_set: Result.z = a_z

vec3_unit_x: SDF_VEC3
    ensure
        result_attached: Result /= Void
        is_unit: Result.is_unit_vector
```

### Shape Factory

```eiffel
sphere (a_radius: REAL_64): SDF_SPHERE
    require
        positive_radius: a_radius > 0.0
    ensure
        result_attached: Result /= Void
        radius_set: Result.radius = a_radius

box (a_width, a_height, a_depth: REAL_64): SDF_BOX
    require
        positive_width: a_width > 0.0
        positive_height: a_height > 0.0
        positive_depth: a_depth > 0.0
    ensure
        result_attached: Result /= Void

capsule (a_point_a, a_point_b: SDF_VEC3; a_radius: REAL_64): SDF_CAPSULE
    require
        point_a_attached: a_point_a /= Void
        point_b_attached: a_point_b /= Void
        positive_radius: a_radius > 0.0
    ensure
        result_attached: Result /= Void

torus (a_major_radius, a_minor_radius: REAL_64): SDF_TORUS
    require
        positive_major: a_major_radius > 0.0
        positive_minor: a_minor_radius > 0.0
        minor_less_than_major: a_minor_radius < a_major_radius
    ensure
        result_attached: Result /= Void

plane (a_normal: SDF_VEC3; a_height: REAL_64): SDF_PLANE
    require
        normal_attached: a_normal /= Void
        normal_is_unit: a_normal.is_unit_vector
    ensure
        result_attached: Result /= Void
```

### Ray Marcher Factory

```eiffel
ray_marcher_custom (a_max_steps: INTEGER; a_max_distance, a_threshold: REAL_64): SDF_RAY_MARCHER
    require
        positive_steps: a_max_steps > 0
        positive_distance: a_max_distance > 0.0
        positive_threshold: a_threshold > 0.0
    ensure
        result_attached: Result /= Void
```

### Scene Factory

```eiffel
scene: SDF_SCENE
    ensure
        result_attached: Result /= Void
        is_empty: Result.is_empty
```

### Distance Evaluation

```eiffel
distance (a_shape: SDF_SHAPE; a_point: SDF_VEC3): REAL_64
    require
        shape_attached: a_shape /= Void
        point_attached: a_point /= Void

union_distance (a_shapes: ARRAY [SDF_SHAPE]; a_point: SDF_VEC3): REAL_64
    require
        shapes_attached: a_shapes /= Void
        has_shapes: a_shapes.count > 0
        point_attached: a_point /= Void
```

## Key Design Decisions

1. **Positive dimensions required** - All radii, sizes must be > 0
2. **Unit vectors for normals** - Plane normals must be normalized
3. **Factory pattern** - All objects created through facade
4. **Void safety** - All returned objects guaranteed non-void
