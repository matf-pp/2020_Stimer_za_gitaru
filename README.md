# Strings
[![pipeline status](https://gitlab.com/dusan-gvozdenovic/strings/master/pipeline.svg)](https://gitlab.com/dusan-gvozdenovic/strings/pipelines)
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
libglib2.0-dev
libasound2-dev
libcairo2-dev
```

### Steps
```bash
meson build --prefix=/usr
cd build
ninja                     # Build
ninja install             # Install system-wide
```

## Releases
### Nightly Builds
Being still under development, the project is not yet publically released. However, you can head over to [CI / CD pipelines](https://gitlab.com/dusan-gvozdenovic/strings/pipelines) and grab the latest nightly build (.deb package).

## Contributing
Please read the [contribution guide](CONTRIBUTING.md).
