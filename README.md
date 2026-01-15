<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/simple_sdf/master/docs/images/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_sdf

**[Documentation](https://simple-eiffel.github.io/simple_sdf/)** | **[GitHub](https://github.com/simple-eiffel/simple_sdf)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Signed Distance Field (SDF) library for geometric primitives, boolean operations, and ray marching.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - GPU-accelerated via Vulkan, 63 FPS at 4K resolution

## Inspiration

This library was inspired by watching [Art of Code's SDF tutorial](https://youtu.be/il-TXbn5iMA?si=owhsmvIj-CFQx1F5) at 9 AM one morning. By 1 PM that same day, we had a fully working `simple_vulkan` and `simple_sdf` library with complete demo applications - including a procedural Medieval Village rendered in real-time at 63 FPS.

The power of Eiffel's Design by Contract combined with GPU compute shaders makes complex graphics programming accessible and reliable.

## Overview

SIMPLE_SDF provides a comprehensive toolkit for working with Signed Distance Fields in Eiffel. Create procedural geometry, perform CSG operations, and render with real-time ray marching on CPU or GPU.

## Quick Start

### One-Liner API (SDF_QUICK)

```eiffel
local
    sdf: SDF_QUICK
do
    -- That's it! One line to create, one line to run.
    create sdf.make_village ("Medieval Village", 1920, 1080)
    sdf.run
end
```

This 4-line demo gives you a full procedural Medieval Village with:
- Interactive camera (WASD + arrows)
- 63 FPS GPU rendering via Vulkan
- Screenshots (F12) and pause (P)
- Built-in controls display

### Core Library API

```eiffel
local
    sdf: SIMPLE_SDF
    sphere: SDF_SPHERE
    box: SDF_BOX
    result: SDF_SHAPE
do
    create sdf

    -- Create primitives
    sphere := sdf.sphere (1.0)
    box := sdf.cube (0.8)

    -- Boolean operations
    result := sdf.smooth_union (sphere, box, 0.3)

    -- Query distance at a point
    print (result.distance (sdf.vec3 (0, 0, 0)))
end
```

## Features

- **Geometric Primitives** - Sphere, box, cylinder, torus, plane, and more
- **Boolean Operations** - Union, intersection, difference with smooth blending
- **Transformations** - Translate, rotate, scale any SDF shape
- **Ray Marching** - High-quality rendering with configurable parameters
- **GPU Acceleration** - 63 FPS at 4K via Vulkan compute shaders
- **Multiple Backends** - MiniFB (CPU), Raylib, Vulkan (GPU)

## Installation

1. Set the ecosystem environment variable:
```
SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_sdf" location="$SIMPLE_EIFFEL/simple_sdf/simple_sdf.ecf"/>
```

## Primitives

```eiffel
sphere := sdf.sphere (1.0)                    -- Sphere
box := sdf.box (2.0, 1.0, 0.5)                -- Box
cube := sdf.cube (1.5)                        -- Cube
cylinder := sdf.cylinder (0.5, 2.0)           -- Cylinder
torus := sdf.torus (1.0, 0.3)                 -- Torus
plane := sdf.plane (sdf.vec3 (0, 1, 0), 0.0)  -- Ground plane
```

## Boolean Operations

```eiffel
-- Sharp operations
combined := sdf.union (a, b)
overlap := sdf.intersection (a, b)
carved := sdf.difference (a, b)

-- Smooth operations (with blend radius)
blended := sdf.smooth_union (a, b, 0.3)
rounded := sdf.smooth_intersection (a, b, 0.2)
filleted := sdf.smooth_difference (a, b, 0.1)
```

## Visualization

Run the demos to see SDF rendering in action:

```batch
# SDF_QUICK One-Liner Demo (recommended)
ec -batch -config simple_sdf.ecf -target simple_sdf_quick_demo -c_compile

# Medieval Village Demo - Full procedural scene
ec -batch -config simple_sdf.ecf -target simple_sdf_village_demo -c_compile

# Basic GPU demo (Vulkan) - 63 FPS at 4K!
ec -batch -config simple_sdf.ecf -target simple_sdf_vulkan_demo -c_compile

# CPU rendering (MiniFB) - For systems without Vulkan
ec -batch -config simple_sdf.ecf -target simple_sdf_minifb_demo -c_compile
```

### Demo Controls

| Key | Action |
|-----|--------|
| WASD | Move camera |
| Space/Ctrl | Up/Down |
| Arrow Keys | Look around |
| P | Pause/Resume |
| F12 | Screenshot (BMP) |
| ESC | Exit |

## Medieval Village Demo

The village demo showcases complex procedural SDF scene construction:

- Half-timbered houses with pitched roofs
- Stone church with steeple
- Watchtower
- Village well with stone rim
- Trees with foliage
- Cobblestone ground texture
- Perimeter walls

All geometry is defined mathematically using SDF primitives and boolean operations - no 3D models required!

## Performance

Tested on NVIDIA GeForce RTX 5070 Ti:

| Backend | Resolution | FPS |
|---------|------------|-----|
| MiniFB (CPU) | 1920x1080 | 30-40 |
| Vulkan (GPU) | 1920x1080 | 63 |
| Vulkan (GPU) | 3840x2160 | 63 |

## Dependencies

- **simple_vulkan** - For GPU acceleration (optional)
- **simple_minifb** - For CPU visualization (bundled)
- No external Eiffel library dependencies

## License

MIT License
