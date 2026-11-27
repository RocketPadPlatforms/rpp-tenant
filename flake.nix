{
  description = "Dev shell for rpp-tenant";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [argocd kubeseal kubernetes-helm];
      shellHook = ''
        export ARGOCD_CONFIG_DIR=$(realpath ./.argocd)
      '';
    };
  };
}
