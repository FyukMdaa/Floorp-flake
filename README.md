# Floorp Flake

NixOS用のFloorpブラウザflakeです。nixpkgsより早く最新版を使えます。

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
      modules = [
        floorp.nixosModules.default
        {
          environment.systemPackages = [ floorp.packages.x86_64-linux.floorp ];
        }
      ];
    };
  };
}
```

### シンプルな方法（overlayなし）

```nix
{
  inputs.floorp.url = "github:fyukmdaa/floorp-flake";
  
  outputs = { nixpkgs, floorp, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      modules = [{
        environment.systemPackages = [
          floorp.packages.x86_64-linux.floorp
        ];
      }];
    };
  };
}
```

## 手動更新

```bash
# 最新版に更新
nix run github:Mic92/nix-update -- floorp --flake

# ビルドテスト
nix build .#floorp

# システムに適用
sudo nixos-rebuild switch --flake .
```

## ファイル構成

```
.
├── flake.nix           # flake定義
├── package.nix         # パッケージビルド定義
├── .github/
│   └── workflows/
│       └── update.yml  # 自動更新workflow
└── README.md
```

## 自動更新

GitHub Actionsが毎日自動でFloorpの最新版をチェックし、新しいバージョンがあればPRを作成します。

## トラブルシューティング

### ハッシュエラーが出る

```bash
nix run github:Mic92/nix-update -- floorp --flake --version=skip
```

でハッシュを再計算できます。

### ビルドが失敗する

依存関係が足りない可能性があります。`package.nix`の`buildInputs`を確認してください。
