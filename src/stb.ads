--  Ada bindings to Sean Barrett's STB header-only utility
--  collection (https://github.com/nothings/stb).
--
--  STB is a collection of independent header-only C libraries:
--  stb_image, stb_image_write, stb_truetype, stb_rect_pack, and
--  many more. The Ada bindings mirror that shape — one child
--  package per header. Users `with` only the children they need;
--  pulling in Stb.Image doesn't drag in the truetype or rect_pack
--  code.
--
--  Child packages so far (see CHARTER.md for the v0.x roadmap):
--
--    Stb.Image        — image loading (PNG, JPG, BMP, GIF, ...)
--    Stb.Image_Write  — image writing (planned)
--    Stb.Truetype     — font rasterisation (planned)
--    Stb.Rect_Pack    — atlas packing (planned)
--
--  All STB code lives behind a single thin C compilation unit
--  (csrc/stb_impl.c) that triggers the `STB_*_IMPLEMENTATION`
--  defines for every header we ship bindings for.

with Df_Stb_Config;

package Stb is

   --  Version of this binding crate (NOT the STB header version, which is
   --  per-header and exposed by each child). Sourced from Alire's generated
   --  crate config so it never drifts from alire.toml.
   Crate_Version : constant String := Df_Stb_Config.Crate_Version;

end Stb;
