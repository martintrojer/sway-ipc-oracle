FROM registry.fedoraproject.org/fedora:44

ARG I3_COMMIT=9be3249ac5b377ed3270e36bca83df53d8023337
ARG SWAY_COMMIT=88869399f421d9180dd8b6ed0b5a1f4a3585d252
ARG WLROOTS_COMMIT=c1d38536c926134698ff2615843e0d4103e84ac4
ARG SWAYWARD_COMMIT=b420c1a4316af8ed55c83d73fbad93d66f4d8530

RUN dnf install -y \
        bash git gcc gcc-c++ clang cargo meson ninja-build pkgconf-pkg-config \
        cairo-devel cairo-gobject-devel dbus-devel json-c-devel libdisplay-info-devel libev-devel libevdev-devel libinput-devel \
        libliftoff-devel libseat-devel libudev-devel libxkbcommon-devel libxkbcommon-x11-devel \
        mesa-libEGL-devel mesa-libgbm-devel pango-devel pcre2-devel \
        pipewire-devel startup-notification-devel systemd-devel wayland-devel \
        wayland-protocols-devel libxcb-devel xcb-proto xcb-util-devel xcb-util-cursor-devel xcb-util-errors-devel \
        xcb-util-keysyms-devel xcb-util-wm-devel xcb-util-xrm-devel yajl-devel \
        foot google-noto-sans-mono-vf-fonts perl-AnyEvent perl-AnyEvent-I3 perl-ExtUtils-Depends \
        perl-ExtUtils-PkgConfig perl-IPC-Run perl-Inline-C perl-JSON-PP \
        perl-Test-Deep perl-Test-Differences perl-Test-Exception perl-Test-Fatal \
        perl-Test-Simple perl-XML-Parser perl-XML-Simple perl-App-cpanminus perl-LWP-Protocol-https python3 scdoc \
        xdotool xkeyboard-config xorg-x11-server-Xephyr xorg-x11-server-Xvfb xorg-x11-server-Xwayland xorg-x11-server-Xwayland-devel \
        xorg-x11-xauth xorg-x11-xinit xterm xwayland-satellite \
    && dnf clean all

RUN cpanm --notest X11::XCB@0.25 || { cat /root/.cpanm/work/*/build.log; false; }

RUN git clone https://github.com/i3/i3.git /opt/i3-src \
    && git -C /opt/i3-src checkout "$I3_COMMIT" \
    && meson setup /opt/i3-src/build /opt/i3-src \
    && meson compile -C /opt/i3-src/build

RUN git clone https://github.com/swaywm/sway.git /opt/sway-src \
    && git -C /opt/sway-src checkout "$SWAY_COMMIT" \
    && git clone https://gitlab.freedesktop.org/wlroots/wlroots.git /opt/sway-src/subprojects/wlroots \
    && git -C /opt/sway-src/subprojects/wlroots checkout "$WLROOTS_COMMIT" \
    && meson setup /opt/sway-src/build /opt/sway-src -Ddefault-wallpaper=false -Dman-pages=disabled \
    && meson compile -C /opt/sway-src/build

RUN git clone https://github.com/martintrojer/swayward.git /opt/swayward-src \
    && git -C /opt/swayward-src checkout "$SWAYWARD_COMMIT" \
    && CARGO_BUILD_JOBS=2 cargo build --manifest-path /opt/swayward-src/Cargo.toml --release \
    && rm -rf /opt/swayward-src/target/release/{build,deps,incremental,.fingerprint}

ENV ORACLE_CONTAINER=1 \
    I3SRC=/opt/i3-src \
    I3BUILD=/opt/i3-src/build \
    I3_BINARY=/opt/i3-src/build/i3 \
    SWAY_BINARY=/opt/sway-src/build/sway/sway \
    SWAYWARD_BINARY=/opt/swayward-src/target/release/swayward \
    XDG_RUNTIME_DIR=/tmp/oracle-runtime

RUN mkdir -m 700 /tmp/oracle-runtime \
    && git config --system --add safe.directory /oracle

WORKDIR /oracle
CMD ["./contrib/validate"]
