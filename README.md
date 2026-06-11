# stb-ada

Ada bindings to [STB](https://github.com/nothings/stb) — Sean
Barrett's collection of public-domain header-only C utilities.

Targets the `stb_image`, `stb_image_write`, `stb_truetype`, and
`stb_rect_pack` headers in v0.x. Each gets its own Ada child
package; users import only what they need.

## Status

v0.1.0-dev. See [CHARTER.md](CHARTER.md) for the plan and
per-header roadmap. First binding (`Stb.Image`) lands as part
of this version's scope.

## Regenerating the binding

`scripts/gen.sh` runs `gcc -fdump-ada-spec` over the bound STB headers in
`vendor/stb` and parks the raw Ada specs under `gen/` (gitignored) as a
generation reference.

```sh
./scripts/gen.sh          # writes gen/<header>/<header>_h.ads + system closure
```

It discovers which headers to dump from the active
`#define STB_*_IMPLEMENTATION` / `#include` lines in `csrc/stb_impl.c`, so the
reference tracks whatever the crate actually binds.

**Caveat — this is a reference aid, not a byte-faithful reproducer.** Unlike
the box2d-ada / llama-ada family, the Ada in `src/` here is *hand-authored*:
`Stb.Image.C` (`src/stb-image-c.ads`) thins `stb_image.h` to the handful of
functions the wrapper needs, with hand-written doc comments and explicit
`External_Name`, and `Stb.Image` (`src/stb-image.{ads,adb}`) is the typed Ada
front. A raw fdump instead emits a flat ~700-declaration `stb_image_h` package
plus its system-header spillover — useful to crib new bindings from, but **not**
a drop-in for `src/`. `gen.sh` therefore never writes to `src/`; the
hand-authored binding is the canonical source and is preserved verbatim.

Building: `alr build` is self-contained — the single STB implementation unit
(`csrc/stb_impl.c`) is compiled by gprbuild alongside the Ada and archived into
the library, so there is no pre-build step. On macOS the Alire-shipped `gcc`
needs to be pointed at the SDK headers; if `alr build` reports a missing
`_stdio.h`, set `SDKROOT` (and, for the C include search, `CPATH`):

```sh
export SDKROOT="$(xcrun --show-sdk-path)"
export CPATH="$SDKROOT/usr/include"
```

Linux and the Alire index CI need none of this.

Toolchain note (macOS, code generation only): the STB headers `#include
<stdio.h>`, which the Alire-shipped `gcc` cannot `fdump` against the current
macOS SDK (`'FILE' does not name a type`). `gen.sh` uses Homebrew `gcc-15` for
the dump (override with `GEN_GCC=`); this affects only regenerating the binding,
not `alr build`.

## License

MIT — matches the MIT half of STB's dual license.

## Thanks

Dedicated to the Ada community who have answered countless
questions, corrected countless mistakes, and saved countless
hours of head-scratching over the decades. See [THANKS.md](THANKS.md).
