# S02 - Class Catalog: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Date:** 2026-01-23

## Class Hierarchy

```
SIMPLE_SDF (facade)
|
+-- SDF_VEC2 (2D vector)
+-- SDF_VEC3 (3D vector)
|
+-- SDF_SHAPE (deferred)
|   +-- SDF_SPHERE
|   +-- SDF_BOX
|   +-- SDF_CAPSULE
|   +-- SDF_CYLINDER
|   +-- SDF_TORUS
|   +-- SDF_PLANE
|
+-- SDF_OPS (operations)
+-- SDF_SCENE (composition)
+-- SDF_RAY_MARCHER (renderer)
+-- SDF_RAY_HIT (hit info)
```

## Class Descriptions

### SIMPLE_SDF (Facade)
Main entry point providing factory methods for creating vectors, shapes, operations, scenes, and ray marchers.

**Creation:** `default_create`

### SDF_VEC2
2D vector with x, y components. Supports arithmetic operations, normalization, dot product.

### SDF_VEC3
3D vector with x, y, z components. Supports arithmetic operations, normalization, cross product, dot product.

### SDF_SHAPE (Deferred)
Base class for all SDF primitives. Defines `distance(point: SDF_VEC3): REAL_64` contract.

### SDF_SPHERE
Sphere primitive defined by radius and center position.

### SDF_BOX
Axis-aligned box defined by half-extents (width, height, depth).

### SDF_CAPSULE
Capsule (line segment with radius) defined by two endpoints and radius.

### SDF_CYLINDER
Vertical cylinder defined by height and radius.

### SDF_TORUS
Torus (donut) defined by major and minor radii.

### SDF_PLANE
Infinite plane defined by normal vector and height offset.

### SDF_OPS
Boolean and smooth operations: union, subtraction, intersection with optional smoothing.

### SDF_SCENE
Container for multiple SDF shapes with composition operations.

### SDF_RAY_MARCHER
Ray marching algorithm implementation with configurable max steps, max distance, and threshold.

### SDF_RAY_HIT
Result of ray march containing hit point, normal, distance, and hit status.

## Class Count Summary
- Facade: 1
- Vectors: 2
- Primitives: 6
- Operations: 1
- Scene: 1
- Rendering: 2
- **Total: 13 classes**
