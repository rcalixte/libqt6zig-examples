<div align="center">
<img alt="libqt6zig-examples" src="assets/libqt6zig-examples.png" height="128px;" />

![MIT License](https://img.shields.io/badge/License-MIT-green)
[![Static Badge](https://img.shields.io/badge/v0.14%20(stable)-f7a41d?logo=zig&logoColor=f7a41d&label=Zig)](https://ziglang.org/download/)
</div>

---

Example applications using the MIT-licensed Qt 6 bindings for Zig

These examples can be thought of as instructive templates for using the main library. Though some of the examples have some complexity to them, the intention is to aim for simplicity while demonstrating valid uses of the library. All of source code for the examples are a single file by design. Any auxiliary files are placed in the same directory for either compilation or execution purposes. Please try out the sample applications and start a [discussion](https://github.com/rcalixte/libqt6zig/discussions) if you have any questions or issues relevant to these examples.

---

TABLE OF CONTENTS
-----------------

- [License](#license)
- [Building](#building)
- [FAQ](#faq)
- [Special Thanks](#special-thanks)

License
-------

The sample applications within `libqt6zig-examples` are licensed under the MIT license.

Building
--------

The dependencies for building the sample applications are the same as the main library. Refer to the main library's [Building](https://github.com/rcalixte/libqt6zig#building) section for more information.

It is recommended to execute an initial build to generate a clean build cache before making any changes. This allows the build process to use the cached build artifacts to speed up subsequent builds.

Once the required packages are installed, the library can be built from the root of the repository:

```bash
zig build
```

Users of Arch-based distributions need to __make sure that all packages are up-to-date__ first and will need to add the following option to support successful compilation:

```bash
zig build -Denable-workaround
```

Prefixed libraries have per-library options that can be used to enable or disable them (where supported):

```bash
zig build -Denable-charts=true -Denable-qscintilla=false
```

Example applications can also be built and run independently:

```bash
zig build helloworld events
```

Applications can be installed to the system in a non-default location by adding the `--prefix-exe-dir` option to the build command:

```bash
sudo zig build --prefix-exe-dir /usr/local/bin # creates /usr/local/bin/{examples}
```

To see the full list of examples available:

```bash
zig build -l
```

To see the full list of examples and build options available:

```bash
zig build --help
```

The source code for the examples can be found in the `src` directory of the repository.

FAQ
---

### Q1. How long does it take to compile the examples?

The examples compile a subset of the entire main library and then build the sample applications from the source code. The first compilation should take less than 3 minutes, assuming the hardware in use is at or above the level of that of a consumer-grade mid-tier machine released in the past decade. Once the build cache is warmed up for the examples, subsequent compilations should be very fast, on the order of seconds. For client applications that use and configure a specific subset of the main library, the expected compilation time should be similar to the examples.

### Q2. What build modes are supported by the examples?

Currently, only `ReleaseFast`, `ReleaseSafe`, and `ReleaseSmall` are supported. The `Debug` build mode is not supported. This may change in the future. The default build mode is `ReleaseFast`. To change the build mode:

```bash
zig build -Doptimize=ReleaseSafe
```

or

```bash
zig build --release=safe
```

### Q3. Are translations supported?

Several options are available to implement translations ranging from functions available in the main library to well-supported systems such as [GNU gettext](https://www.gnu.org/software/gettext/) to [Qt's internationalization options](https://doc.qt.io/qt-6/internationalization.html). Developers are free to use any of the available options or implement their own solution.

### Q4. Do the applications built with this library support theming?

<table align="center">

| ![debian_cinnamon_helloworld](assets/debian_cinnamon_helloworld.png) | ![endeavour_kde_helloworld](assets/endeavour_kde_helloworld.png) |
| :------------------------------------------------------------------: | :--------------------------------------------------------------: |
|              Debian + Cinnamon + Qt 6.8 (custom theme)               |                    EndeavourOS + KDE + Qt 6.8                    |
|      ![fedora_kde_helloworld](assets/fedora_kde_helloworld.png)      |  ![freebsd_xfce_helloworld](assets/freebsd_xfce_helloworld.png)  |
|                        Fedora + KDE + Qt 6.8                         |                     FreeBSD + Xfce + Qt 6.8                      |
|   ![mint_cinnamon_helloworld](assets/mint_cinnamon_helloworld.png)   |        ![ubuntu_helloworld](assets/ubuntu_helloworld.png)        |
|                    Linux Mint + Cinnamon + Qt 6.4                    |                         Ubuntu + Qt 6.4                          |

</table>

Special Thanks
--------------

- [@mappu](https://github.com/mappu) for the [MIQT](https://github.com/mappu/miqt) bindings that provided the phenomenal foundation for this project

- [@arnetheduck](https://github.com/arnetheduck) for proving the value of collaboration on the back-end of the library while working across different target languages
