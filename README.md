# llauncher-flake

A Nix flake packaging [LLauncher](https://github.com/AugustLigh/LLauncher) — a native Linux launcher for Arknights: Endfield — from its official `.deb` release.

If you're on Arch or a derivative, upstream already publishes an AUR package (`llauncher-bin`) which may be simpler:

```bash
paru -S llauncher-bin
```

This flake exists for NixOS/Nix users where that isn't an option.

## Usage

```nix
{
  inputs.llauncher.url = "github:axioncs/llauncher-flake";
}
```

```nix
inputs.llauncher.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Or run directly without installing:

```bash
nix run github:axioncs/llauncher-flake
```

## Known caveats

- Only `x86_64-linux` is packaged — upstream doesn't publish an arm64 Linux build yet.
- Built from the `.deb` release rather than the AppImage. A few runtime fixes were needed to make this work outside the AppImage's self-contained environment, since Nix builds each package in isolation rather than sharing a system-wide GTK/GIO setup:
  - `libayatana-appindicator` is loaded dynamically at runtime rather than linked at build time, so it's added to `LD_LIBRARY_PATH` explicitly.
  - GSettings schemas (used by GTK's native file picker, among other things) are compiled and bundled into the package directly, rather than relying on a system-wide schema cache.
  - `glib-networking`'s GIO TLS module and a WebKit compositing workaround are set explicitly, matching a black-screen fix upstream normally bakes into the AppImage at build time.
- Tested end-to-end on NixOS, including the native file/folder picker. If you hit an issue, please open one here.
- Requires a working Proton install, managed from within the app itself (see upstream docs).

## License

Packaging code in this repo is MIT — see `LICENSE`. LLauncher itself is also MIT — see [upstream](https://github.com/AugustLigh/LLauncher).
