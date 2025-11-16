{
  description = "A C library that embeds Tailscale into a process";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/2fb006b87f04c4d3bdf08cfdbc7fab9c13d94a15";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [];
      # TODO:  "aarch64-linux" "aarch64-darwin" "x86_64-darwin"
      systems = ["x86_64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }:
        with pkgs.lib; {
          packages = {
            go-module = pkgs.buildGoModule {
              pname = "libtailscale";
              version = "0.1.0";
              src = ./.;
              proxyVendor = true;
              vendorHash = "sha256-l2hSfOzMAIsCKPwxxFw2D87s8m+3NTGdID9Gc9JjdR8=";
              buildPhase = ''
                go build -buildmode=c-archive -o libtailscale.a
              '';

              installPhase = ''
                mkdir -p $out/lib $out/include
                cp libtailscale.a $out/lib/
                cp libtailscale.h $out/include/ 2>/dev/null || true
              '';
              doCheck = false;
            };

            example-c = pkgs.stdenv.mkDerivation {
              pname = "tailscale-echoserver";
              version = "0.1.0";
              src = ./.;
              nativeBuildInputs = with pkgs; [gcc];
              buildPhase = ''
                cd example
                cc echo_server.c ${self'.packages.go-module}/lib/libtailscale.a
              '';
              installPhase = ''
                mkdir -p $out/bin/
                cp ./a.out $out/bin/
              '';
              meta = {
                mainProgram = "a.out";
              };
            };

            example-java = pkgs.stdenv.mkDerivation {
              name = "tailscale-echoserver";
              version = "0.1.0";
              src = ./.;
              nativeBuildInputs = with pkgs; [openjdk];
              buildPhase = ''
                cd example

                gcc \
                  -shared \
                  -fPIC \
                  -I$${JAVA_HOME}/include -I$${JAVA_HOME}/include/linux \
                  -o libtailscalejni.so \
                  tailscale_jni.c \
                  ${self'.packages.go-module}/lib/libtailscale.a

                javac EchoServer.java

                echo "❯ TS_AUTHKEY=invalid java -Djava.library.path=... EchoServer" > README.md

                cat > run-echo-server << 'EOF'
                #!/bin/sh
                export JAVA_HOME=${pkgs.jdk}
                export CLASSPATH=@out@/share/java
                exec java -Djava.library.path=@out@/lib EchoServer "$@"
                EOF
              '';
              installPhase = ''
                mkdir -p $out/share/java $out/lib $out/bin

                cp 'EchoServer$ConnectionHandler.class' $out/share/java/
                cp 'EchoServer.class' $out/share/java/

                cp libtailscalejni.so $out/lib/

                cp run-echo-server $out/bin/tailscale-echo-server
                substituteInPlace $out/bin/tailscale-echo-server \
                  --replace '@out@' "$out"
                chmod +x $out/bin/tailscale-echo-server

                cp README.md $out/
              '';
              meta = {
                mainProgram = "tailscale-echo-server";
              };
            };

            default = pkgs.stdenv.mkDerivation {
              pname = "libtailscale";
              version = "0.1.0";

              src = ./.;

              nativeBuildInputs = with pkgs; [go];

              buildPhase = ''
                runHook preBuild

                make c-archive
                make shared

                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                mkdir -p $out/lib $out/include

                cp libtailscale.a $out/lib/
                cp libtailscale.so $out/lib/
                cp tailscale.h $out/include/

                runHook postInstall
              '';

              meta = with pkgs.lib; {
                description = "A C library that embeds Tailscale into a process";
                homepage = "https://github.com/tailscale/tailscale";
                license = licenses.bsd3;
                maintainers = with maintainers; [];
                platforms = platforms.unix;
              };
            };
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [go openjdk gcc];
          };
        };
      flake = {};
    };
}
