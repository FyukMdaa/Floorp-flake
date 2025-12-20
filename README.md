# Floorp Flake

NixOS用のFloorpブラウザflakeです。nixpkgsよりも upstream のリリースを頻繁に取り込み、より早く最新版を利用できます。

**注意** これは個人用の実験的なflakeです。自己責任で使用してください。  
例: パッケージのビルドが失敗する場合や、Floorpの一部機能が正常に動作しない可能性があります。

## 使い方

### flake.nixに追加

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [ floorp.overlays.default ];

          environment.systemPackages = [ pkgs.floorp-bin ];
        }
      ];
    };
  };
}
```

### Home-managerで使う場合

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
    home-manager = "github:nix-community/home-manager";
  };

  outputs = { nixpkgs, floorp, home-manager, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit floorp; };

      modules = [
        {
          nixpkgs.overlays = [ floorp.overlays.default ];
          home.packages = [ pkgs.floorp-bin ];
        }
      ];
    };
  };
}
```

### Overlayを使わない場合

`floorp.packages.x86_64-linux.floorp` は、flakeの `outputs.packages` から直接 Floorp パッケージを参照しています。

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    floorp.url = "github:fyukmdaa/floorp-flake";
  };

  outputs = { self, nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [ floorp.packages.x86_64-linux.floorp ];
        }
      ];
    };
  };
}
```

## ファイル構成

```
.
├── flake.nix           # flake定義
├── sources.json        # バージョン、URL、ハッシュ値の定義
├── .github/
│   └── workflows/
│       └── update.yml  # 自動更新workflow
└── README.md
```

## 自動更新

~~GitHub Actionsが毎日自動でFloorpの最新版をチェックし、新しいバージョンがあればPRを作成します。~~  
手動更新に切り替えました。自動更新をする場合は`.github/workflows/update.yml`にスケジュールを作成してください。

### 自動PR作成の仕組み

- `.github/workflows/update.yml` により、毎日定期的にFloorpの新しいリリースをチェックします。
- 新しいバージョンが見つかった場合、`sources.json` などバージョン情報を含むファイルが自動で更新され、PRが作成されます。
- これにより、常に最新のFloorpを簡単に取り込むことができます。

# 謝辞
**[Floorp](https://github.com/Floorp-Projects/Floorp)**  
最高のブラウザです。  


**[nixpkgs/floorp-bin-unwrapped](https://github.com/NixOS/nixpkgs/tree/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/by-name/fl/floorp-bin-unwrapped)**   
**[nixpkgs/firefox-wrapper.nix](https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/pkgs/applications/networking/browsers/firefox/wrapper.nix)**   
このFlakeを作る時にとても参考になりました。
