{
  description = "Lumera - Android TV streaming app for Stremio addons (homelab fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        # Android SDK
        androidSdk = pkgs.androidenv.androidsdk {
          buildToolsVersions = [ "34.0.0" "35.0.0" "36.0.0" ];
          platformVersions = [ "26" "28" "30" "31" "33" "34" "35" "36" ];
          includeNDK = false;
          includeExtras = [
            "extras;google;gcm"
          ];
        };

        # Build dependencies
        nativeBuildInputs = with pkgs; [
          androidSdk
          jdk17
          gradle
          git
          which
        ];

        # Runtime dependencies for the build
        buildInputs = with pkgs; [
          jdk17
        ];

        # Lumera build derivation
        lumera-apk = pkgs.stdenv.mkDerivation {
          name = "lumera-apk";
          src = self;

          inherit nativeBuildInputs buildInputs;

          # Gradle properties for the build
          GRADLE_OPTS = "-Dorg.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8";

          # Android SDK location
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

          # Java home
          JAVA_HOME = pkgs.jdk17.home;

          # Build phase
          buildPhase = ''
            runHook preBuild

            echo "=== Building Lumera APK ==="
            echo "ANDROID_HOME=$ANDROID_HOME"
            echo "JAVA_HOME=$JAVA_HOME"

            # Create local.properties for API keys (empty placeholders)
            cat > local.properties <<EOF
            acra.url=
            acra.token=
            tmdb.api_key=
            TRAKT_CLIENT_ID=
            TRAKT_CLIENT_SECRET=
            EOF

            # Make gradlew executable
            chmod +x gradlew

            # Build the debug APK
            ./gradlew :app:assembleDebug \
              --no-daemon \
              --stacktrace \
              -x lint \
              -x test

            runHook postBuild
          '';

          # Install phase
          installPhase = ''
            runHook preInstall

            echo "=== Installing APK ==="
            mkdir -p $out

            # Copy the built APK
            find app/build/outputs/apk -name "*.apk" -exec cp {} $out/ \;

            echo "APK built successfully:"
            ls -la $out/

            runHook postInstall
          '';

          # Fixup phase (not needed for APK)
          dontFixup = true;

          # Output hash (will be computed on first build)
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = pkgs.lib.fakeSha256;
        };

      in
      {
        # Packages
        packages = {
          default = lumera-apk;
          lumera-apk = lumera-apk;
        };

        # DevShell for development
        devShells = {
          default = pkgs.mkShell {
            name = "lumera-dev";

            inherit nativeBuildInputs buildInputs;

            # Android SDK location
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";

            # Java home
            JAVA_HOME = pkgs.jdk17.home;

            # Gradle options
            GRADLE_OPTS = "-Dorg.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8";

            shellHook = ''
              echo "=== Lumera Development Shell ==="
              echo "Android SDK: $ANDROID_HOME"
              echo "Java: $JAVA_HOME"
              echo ""
              echo "Available commands:"
              echo "  ./gradlew :app:assembleDebug   - Build debug APK"
              echo "  ./gradlew :app:assembleRelease - Build release APK"
              echo "  ./gradlew :app:installDebug    - Install on connected device"
              echo "  ./gradlew tasks                - List all tasks"
              echo ""
              echo "Build APK manually:"
              echo "  nix build .#lumera-apk"
            '';
          };
        };

        # Apps (for `nix run`)
        apps = {
          build-app = {
            type = "app";
            program = "${pkgs.writeShellScript "build-lumera" ''
              cd ${self}
              echo "Building Lumera APK..."
              ${pkgs.nix}/bin/nix build .#lumera-apk --out-link lumera-apk
              echo "APK available at: lumera-apk/"
            ''}";
          };
        };

        # Checks (for `nix flake check`)
        checks = {
          # Just verify the devshell builds
          devshell = self.devShells.${system}.default;
        };
      }
    );
}
