{
  inputs = {
    NixPkgs.url = "github:NixOS/NixPkgs/nixos-unstable";

    NUR = {
      url = "github:Nix-Community/NUR";
      inputs.nixpkgs.follows = "NixPkgs";
    };

    HomeManager = {
      url = "github:Nix-Community/Home-Manager";
      inputs.nixpkgs.follows = "NixPkgs";
    };

    PlasmaManager = {
      url = "github:Nix-Community/Plasma-Manager";
      inputs.nixpkgs.follows = "NixPkgs";
      inputs.home-manager.follows = "HomeManager";
    };

    Stylix = {
      url = "github:Nix-Community/Stylix";
      inputs.nixpkgs.follows = "NixPkgs";
    };

    Spicetify = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "NixPkgs";
    };
  };

  outputs =
    {
      NixPkgs,
      HomeManager,
      NUR,
      Stylix,
      Spicetify,
      PlasmaManager,
      ...
    }:
    let
      mkHost =
        {
          hostName,
          GPU ? "amdgpu",
          DarkTheme ? false,
          Color,
          extraSystemModules ? [ ],
          extraHomeArgs ? { },
          extraHomeModules ? [ ],
        }:
        NixPkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit
              GPU
              DarkTheme
              Color
              Stylix
              ;
          };

          modules = [
            # NUR
            NUR.modules.nixos.default

            # Stylix
            Stylix.nixosModules.stylix

            # Host
            ./Hosts/${hostName}/Configuration.nix
            ./Hosts/Common.nix

            # System
            ./System/Plymouth.nix
            ./System/PipeWire.nix
            ./Services/Avahi.nix
            ./Services/GarbageCollector.nix

            # Plasma
            ./System/Desktop/Plasma/Configuration.nix

            # Hostname
            {
              networking.hostName = hostName;
            }
          ]
          ++ extraSystemModules
          ++ [
            # Home Manager
            HomeManager.nixosModules.default

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                backupFileExtension = "backup";
                overwriteBackup = true;

                extraSpecialArgs = {
                  inherit
                    DarkTheme
                    Color
                    Stylix
                    ;
                }
                // extraHomeArgs;

                users.nixos = {
                  imports = [
                    ./Home/Common.nix

                    # Common packages
                    ./Home/Packages/Firefox.nix
                    ./Home/Packages/OnlyOffice.nix

                    # Plasma
                    PlasmaManager.homeModules.plasma-manager
                    ./System/Desktop/Plasma/Home.nix
                  ]
                  ++ extraHomeModules;
                };
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        IdeaCentre = mkHost {
          hostName = "IdeaCentre";
          Color = "pink";
        };

        IdeaPad = mkHost {
          hostName = "IdeaPad";
          DarkTheme = true;
          Color = "pink";
        };

        Pavilion = mkHost {
          hostName = "Pavilion";
          GPU = "i915";
          Color = "pink";

          extraHomeArgs = {
            inherit Spicetify;
          };

          extraHomeModules = [
            Spicetify.homeManagerModules.default
            ./Home/Packages/Spicetify.nix
          ];
        };

        ThinkPad = mkHost {
          hostName = "ThinkPad";
          DarkTheme = true;
          Color = "blue";

          extraSystemModules = [
            ./Home/Packages/VirtManager.nix
          ];

          extraHomeArgs = {
            inherit Spicetify;
          };

          extraHomeModules = [
            Spicetify.homeManagerModules.default
            ./Home/Packages/Spicetify.nix
            ./Home/Packages/PhotoGIMP.nix
            ./Home/Packages/Development/VSCode.nix
          ];
        };
      };
    };
}
