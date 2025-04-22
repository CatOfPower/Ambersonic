<p align="center">
  <img width="160" src="data/icons/hicolor/scalable/apps/cat.of.power.Ambersonic.svg">
</p>
<h1 align="center">Ambersonic</h1>
<h3 align="center">A GTK 4 Subsonic client for Linux</h3>

> **Warning**
> This application is highly WIP and not ready to use

Ambersonic is a highly work-in-progress Subsonic-compatible client and API written with GTK4 and vala

### Dependencies

- GTK 4
- libadwaita >= 1.4
- libsoup-3.0
- libxml-2.0
- meson
- vala
- blueprint-compiler

### Installation

#### Building from Source

1. Install dependencies:
For Debian/Ubuntu
```bash
sudo apt install build-essential meson valac libgtk-4-dev libadwaita-1-dev libsoup-3.0-dev libxml2-dev blueprint-compiler
```
For Arch Linux
``` bash
sudo pacman -S base-devel meson vala gtk4 libadwaita libsoup3 libxml2 blueprint-compiler ninja
```

2. Clone the repository:

```bash
git clone https://github.com/CatOfPower/Ambersonic.git
cd Ambersonic
```

3. Build and install:

```bash
meson setup build --buildtype=release
ninja -C build
sudo ninja -C build install
```