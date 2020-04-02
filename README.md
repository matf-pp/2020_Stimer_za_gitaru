# Strings

An FFT-based instrument tuner for GNU/Linux operating systems.

**Note:** This software is currently pre-alpha. Don't expect much and use at own risk.

![Screenshot](data/screenshot.png)

## Building
### Prerequisites (debian based distros)
```
valac
meson
gettext
libgtk-3-dev
libglib-2.0-dev
libasound-2-dev
libcairo2-dev
```

### Steps
```bash
meson build --prefix=/usr
cd build
ninja                     # Build
ninja install             # Install system-wide
```

## Contributing
Please read the [contribution guide](CONTRIBUTING.md).
