# CentOS Stream 9 Docker Image Notes

## Overview
This document describes the CentOS Stream 9 variant of the Steam Headless Docker image.

## Key Features

### Multi-Stage Build
The CentOS variant uses a multi-stage Docker build to compile Sunshine from source:

1. **Builder Stage (`sunshine-builder`)**:
   - Based on `quay.io/centos/centos:stream9`
   - Installs all build dependencies (cmake, gcc, boost-devel, etc.)
   - Clones Sunshine from GitHub (version v2025.122.141614)
   - Compiles Sunshine with the following features:
     - X11 support enabled
     - Wayland support enabled
     - DRM support enabled
     - CUDA support disabled (can be enabled if needed)
   - Installs to `/tmp/sunshine-install` for copying to final stage

2. **Final Stage**:
   - Based on `quay.io/centos/centos:stream9`
   - Copies compiled Sunshine from builder stage
   - Installs runtime dependencies only
   - Much smaller final image size

## Package Manager Differences

### CentOS uses DNF instead of APT
- `dnf -y install` instead of `apt-get install -y`
- `dnf clean all` instead of `apt-get clean`
- Package cache at `/var/cache/dnf` instead of `/var/lib/apt/lists/`

### Repository Configuration
CentOS requires:
- EPEL (Extra Packages for Enterprise Linux) repository
- CRB (CodeReady Builder) repository for development packages
- RPM Fusion repositories for Steam

## Package Name Differences

### Common Tools
| Debian Package | CentOS Package |
|---------------|----------------|
| `procps` | `procps-ng` |
| `p7zip-full` | `p7zip` + `p7zip-plugins` |

### X11 Packages
| Debian Package | CentOS Package |
|---------------|----------------|
| `xorg` | `xorg-x11-server-Xorg` |
| `xserver-xorg-video-dummy` | `xorg-x11-drv-dummy` |
| `x11-utils` | `xorg-x11-apps` |
| `x11-xserver-utils` | `xorg-x11-server-utils` |
| `xserver-xorg-input-evdev` | `xorg-x11-drv-evdev` |
| `xserver-xorg-input-libinput` | `xorg-x11-drv-libinput` |
| `xfonts-base` | `xorg-x11-fonts-misc` |

### Audio Packages
| Debian Package | CentOS Package |
|---------------|----------------|
| `libasound2` | `alsa-lib` |
| `libasound2-plugins` | `alsa-plugins-pulseaudio` |

### Desktop Environment
| Debian Package | CentOS Package |
|---------------|----------------|
| `xfce4` | `@xfce-desktop-environment` |
| `msttcorefonts` | `google-noto-sans-fonts` |
| `fonts-vlgothic` | (not needed, Noto fonts cover this) |
| `imagemagick` | `ImageMagick` (different case) |

### Gstreamer
| Debian Package | CentOS Package |
|---------------|----------------|
| `gstreamer1.0-*` | `gstreamer1-*` |
| `libgstreamer1.0-0` | `gstreamer1` |

### Media Drivers
| Debian Package | CentOS Package |
|---------------|----------------|
| `intel-media-va-driver-non-free` | (included in `mesa-va-drivers`) |
| `i965-va-driver-shaders` | (included in `mesa-va-drivers`) |
| `libva2` | `libva` |
| `vainfo` | `libva-utils` |
| `vdpauinfo` | `libvdpau` |

## Sunshine Compilation

### Build Dependencies
The builder stage requires these additional packages for compiling Sunshine:
- Development headers: `*-devel` packages
- Build tools: `cmake`, `gcc`, `gcc-c++`, `make`
- Libraries: `boost-devel`, `opus-devel`, `libva-devel`, etc.

### Build Configuration
```cmake
cmake -DCMAKE_BUILD_TYPE=Release \
      -DSUNSHINE_ENABLE_WAYLAND=ON \
      -DSUNSHINE_ENABLE_X11=ON \
      -DSUNSHINE_ENABLE_DRM=ON \
      -DSUNSHINE_ENABLE_CUDA=OFF \
      ..
```

### Runtime Dependencies
After building, only runtime libraries are needed:
- Base libraries without `-devel` suffix
- No build tools or headers

## Steam Installation

CentOS requires RPM Fusion repositories for Steam:
```bash
dnf -y install \
    https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm
dnf -y install steam
```

## Docker Compose Usage

Use the CentOS-specific compose file:
```yaml
services:
  steam-headless:
    image: ghcr.io/thisisqasim/steam-headless:centos
    # ... rest of configuration
```

Or specify in your `.env` file and use a generic compose file with:
```bash
IMAGE_TAG=centos
```

## CI/CD Integration

The GitHub Actions workflow (`build_ci.yml`) has been updated to include 'centos' in the build matrix:
```yaml
matrix:
  flavour: ['debian', 'arch', 'centos']
```

This ensures the CentOS variant is built alongside Debian and Arch variants.

## Image Tags

The CentOS variant will be available as:
- `ghcr.io/thisisqasim/steam-headless:centos` (stable)
- `ghcr.io/thisisqasim/steam-headless:centos-staging` (development)

## Notes

### Neko Server Removed
The CentOS variant does not include the Neko server (WebRTC streaming). Only VNC-based web UI is available:
- `WEB_UI_MODE` is set to `"vnc"` by default
- NEKO environment variables are not included
- This simplifies the build and reduces dependencies

### Script Compatibility
The entrypoint and initialization scripts have been updated to support CentOS/RHEL distributions:
- **GPU Driver Configuration** (`60-configure_gpu_driver.sh`): Added DNF package manager support for Mesa/Vulkan driver installation
- **Package Manager Detection**: Scripts automatically detect whether to use `apt-get`, `pacman`, or `dnf`
- All other scripts are distribution-agnostic and work without modification

### Missing Packages
Some packages from Debian are not available or needed in CentOS:
- `xcvt` - Not required, using standard xrandr utilities
- `cpu-x` - Not available in standard repos, removed from install list
- `gamescope` - Not available in CentOS Stream 9 repos

### Flatpak Configuration
CentOS handles flatpak slightly differently:
- No need for `gnome-software-plugin-flatpak` (included in base)
- No need for `dpkg-statoverride` (Debian-specific)

### Font Configuration
Using Google Noto Sans fonts instead of Microsoft TrueType fonts, which is more appropriate for enterprise Linux distributions and provides excellent Unicode coverage.

## Future Improvements

1. Consider adding gamescope support when available in repos
2. Add optional CUDA support for NVIDIA users
3. Optimize Sunshine build flags for specific hardware
4. Add more comprehensive hardware monitoring tools
