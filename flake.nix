{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      # Python 3.11 seems to be necessary for the version of pydantic-core that
      # this version of pydantic requires:
      #
      # https://stackoverflow.com/questions/78593700/langchain-community-langchain-packages-giving-error-missing-1-required-keywor
      py-pkgs = pkgs.python311Packages;

      pydantic-settings = (py-pkgs.pydantic-settings.overrideAttrs (oldAttrs: rec {
        version = "2.6.0";

        src = pkgs.fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic-settings";
          rev = "refs/tags/v${version}";
          hash = "sha256-gJThzYJg6OIkfmfi/4MVINsrvmg+Z+0xMhdlCj7Fn+w=";
        };

        propagatedBuildInputs = [ pydantic py-pkgs.python-dotenv ];
      }));

      httpx = (py-pkgs.httpx.overrideAttrs (oldAttrs: rec {
        version = "0.27.2";
        src = pkgs.fetchFromGitHub {
          owner = "encode";
          repo = oldAttrs.pname;
          rev = "refs/tags/${version}";
          hash = "sha256-N0ztVA/KMui9kKIovmOfNTwwrdvSimmNkSvvC+3gpck=";
        };

        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ py-pkgs.zstandard  ];
      }));

      textual = (py-pkgs.textual.overrideAttrs (oldAttrs: rec {
        version = "0.85.0";
        src = pkgs.fetchFromGitHub {
          owner = "Textualize";
          repo = "textual";
          rev = "refs/tags/v${version}";
          hash = "sha256-ROq/Pjq6XRgi9iqMlCzpLmgzJzLl21MI7148cOxHS3o=";
        };
      }));

      pydantic = (py-pkgs.pydantic.overrideAttrs (oldAttrs: rec {
        version = "2.9.2";
        src = pkgs.fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic";
          rev = "refs/tags/v${version}";
          hash = "sha256-Eb/9k9bNizRyGhjbW/LAE/2R0Ino4DIRDy5ZrQuzJ7o=";
        };

        propagatedBuildInputs = [ pydantic-core py-pkgs.annotated-types py-pkgs.jsonschema ];
      }));

      pydantic-core = (py-pkgs.pydantic-core.overrideAttrs (oldAttrs: rec {
        version = "2.23.4";

        src = pkgs.fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic-core";
          rev = "refs/tags/v${version}";
          hash = "sha256-WSSwiqmdQN4zB7fqaniHyh4SHmrGeDHdCGpiSJZT7Mg=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
          inherit src;
          name = "${oldAttrs.pname}-${version}";
          hash = "sha256-dX3wDnKQLmC+FabC0van3czkQLRcrBbtp9b90PgepZs=";
        };

        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          py-pkgs.typing-extensions
        ];
      }));

      textual-autocomplete = py-pkgs.buildPythonPackage rec {
        pname = "textual_autocomplete";
        version = "3.0.0a12";
        pyproject = true;
        src = pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-HSyeTSTH9XWryMYSy2q//0cG9qqrm5OVBrldroRUkwk=";
        };

        nativeBuildInputs = with py-pkgs; [
          poetry-core
        ];
        
        dependencies = with py-pkgs; [
          textual
          typing-extensions
        ];
      };
    in
    {
      packages = rec {
        default = posting;
        posting = py-pkgs.buildPythonApplication rec {
          pname = "posting";
          version = "2.0.1";
          pyproject = true;

          src = pkgs.fetchFromGitHub {
            owner = "darrenburns";
            repo = "posting";
            rev = "refs/tags/${version}";
            sha256 = "sha256-6KtC5VuG3x07VTenpyDAJr9KO4jdTCFk1u/pSoyYPsc=";
          };

          patches = [
            ./0001-Change-watchfile-version.patch
          ];

          nativeBuildInputs = [
            py-pkgs.hatchling
          ];

          propagatedBuildInputs = [
            py-pkgs.click
            py-pkgs.xdg-base-dirs
            py-pkgs.click-default-group
            py-pkgs.pyperclip
            py-pkgs.pyyaml
            py-pkgs.python-dotenv
            py-pkgs.watchfiles
            pydantic
            pydantic-settings
            textual
            textual-autocomplete
            httpx
          ];
        };
      };
    }
  );
}
