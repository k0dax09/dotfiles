# Helium browser — packaged from its source.
#
# Replace the placeholders below with the real repo information:
#   * repo       → the URL to helium.computer's source (clone URL on GitHub)
#   * rev        → commit hash (use the latest tag/commit)
#   * hash       → SHA-256 of the source tree
#
# Get the hash with:
#   nix-prefetch-url --unpack <tarball-url>
# or:
#   nix flake prefetch ... 

{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "YOUR_GITHUB_ORG";   # ← e.g. helium-browser
    repo = "helium";
    rev = "YOUR_COMMIT_SHA";     # ← e.g. "abcdef0"
    sha256 = "0000000000000000000000000000000000000000000000000000"; # ← real hash
  };

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  # If helium uses a standard build (cargo/npm/make), adapt here.
  buildPhase = ''
    # e.g. cargo build --release   |   npm run build   |   make
  '';

  installPhase = ''
    install -Dm755 helium "$out/bin/helium"
  '';

  meta = with lib; {
    description = "Helium browser";
    homepage = "https://helium.computer/";
    license = licenses.free;
    platforms = platforms.linux;
  };
}