# create-pwegam

A CLI scaffolder and hybrid **2D/3D ASCII game engine** built natively for PowerShell (`pwsh`).

## Quick Install

Run this one-liner in PowerShell to install `create-pwegam` globally:

```powershell
irm https://raw.githubusercontent.com/ravioli67/create-pwegam/main/install.ps1 | iex
```

## Create a New Game

```powershell
create pwegam@latest my-game
cd my-game
pwsh ./START.ps1
```

## Controls (Default Template)
* **`W A S D`** — Move the animated 2D sprite
* **`1` / `2` / `3`** — Toggle 3D render modes (Fill + Wireframe, Fill only, Wireframe only)
* **`ESC`** — Quit cleanly

## License
MIT License — see [LICENSE](./LICENSE). Portions of the 3D rasterizer and console font utilities are adapted from third-party MIT-licensed open-source work (attribution retained in source headers).
