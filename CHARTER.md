# stb-ada — charter

Ada bindings to the [STB header-only utility collection](https://github.com/nothings/stb)
by Sean Barrett.

Second entry in the bindings line after ada-imgui. STB is on the
Ada community's explicit Projects to Work on wishlist with no
existing Ada bindings — clear gap to fill.

## Why STB second

- **Real gap** — survey at scaffold time found zero existing Ada
  bindings for any stb_* header. Unlike Raylib (already covered
  by Fabien Chouteau's binding) or ImGui (one stale solo).
- **Header-only C** — no separate build step like cimgui's C++
  compilation. A single `stb_impl.c` with the right `#define
  STB_*_IMPLEMENTATION` lines covers the whole umbrella.
- **Small surfaces per header** — stb_image has ~25 public
  functions; stb_truetype ~30; stb_image_write ~6. Each is a
  tractable session's work.
- **Universally useful** — almost every graphics-adjacent
  project needs PNG/JPG loading or font rasterisation. The
  consumers come ready-made. Includes our own future ImGui /
  raylib examples — they need image + font loading.
- **Public domain** — STB is unlicense / MIT dual; no licensing
  friction for a binding crate.

## Per-header strategy

STB is a collection, not a single library. The Ada side mirrors
that: one child package per header, all under `Stb.*`. Users
import only the children they need.

Priority order for v0.x:

1. **stb_image** (image loading) — highest universal demand.
   Read PNG, JPG, BMP, GIF, PSD, TGA, HDR. Returns malloc'd
   pixel buffer + width/height/components.
2. **stb_image_write** (image writing) — small surface, pairs
   naturally with stb_image. PNG, BMP, TGA, JPG, HDR output.
3. **stb_truetype** (font rasterisation) — needed by any text-
   rendering pipeline. ImGui uses it; raylib uses it.
4. **stb_rect_pack** (rectangle packing) — small, used by
   stb_truetype for font atlas layout. Often shipped together.
5. **stb_image_resize2** (image resizing) — useful, smaller
   demand. Ship after the first four prove the umbrella shape.

Out of scope for v0.x: stb_vorbis (audio), stb_ds (data
structures — overlaps Ada containers), stb_sprintf (overlaps
Ada I/O), stb_textedit (overlaps any GUI library's own).

## Repository layout

```
stb-ada/
├── CHARTER.md           — this
├── README.md            — public one-pager
├── LICENSE              — MIT (matches STB's MIT half)
├── alire.toml           — crate metadata
├── stb_ada.gpr          — root GPR (static library)
├── src/
│   ├── stb.ads          — root package, version, common types
│   ├── stb-image.ads/adb       — first child: image loading
│   ├── stb-image_write.ads/adb — image writing
│   ├── stb-truetype.ads/adb    — font rasterisation
│   └── stb-rect_pack.ads/adb   — atlas packing
├── csrc/
│   └── stb_impl.c       — single .c with all STB_*_IMPLEMENTATION
│                          defines + includes
├── vendor/
│   └── stb/             — upstream stb headers (git submodule
│                          or git clone)
├── scripts/
│   └── build-stb.sh     — compiles csrc/stb_impl.c → libstb.a
├── examples/
│   ├── smoke/           — non-GUI: load a test PNG, verify
│   │                      dimensions, free the buffer
│   └── (later)          — resize, font atlas, etc.
└── tests/
    └── fixtures/
        └── tiny.png     — known-good test image (8x8 RGBA)
```

## Naming convention

Following ada-imgui's precedent:

- `stbi_load` (C) → `Stb.Image.Load` (Ada) — drop the `stbi_`
  prefix; the child-package path provides the namespace.
- `STBI_VERSION` → `Stb.Image.Version` (constant).
- Type `stbi_uc` → `Interfaces.Unsigned_8` directly; we don't
  re-export STB's typedefs unless they add meaning.
- Internal C surface: `Stb.C` private-ish (same trade-off as
  ada-imgui's Imgui.C — public for now, may privatize later).

## Idiomatic Ada wrappers

For each stb function, provide both:
- A thin binding matching the C signature (in `Stb.C`)
- An idiomatic Ada wrapper that hides ownership concerns

Example for stb_image:

```ada
--  Thin (in Stb.C):
function stbi_load
  (Filename : chars_ptr;
   X, Y, Channels : access int;
   Desired_Channels : int) return access Unsigned_8
with Import, Convention => C;

--  Idiomatic (in Stb.Image):
type Image is record
   Width    : Positive;
   Height   : Positive;
   Channels : Positive range 1 .. 4;
   Pixels   : Pixel_Array_Access;  -- malloc'd; owned by Image
end record;

function Load_From_File (Path : String) return Image;
procedure Free (Img : in out Image);
```

The `Image` record OWNS the pixel buffer; `Free` calls
`stbi_image_free` to release it back to STB's allocator.
Eventually wrap in a controlled type for auto-finalisation;
not v0.1.

## License

MIT — matches STB's MIT-half (Sean dual-licenses STB as
public domain OR MIT).

## What this binding establishes

Validates the factory pattern on a **header-only C library**.
ImGui exercised the C++-via-cimgui shape; STB exercises pure-C
header-only. Between them, the pattern handles almost every
upstream library shape. Remaining shape (auto-generated C via
SWIG or similar) is rare in the wishlist.

— Pawl
