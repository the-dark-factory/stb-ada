#!/usr/bin/env bash
#
# gen.sh — emit a reference fdump-ada-spec for the STB headers this crate
# binds, from vendor/stb, deterministically. The output is a generation AID,
# parked under gen/ and never copied into src/.
#
# STATUS (2026-06-06): UNLIKE box2d-ada/scripts/gen.sh, this is NOT a
# byte-faithful reproducer of src/. The committed Ada binding (src/stb.ads,
# src/stb-image.ads + .adb, src/stb-image-c.ads) is HAND-AUTHORED — none of it
# carries the fdump boilerplate signature ("pragma Ada_2012; pragma
# Style_Checks (Off);"), it uses Ada child-package naming (Stb.Image.C, not the
# fdump `stb_image_h`), and src/stb-image-c.ads thins stb_image.h down to the 7
# functions the wrapper needs (with hand-written doc comments and explicit
# External_Name), whereas a raw fdump over stb_image.h emits ~700 declarations
# in a flat `stb_image_h` package plus ~57 system-header spillover specs. So a
# fdump cannot REPLACE src/; running it and diffing src/ would (correctly)
# diverge. We therefore park the raw spec under gen/ as the reference the
# binding author curated from, and leave the hand-authored src/ untouched and
# buildable (that is the contract). `git diff src/` after this script is empty
# by construction — the script never writes there.
#
# Why a separate generator compiler: stb_image.h (and the other stb_*.h)
# `#include <stdio.h>`. The Alire GCC (~/.alire/bin/gcc) is built for an older
# darwin and its pre-fixed <stdio.h> no longer matches the macOS 26 SDK
# ('FILE' does not name a type), so it CANNOT fdump these headers here. Homebrew
# gcc-15 (current-SDK-matched) is the only working fdump; stb is plain C so we
# use C mode (-x c). The default MacOSX.sdk symlink can drift, so we pass an
# explicit -isysroot.
#
# Steps:
#   1. Discover which stb_*.h headers the binding covers — the `#include`d
#      headers under an active `#define STB_*_IMPLEMENTATION` in csrc/stb_impl.c.
#   2. For each, gcc -fdump-ada-spec (C mode) into gen/<header>/ as a reference
#      spec (the project spec plus its system-header closure, unpruned).
#
# Requirements: a current-SDK gcc with -fdump-ada-spec (Homebrew gcc-15 by
# default; override with GEN_GCC), and the vendored stb at vendor/stb.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

inc="$repo_root/vendor/stb"
impl="$repo_root/csrc/stb_impl.c"
[ -d "$inc" ]  || { echo "error: $inc not found — is vendor/stb populated?" >&2; exit 1; }
[ -f "$impl" ] || { echo "error: $impl not found — cannot discover bound headers" >&2; exit 1; }

gen_gcc="${GEN_GCC:-/opt/homebrew/bin/gcc-15}"
command -v "$gen_gcc" >/dev/null 2>&1 || gen_gcc="gcc-15"
command -v "$gen_gcc" >/dev/null 2>&1 || {
  echo "error: no fdump-capable gcc ($gen_gcc). Install one (brew install gcc) or set GEN_GCC." >&2
  echo "       NOTE: the Alire gcc cannot fdump stdio-pulling stb headers on macOS 26." >&2
  exit 1; }

sysroot_flag=()
for sdk in /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk \
           /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk; do
  [ -d "$sdk" ] && { sysroot_flag=(-isysroot "$sdk"); break; }
done

# Bound headers = active (non-commented) `#include "stb_*.h"` lines in the impl
# TU. The impl gates each behind a STB_*_IMPLEMENTATION define; commented-out
# future headers (C-comment ' *  #include') are skipped by the leading-# filter.
# (read loop, not mapfile — macOS ships bash 3.2; cf. box2d-ada/scripts/gen.sh.)
headers=()
while IFS= read -r h; do [ -n "$h" ] && headers+=("$h"); done < <(awk '
  /^[[:space:]]*#[[:space:]]*include[[:space:]]*"stb_.*\.h"/ {
    s=$0; sub(/^[^"]*"/,"",s); sub(/".*/,"",s); print s
  }' "$impl" | sort -u)

[ "${#headers[@]}" -gt 0 ] || { echo "error: no bound stb_*.h headers found in $impl" >&2; exit 1; }

dest="$repo_root/gen"
rm -rf "$dest"
mkdir -p "$dest"

echo ">> bound headers (from csrc/stb_impl.c): ${headers[*]}"
echo ">> fdump-ada-spec reference  (gcc: $gen_gcc)"

for hdr in "${headers[@]}"; do
  src_hdr="$inc/$hdr"
  [ -f "$src_hdr" ] || { echo "   warn: $hdr not in vendor/stb — skipping" >&2; continue; }
  out="$dest/${hdr%.h}"
  mkdir -p "$out"
  # fdump emits the specs even when gcc returns non-zero (e.g. the benign
  # '#pragma once in main file' note); swallow stderr, ignore status.
  ( cd "$out" && "$gen_gcc" -c -fdump-ada-spec -x c \
      -I "$inc" "${sysroot_flag[@]}" "$src_hdr" ) 2>/dev/null || true
  proj_spec="${hdr%.h}_h.ads"
  if [ -f "$out/$proj_spec" ]; then
    n=$(ls -1 "$out"/*.ads 2>/dev/null | wc -l | tr -d ' ')
    echo "   $hdr -> gen/${hdr%.h}/$proj_spec  (+$((n - 1)) system-closure specs)"
  else
    echo "   warn: fdump produced no $proj_spec for $hdr" >&2
  fi
done

echo ">> reference specs written under gen/  (NOT src/ — hand-authored binding preserved)"
