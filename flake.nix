{
  description = "pydantic-core: version-bumped ahead of nixpkgs through a Python package overlay.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version hash cargoHash;
      source = { type = "pypi"; pname = "pydantic_core"; format = "sdist"; };
      overlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev:
            let
              src = pyfinal.fetchPypi {
                pname = "pydantic_core";
                inherit version hash;
              };
            in
            {
              pydantic-core = pyprev.pydantic-core.overridePythonAttrs (_: {
                inherit version src;
                sourceRoot = null;
                doCheck = false;
                passthru = { };
                cargoDeps = final.rustPlatform.fetchCargoVendor {
                  pname = "pydantic-core";
                  inherit version src;
                  hash = cargoHash;
                };
              });
            })
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            pydantic-core = pkgs.python3.pkgs.pydantic-core;
            default = pkgs.python3.pkgs.pydantic-core;
            update-version = flake-lib.lib.mkUpdateVersion {
              inherit pkgs source;
              buildAttr = "pydantic-core";
              buildFailureHash = "cargoHash";
            };
            update-branches = flake-lib.lib.mkUpdateBranches {
              inherit pkgs source;
              pinSchema = "pypi";
              extraHashes = [ "cargoHash" ];
            };
          };
        }) // {
      overlays.default = overlay;
    };
}
