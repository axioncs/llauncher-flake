{
  description = "Nix flake for LLauncher – a launcher for Arknights: Endfield";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        versionInfo = builtins.fromJSON (builtins.readFile ./version.json);
        inherit (versionInfo) version;

        debHash = versionInfo.hashes.amd64;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "llauncher";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/AugustLigh/LLauncher/releases/download/${version}/LLauncher_${version}_amd64.deb";
            hash = debHash;
          };

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            dpkg
            makeWrapper
            glib
          ];

          buildInputs = with pkgs; [
            gtk3
            glib
            cairo
            pango
            gdk-pixbuf
            webkitgtk_4_1
            libsoup_3
            libayatana-appindicator
            glib-networking
            stdenv.cc.cc.lib
          ];

          unpackPhase = ''
            dpkg-deb -x $src .
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 usr/bin/llauncher -t "$out/bin"
            install -Dm644 usr/share/applications/LLauncher.desktop -t "$out/share/applications"

            for size in 32x32 128x128; do
              if [ -f "usr/share/icons/hicolor/$size/apps/llauncher.png" ]; then
                install -Dm644 "usr/share/icons/hicolor/$size/apps/llauncher.png" \
                  "$out/share/icons/hicolor/$size/apps/llauncher.png"
              fi
            done
            if [ -f "usr/share/icons/hicolor/256x256@2/apps/llauncher.png" ]; then
              install -Dm644 "usr/share/icons/hicolor/256x256@2/apps/llauncher.png" \
                "$out/share/icons/hicolor/256x256@2/apps/llauncher.png"
            fi

            runHook postInstall
          '';

          postInstall = ''
            mkdir -p "$out/share/glib-2.0/schemas"
            for src in \
              "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas" \
              "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}/glib-2.0/schemas"
            do
              cp "$src"/*.xml "$out/share/glib-2.0/schemas/"
            done
            ${pkgs.glib.dev}/bin/glib-compile-schemas "$out/share/glib-2.0/schemas"
          '';

          postFixup = ''
            wrapProgram $out/bin/llauncher \
              --set GIO_MODULE_DIR "${pkgs.glib-networking}/lib/gio/modules" \
              --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
              --prefix LD_LIBRARY_PATH : "${pkgs.libayatana-appindicator}/lib" \
              --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/llauncher-${version}:$out/share"
          '';

          meta = {
            description = "Launcher for Arknights: Endfield";
            homepage = "https://github.com/AugustLigh/LLauncher";
            license = lib.licenses.mit;
            platforms = [ "x86_64-linux" ];
            mainProgram = "llauncher";
          };
        };
      }
    );
}
