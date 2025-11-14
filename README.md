# TCNopen fork

## Bug fixes for TRDP spy

Currently I only rebuild the plugin for [Wireshark 4.0 Linux](trdp/spy/plugins/4.0/epan). I do not have the infrastructure to build other versions.

2023-August: The patch that brought little-endian interpretation was not complete and would do the wrong thing at times. Proper plugin-config-option added.

2023-April: Wireshark would crash if xml-file went missing.

## Repo is put to rest

As I wrote [before](#in-2021-and-2022):
> "The upstream project still receives active development but focuses on many goals. When I pull their additions, I notice that warning-free Linux compilation is not their primary focus, which also makes keeping up tiring."

So I will pause doing it. I may still add updates to [TRDP-SPY](trdp/spy/) Wireshark plugin here in the master-branch, but don't count on it.

I will also only react to issues concerning the Wireshark plugin and code that I added beyond upstream.

## About 
This is a "private" fork of TCNopen (Components for IEC61375 standardised communication)

**Now awesome**: 
Debian packaging is there! See below for news on 2020.

I rewrote the Wireshark Plugin [TRDP-SPY](trdp/spy/) for current Wireshark. Compiled binaries are available for versions [2.6](trdp/spy/plugins/2.6/epan), [3.0](trdp/spy/plugins/3.0/epan), [3.2](trdp/spy/plugins/3.2/epan), [3.4](trdp/spy/plugins/3.4/epan), [3.6](trdp/spy/plugins/3.6/epan) and [4.0](trdp/spy/plugins/4.0/epan). It now really works for Datasets, Arrays, Strings and filtering on names. Try it out! Create an issue if it doesn't work for you. Please be verbose if I misinterpreted the standard somewhere. From the latest revision (only available for Wireshark 3.6) you can load a folder full of XML-configs.

## Goal of fork
 - The [master](https://github.com/T12z/TCNopen/tree/master) for me to play around.
 - The [upstream](https://github.com/T12z/TCNopen/tree/upstream) if all you need is a mirror.
 - Nothing else, no product, no specific enhancements.

## In 2017
 - I updated the TRDP-Spy plugin to wireshark 2.5. Later on, Upstream have updated the plugin to a 2.x version as well, so I split this off to an [archive branch](https://github.com/T12z/TCNopen/tree/wireshark2.5). 
 - I also started into looking how to pair that up with SCADE but got off-tracked into "paid work". Currently it is *nothing* useful. Don't bother looking. If there is more interest in this topic send me some kind of thumbs-up, so I feel like I should get back onto it.
 
## In 2018
 - So I synced an update, yet haven't really looked into it. But I did trash the branch history, sorry for that!
 - In future, I will try to separate [upstream](https://github.com/T12z/TCNopen/tree/upstream) and my work, so the git-svn shuffling might work smoother.

## In 2019
 - I finally gave up on all my git misery and rebooted the repo. Syncing with upstream became a huge pain and everytime git-bugs piled up. I am **absolutely deeply sorry** for everyone, who had a clone and now has to restart.
 - I built a TRDP application that uses a wrapper around the XML stuff, partially based on the original example.
 - This wrapper is again lightly cling-wrapped to be usable from C++/Qt. Planning to publish it a.s.a.p. (As of writing, it still has too many dependencies on other stuff.)
 - Finally, I also use [Ansys SCADE](https://www.ansys.com/de-de/products/embedded-software/ansys-scade-suite), a lot, and have it working with TRDP nicely. However, if you are not using SCADE, you're in for pain. Currently, I am trying to trim a middle way, please hold on for a few weeks or drop me line.

## In 2020
 Some more Linux features:
 - Debian packaging and shared libraries added for Linux.
 - The Wireshark plugin can be built on Linux without the Wireshark source tree and now integrates with the CMake targets described below.
 With this, I will not pre-build the Wireshark plugins anymore. Please checkout the upstream branch for older pre-build plugin binaries 2.6, 3.0 and 3.2.
 - Actually, I added the plugins for 3.4 for convenience for a last time.

## Building with CMake

The top-level project uses out-of-source builds. Configure a build directory with

```sh
cmake -S . -B build/LINUX_X86_64 --preset LINUX_X86_64
```

The presets in `CMakePresets.json` enable Ninja builds with the toolchain files under `trdp/cmake/toolchains`. They also toggle the frequently requested cache options (e.g. `TRDP_MD_SUPPORT`, `TRDP_TSN_SUPPORT`, `TRDP_HIGH_PERF_INDEXED`, `TRDP_DEBUG`) so you can pick the combination that matches your target. You can override any cache value by appending `-D<NAME>=<VALUE>` to the configure command, or create a new out-of-source directory by replacing `build/LINUX_X86_64` with a custom path and reusing `-S`/`-B`. When you only care about the TRDP stack, disable the SDTv2 build with `-DTCNOPEN_BUILD_SDT=OFF`. The option automatically falls back to `OFF` when the `SDTv2` folder is absent (for example when you perform a sparse checkout), so you can keep the source tree focused on `trdp/`.

When no preset fits your environment (different architecture, generator, or compiler), start from the hidden `base` preset:

```sh
cmake -S . -B build/custom --preset base -DTRDP_TARGET_ARCH=<arch> -DTRDP_TARGET_OS=<os> -DTRDP_TARGET_VOS=<vos>
```

All presets assume CMake ≥ 3.16, Ninja, and the platform-specific toolchain prerequisites. On Linux you need GCC (or Clang), `uuid-dev`, `libglib2.0-dev`, and the usual build-time dependencies such as FlexeLint (optional), Doxygen, and Graphviz when you request documentation. Debian packaging additionally requires `devscripts` (`debuild`) and the packages listed in `debian/control` (`debhelper`, `libwireshark-dev` ≥ 2.6, …). Windows users must select a generator that matches their compiler (for example `-G "Visual Studio 17 2022"`) and ensure Wireshark development headers are available.

Build any configured tree with

```sh
cmake --build build/LINUX_X86_64
```

You can swap the directory with another build folder or use `cmake --build --preset <name>` for the matching presets.

### Migrating Debian packaging workflows

The legacy `make bindeb-pkg` shortcut is now exposed as a CMake target:

```sh
cmake --build build/LINUX_X86_64 --target bindeb-pkg
```

The resulting `.deb` files are staged under `build/LINUX_X86_64/pkg`. Install them as before with `sudo dpkg -i build/LINUX_X86_64/pkg/*.deb` and link your applications with `-ltrdp -ltau` (or the `-hp` variants). The helper target still wraps `debuild -us -uc -i -I -b`, so you need the same Debian toolchain and lintian/dpkg helpers. Source package creation remains unsupported and will print a diagnostic just like the historic GNU Make recipe.

### Migrating Wireshark TRDP-SPY plugin builds

After configuration, build the plugin with

```sh
cmake --build build/LINUX_X86_64 --target trdp_spy_plugin
```

The shared object/DLL ends up in `build/LINUX_X86_64/trdp/spy/src/trdp_spy`. Use the existing install scripts to copy the artifact into Wireshark’s plugin directory, or invoke `cmake --build … --target install` with a suitable `CMAKE_INSTALL_PREFIX`. Plugin documentation now lives behind `trdp_spy_doc_html` and `trdp_spy_doc_pdf` targets, mirroring the old `doc-html` and `doc-pdf` make rules.

### Embedding TCNopen inside a larger CMake project

You can treat this repository like any other CMake-based dependency: add it as a Git submodule (or vendor the sources) and let the parent project drive the configuration. A minimal setup looks like this:

```sh
git submodule add https://github.com/T12z/TCNopen.git extern/TCNopen
```

```cmake
# Top-level CMakeLists.txt of the consuming project
cmake_minimum_required(VERSION 3.16)
project(my_app LANGUAGES C)

# Optionally tailor the TRDP build before adding the subdirectory.
set(TCNOPEN_BUILD_SDT OFF CACHE BOOL "Skip SDTv2 when embedding" FORCE)
set(TRDP_MD_SUPPORT ON CACHE BOOL "Enable MD APIs" FORCE)

add_subdirectory(extern/TCNopen)

add_executable(my_app src/main.c)
target_link_libraries(my_app PRIVATE tcnopen::trdpap_shared)
# Swap tcnopen::trdpap_shared for tcnopen::trdpap_static when you prefer the
# static library. Lower-level variants (tcnopen::trdp_shared, etc.) are also
# exposed if you only need the core stack.
```

Key points when embedding:

* The `add_subdirectory` call builds the SDTv2 and TRDP subprojects according to the cache variables visible to the parent. Turn SDTv2 off with `-DTCNOPEN_BUILD_SDT=OFF` (or by forcing the cache entry as shown above) when you only need TRDP.
* All TRDP libraries are exported as namespaced targets (`tcnopen::trdpap_shared`, `tcnopen::trdpap_static`, `tcnopen::trdp_shared`, `tcnopen::trdp_static`, …). Linking against one of them automatically propagates the include paths, compiler options, and required system libraries to your targets.
* Super-builds can reuse the presets in `CMakePresets.json` by forwarding `CMAKE_TOOLCHAIN_FILE`, `TRDP_TARGET_ARCH`, etc., or override individual flags on the parent `cmake -S <root> -B <build>` invocation.

### Remaining GNU Make fallbacks

Some optional documentation steps still prefer GNU Make when available—for example, generating the PDF manual for the TRDP-SPY plugin runs `make` inside the Doxygen-generated LaTeX tree. When `make` is missing, the CMake targets emit a warning and skip the PDF step while still producing HTML output. All other historical make targets are now reachable through `cmake --build … --target <name>`.

## In 2021 and 2022
 I moved jobs and now work for Stadler Rail. I am not using TRDP on any recurring basis anymore in my position (rather MQTT, VDV301 ...). So this repo will wind down even further in updates.
 Some upgrades and bugfixes in the SPY were pushed. Building for Windows is still quite annoying and eats precious time.
 The upstream project still receives active development but focuses on many goals. When I pull their additions, I notice that warning-free Linux compilation is not their primary focus, which also makes keeping up tiring. You'll also notice some [differences](https://github.com/T12z/TCNopen/compare/upstream...master) between [upstream](https://github.com/T12z/TCNopen/tree/upstream) and [master](https://github.com/T12z/TCNopen/tree/master)

## Missing
 - Regular Updates. This is NOT in sync nor latest update from original sourceforge SVN
 - Support. I am no TRDP expert, neither have I project funds to work on TRDP

More information from SourceForge site: https://sourceforge.net/projects/tcnopen/

# Original Description

TCNOpen is an open source initiative which the partner railway industries created with the aim to build in collaboration some key parts of new or upcoming railway standards, commonly known under the name TCN.
TCN (Train Communication Network) is a series of international standards (IEC61375) developed by Working Group 43 of the IEC (International Electrotechnical Commission), specifying a communication system for the data communication within and between vehicles of a train. It is currently in use on many thousands of trains in the world in order to allow electronic devices to exchange information while operating aboard the same train.
TCNOpen follows the Open Source scheme, as the software is jointly developed by participating companies, according to their role, so as to achieve cheaper, quicker and better quality results.

## Licenses

TRDP: MPLv2.0 http://www.mozilla.org/MPL/2.0/

TRDPSpy: GPL http://www.gnu.org/licenses/gpl.html

TCNOpen Web Site http://www.tcnopen.eu/

## CMake helper targets

The top-level CMake project now mirrors several legacy make targets:

* `cmake --build <build-dir> --target lint` runs the SDTv2 and TRDP lint recipes. Both targets accept the legacy `FLINT` and `LINT_RULE_DIR` environment variables so you can point to a FlexeLint binary and rule directory without reconfiguring the build.
* `cmake --build <build-dir> --target doc` invokes Doxygen (and, if available, `make` in `trdp/doc/latex`) to refresh the TRDP reference manual and copy it to `doc/TCN-TRDP2-D-BOM-033-xx - TRDP Reference Manual.pdf`.
* `cmake --build <build-dir> --target dist` wraps the source archive creation logic. It requires a working `tar` executable and writes the archives into `<build-dir>/dist`.
* `cmake --build <build-dir> --target bindeb-pkg` runs `debuild -us -uc -i -I -b` when `debuild` is available and moves the resulting packages to `<build-dir>/pkg`. The companion `deb-pkg` target still only reports that source packages are unavailable.
* `cmake --build <build-dir> --target distclean` removes generated artifacts that live inside the source tree (packaging outputs, generated documentation, temporary Debian helper directories, SDTv2 `config/config.mk`, etc.). Use it after `cmake --build <build-dir> --target clean` if you also want to drop compiled objects from the build tree.
