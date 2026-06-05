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

## License

MIT — matches the MIT half of STB's dual license.

## Thanks

Dedicated to the Ada community who have answered countless
questions, corrected countless mistakes, and saved countless
hours of head-scratching over the decades. See [THANKS.md](THANKS.md).
