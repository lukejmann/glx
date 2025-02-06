# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Supported base images: Ubuntu 24.04, 22.04, 20.04
# ARG DISTRIB_IMAGE=ubuntu
# ARG DISTRIB_RELEASE=24.04
# FROM ${DISTRIB_IMAGE}:${DISTRIB_RELEASE}
# ARG DISTRIB_IMAGE
# ARG DISTRIB_RELEASE

# LABEL maintainer="https://github.com/ehfd,https://github.com/danisla"

FROM nvidia/cuda:12.6.0-devel-ubuntu20.04

# Set up environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/home/user/.local/bin"

# We love UTF!
ENV LANG C.UTF-8

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Set the nvidia container runtime environment variables
ENV NVIDIA_VISIBLE_DEVICES ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV CUDA_HOME="/usr/local/cuda"
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6+PTX 8.9"


ARG DEBIAN_FRONTEND=noninteractive
# Configure rootless user environment for constrained conditions without escalated root privileges inside containers
ARG TZ=UTC
ENV PASSWD=mypasswd

RUN apt-get update && apt-get install --no-install-recommends -y curl





RUN apt-get clean && apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends -y \
    apt-utils \
    dbus-user-session \
    fuse \
    kmod \
    locales \
    ssl-cert \
    sudo \
    udev \
    tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/* && \
    locale-gen en_US.UTF-8 && \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone




# RUN apt-get install -y tar untar

# Set locales
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

RUN apt-get update
RUN apt-get update && apt-get install --no-install-recommends -y \
    software-properties-common build-essential ca-certificates cups-browsed cups-bsd cups-common cups-filters printer-driver-cups-pdf \
    alsa-base alsa-utils file gnupg curl wget bzip2 gzip xz-utils unar zip unzip zstd gcc git dnsutils coturn jq \
    python3 python3-cups python3-numpy nano vim htop \
    fonts-dejavu fonts-freefont-ttf fonts-hack fonts-liberation fonts-noto fonts-noto-cjk fonts-noto-cjk-extra fonts-noto-color-emoji fonts-noto-extra fonts-noto-ui-extra fonts-noto-hinted fonts-noto-mono fonts-noto-unhinted fonts-opensymbol fonts-symbola fonts-ubuntu \
    lame less libavcodec-extra libpulse0 supervisor net-tools packagekit-tools pkg-config mesa-utils mesa-va-drivers libva2 vainfo \
    vdpau-driver-all libvdpau-va-gl1 vdpauinfo mesa-vulkan-drivers vulkan-tools radeontop libvulkan-dev ocl-icd-libopencl1 clinfo \
    xkb-data xauth xbitmaps xdg-user-dirs xdg-utils xfonts-base xfonts-scalable xinit xsettingsd libxrandr-dev x11-xkb-utils x11-xserver-utils x11-utils x11-apps \
    xserver-xorg-input-all xserver-xorg-input-wacom xserver-xorg-video-all xserver-xorg-video-qxl \
    libc6-dev libpci3 libelf-dev libglvnd-dev libxau6 libxdmcp6 libxcb1 libxext6 libx11-6 libxv1 libxtst6 libdrm2 libegl1 libgl1 libopengl0 libgles1 libgles2 libglvnd0 libglx0 libglu1 libsm6 \
    nginx apache2-utils netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN curl -fsSL -o /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /tmp/miniconda.sh && \
    /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh



# Set environment variables for conda
ENV PATH=/opt/conda/bin:$PATH

# Create a new conda environment with Python 3.10
RUN conda create -y -n py310 python=3.10

# Activate the new environment and ensure it is used by default
RUN echo "source activate py310" > ~/.bashrc
ENV CONDA_DEFAULT_ENV=py310
ENV PATH=/opt/conda/envs/py310/bin:$PATH


# Test a Python command
RUN python -c "print('Hello, World!')"


# 3. Sanitize NGINX paths and log configuration
RUN sed -i -e 's/\/var\/log\/nginx\/access\.log/\/dev\/stdout/g' \
    -e 's/\/var\/log\/nginx\/error\.log/\/dev\/stderr/g' \
    -e 's/\/run\/nginx\.pid/\/tmp\/nginx\.pid/g' /etc/nginx/nginx.conf
RUN echo "error_log /dev/stderr;" >> /etc/nginx/nginx.conf

# 4. Add PipeWire & WirePlumber upstream repositories and their key
RUN mkdir -pm755 /etc/apt/trusted.gpg.d
RUN curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xFC43B7352BCC0EC8AF2EEB8B25088A0359807596" \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/pipewire-debian-ubuntu-pipewire-upstream.gpg
RUN mkdir -pm755 /etc/apt/sources.list.d
RUN echo "deb https://ppa.launchpadcontent.net/pipewire-debian/pipewire-upstream/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" \
    > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list"
RUN echo "deb https://ppa.launchpadcontent.net/pipewire-debian/wireplumber-upstream/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" \
    > "/etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list"

# 5. Update and install PipeWire and WirePlumber packages
RUN apt-get update
RUN apt-get install --no-install-recommends -y \
    pipewire \
    pipewire-alsa \
    pipewire-audio-client-libraries \
    pipewire-jack \
    pipewire-locales \
    pipewire-v4l2 \
    pipewire-vulkan \
    pipewire-libcamera \
    gstreamer1.0-libcamera \
    gstreamer1.0-pipewire \
    libpipewire-0.3-modules \
    libpipewire-module-x11-bell \
    libspa-0.2-bluetooth \
    libspa-0.2-jack \
    libspa-0.2-modules \
    wireplumber \
    wireplumber-locales \
    gir1.2-wp-0.5

# 6. Install additional packages for amd64 (x86_64) architectures
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
    intel-gpu-tools \
    nvtop \
    va-driver-all \
    i965-va-driver-shaders \
    intel-media-va-driver-non-free \
    va-driver-all:i386 \
    i965-va-driver-shaders:i386 \
    intel-media-va-driver-non-free:i386 \
    libva2:i386 \
    vdpau-driver-all:i386 \
    mesa-vulkan-drivers:i386 \
    libvulkan-dev:i386 \
    libc6:i386 \
    libxau6:i386 \
    libxdmcp6:i386 \
    libxcb1:i386 \
    libxext6:i386 \
    libx11-6:i386 \
    libxv1:i386 \
    libxtst6:i386 \
    libdrm2:i386 \
    libegl1:i386 \
    libgl1:i386 \
    libopengl0:i386 \
    libgles1:i386 \
    libgles2:i386 \
    libglvnd0:i386 \
    libglx0:i386 \
    libglu1:i386 \
    libsm6:i386; \
    fi

# 7. Conditionally install the nvidia-vaapi-driver if the OS version is newer than 20.04
RUN if [ "$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then \
    apt-get update && \
    apt-get install --no-install-recommends -y \
    meson \
    gstreamer1.0-plugins-bad \
    libffmpeg-nvenc-dev \
    libva-dev \
    libegl-dev \
    libgstreamer-plugins-bad1.0-dev && \
    NVIDIA_VAAPI_DRIVER_VERSION="$(curl -fsSL 'https://api.github.com/repos/elFarto/nvidia-vaapi-driver/releases/latest' \
    | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && \
    curl -fsSL "https://github.com/elFarto/nvidia-vaapi-driver/archive/v${NVIDIA_VAAPI_DRIVER_VERSION}.tar.gz" \
    | tar -xzf - && \
    mv -f nvidia-vaapi-driver* nvidia-vaapi-driver && \
    cd nvidia-vaapi-driver && \
    meson setup build && \
    meson install -C build && \
    rm -rf /tmp/*; \
    fi

# 8. Clean up APT caches and temporary files
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# 9. Add NVIDIA library paths to the dynamic linker configuration
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf
RUN echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# 10. Configure OpenCL manually
RUN mkdir -pm755 /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

# 11. Configure Vulkan manually
RUN VULKAN_API_VERSION=$(dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' \
    | grep -oP '[0-9]+(\.[0-9]+)(\.[0-9]+)') && \
    mkdir -pm755 /etc/vulkan/icd.d/ && \
    echo "{\n  \"file_format_version\" : \"1.0.0\",\n  \"ICD\": {\n    \"library_path\": \"libGLX_nvidia.so.0\",\n    \"api_version\" : \"${VULKAN_API_VERSION}\"\n  }\n}" \
    > /etc/vulkan/icd.d/nvidia_icd.json

# 12. Configure EGL manually
RUN mkdir -pm755 /usr/share/glvnd/egl_vendor.d/ && \
    echo "{\n  \"file_format_version\" : \"1.0.0\",\n  \"ICD\": {\n    \"library_path\": \"libEGL_nvidia.so.0\"\n  }\n}" \
    > /usr/share/glvnd/egl_vendor.d/10_nvidia.json


# Expose NVIDIA libraries and paths
ENV PATH="/usr/local/nvidia/bin${PATH:+:${PATH}}"
ENV LD_LIBRARY_PATH=""
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
# Make all NVIDIA GPUs visible by default
ENV NVIDIA_VISIBLE_DEVICES=all
# All NVIDIA driver capabilities should preferably be used, check `NVIDIA_DRIVER_CAPABILITIES` inside the container if things do not work
ENV NVIDIA_DRIVER_CAPABILITIES=all
# Disable VSYNC for NVIDIA GPUs
ENV __GL_SYNC_TO_VBLANK=0
# Set default DISPLAY environment
ENV DISPLAY=":20"

# Anything above this line should always be kept the same between docker-nvidia-glx-desktop and docker-nvidia-egl-desktop

# Default environment variables (default password is "mypasswd")
ENV DISPLAY_SIZEW=1920
ENV DISPLAY_SIZEH=1080
ENV DISPLAY_REFRESH=60
ENV DISPLAY_DPI=96
ENV DISPLAY_CDEPTH=24
ENV VIDEO_PORT=DFP
ENV KASMVNC_ENABLE=false
ENV SELKIES_ENCODER=nvh264enc
ENV SELKIES_ENABLE_RESIZE=false
ENV SELKIES_ENABLE_BASIC_AUTH=true

# Install Xorg
RUN apt-get update && apt-get install --no-install-recommends -y \
    xorg \
    xterm && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# Anything below this line should always be kept the same between docker-nvidia-glx-desktop and docker-nvidia-egl-desktop

# ---------------------- Install KDE + other GUI packages ---------------------
RUN mkdir -pm755 /etc/apt/preferences.d
RUN echo "Package: firefox*\nPin: version 1:1snap*\nPin-Priority: -1" \
    > /etc/apt/preferences.d/firefox-nosnap

RUN mkdir -pm755 /etc/apt/trusted.gpg.d
RUN curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x738BEB9321D1AAEC13EA9391AEBDF4819BE21867" \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/mozillateam-ubuntu-ppa.gpg

RUN mkdir -pm755 /etc/apt/sources.list.d
RUN echo "deb https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"') main" \
    > "/etc/apt/sources.list.d/mozillateam-ubuntu-ppa-$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '\"').list"

RUN apt-get update
RUN apt-get install --no-install-recommends -y \
    kde-baseapps \
    plasma-desktop \
    plasma-workspace \
    adwaita-icon-theme-full \
    appmenu-gtk3-module \
    ark \
    aspell \
    aspell-en \
    breeze \
    breeze-cursor-theme \
    breeze-gtk-theme \
    breeze-icon-theme \
    dbus-x11 \
    debconf-kde-helper \
    desktop-file-utils \
    dolphin \
    dolphin-plugins \
    enchant-2 \
    fcitx \
    fcitx-frontend-gtk2 \
    fcitx-frontend-gtk3 \
    fcitx-frontend-qt5 \
    fcitx-module-dbus \
    fcitx-module-kimpanel \
    fcitx-module-lua \
    fcitx-module-x11 \
    fcitx-tools \
    fcitx-hangul \
    fcitx-libpinyin \
    fcitx-m17n \
    fcitx-mozc \
    fcitx-sayura \
    fcitx-unikey \
    filelight \
    frameworkintegration \
    gwenview \
    haveged \
    hunspell \
    im-config \
    kwrite \
    kcalc \
    kcharselect \
    kdeadmin \
    kde-config-fcitx \
    kde-config-gtk-style \
    kde-config-gtk-style-preview \
    kdeconnect \
    kdegraphics-thumbnailers \
    kde-spectacle \
    kdf \
    kdialog \
    kfind \
    kget \
    khotkeys \
    kimageformat-plugins \
    kinfocenter \
    kio \
    kio-extras \
    kmag \
    kmenuedit \
    kmix \
    kmousetool \
    kmouth \
    ksshaskpass \
    ktimer \
    kwin-addons \
    kwin-x11 \
    libdbusmenu-glib4 \
    libdbusmenu-gtk3-4 \
    libgail-common \
    libgdk-pixbuf2.0-bin \
    libgtk2.0-bin \
    libgtk-3-bin \
    libkf5baloowidgets-bin \
    libkf5dbusaddons-bin \
    libkf5iconthemes-bin \
    libkf5kdelibs4support5-bin \
    libkf5khtml-bin \
    libkf5parts-plugins \
    libqt5multimedia5-plugins \
    librsvg2-common \
    media-player-info \
    okular \
    okular-extra-backends \
    plasma-browser-integration \
    plasma-calendar-addons \
    plasma-dataengines-addons \
    plasma-discover \
    plasma-integration \
    plasma-runners-addons \
    plasma-widgets-addons \
    print-manager \
    qapt-deb-installer \
    qml-module-org-kde-runnermodel \
    qml-module-org-kde-qqc2desktopstyle \
    qml-module-qtgraphicaleffects \
    qml-module-qt-labs-platform \
    qml-module-qtquick-xmllistmodel \
    qt5-gtk-platformtheme \
    qt5-image-formats-plugins \
    qt5-style-plugins \
    qtspeech5-flite-plugin \
    qtvirtualkeyboard-plugin \
    software-properties-qt \
    sonnet-plugins \
    sweeper \
    systemsettings \
    ubuntu-drivers-common \
    vlc \
    vlc-plugin-access-extra \
    vlc-plugin-notify \
    vlc-plugin-samba \
    vlc-plugin-skins2 \
    vlc-plugin-video-splitter \
    vlc-plugin-visualization \
    xdg-user-dirs \
    xdg-utils \
    firefox \
    transmission-qt
RUN apt-get install --install-recommends -y \
    libreoffice \
    libreoffice-kf5 \
    libreoffice-plasma \
    libreoffice-style-breeze
RUN xdg-settings set default-web-browser firefox.desktop
RUN update-alternatives --set x-www-browser /usr/bin/firefox

# RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
#     cd /tmp && \
#     curl -o google-chrome-stable.deb -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_$(dpkg --print-architecture).deb" && \
#     apt-get update && \
#     apt-get install --no-install-recommends -y ./google-chrome-stable.deb && \
#     rm -f google-chrome-stable.deb && \
#     sed -i '/^Exec=/ s/$/ --password-store=basic --in-process-gpu/' /usr/share/applications/google-chrome.desktop; \
#     fi

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

# ------------------------ Fix KDE startup perms issues -----------------------
RUN MULTI_ARCH=$(dpkg --print-architecture | sed -e 's/arm64/aarch64-linux-gnu/' \
    -e 's/armhf/arm-linux-gnueabihf/' \
    -e 's/riscv64/riscv64-linux-gnu/' \
    -e 's/ppc64el/powerpc64le-linux-gnu/' \
    -e 's/s390x/s390x-linux-gnu/' \
    -e 's/i.*86/i386-linux-gnu/' \
    -e 's/amd64/x86_64-linux-gnu/' \
    -e 's/unknown/x86_64-linux-gnu/') && \
    cp -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit /tmp/ && \
    rm -f /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    cp -f /tmp/start_kdeinit /usr/lib/${MULTI_ARCH}/libexec/kf5/start_kdeinit && \
    rm -f /tmp/start_kdeinit

RUN echo "[Daemon]\nAutolock=false\nLockOnResume=false" \
    > /etc/xdg/kscreenlockerrc

RUN echo "[Compositing]\nEnabled=false" > /etc/xdg/kwinrc

RUN echo "[KDE]\nSingleClick=false\n\n[KDE Action Restrictions]\naction/lock_screen=false\nlogout=false\n\n[General]\nBrowserApplication=firefox.desktop" \
    > /etc/xdg/kdeglobals

# KDE environment variables
ENV DESKTOP_SESSION=plasma
ENV XDG_SESSION_DESKTOP=KDE
ENV XDG_CURRENT_DESKTOP=KDE
ENV XDG_SESSION_TYPE=x11
ENV KDE_FULL_SESSION=true
ENV KDE_SESSION_VERSION=5
ENV KDE_APPLICATIONS_AS_SCOPE=1
ENV KWIN_COMPOSE=N
ENV KWIN_EFFECTS_FORCE_ANIMATIONS=0
ENV KWIN_EXPLICIT_SYNC=0
ENV KWIN_X11_NO_SYNC_TO_VBLANK=1
# Use sudoedit to change protected files instead of using sudo on kwrite
# ENV SUDO_EDITOR=kwrite
# Enable AppImage execution in containers
ENV APPIMAGE_EXTRACT_AND_RUN=1
# Set input to fcitx
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XIM=fcitx
ENV XMODIFIERS="@im=fcitx"

# Install latest Selkies-GStreamer (https://github.com/selkies-project/selkies-gstreamer) build, Python application, and web application, should be consistent with Selkies-GStreamer documentation
ARG PIP_BREAK_SYSTEM_PACKAGES=1
RUN apt-get update && apt-get install --no-install-recommends -y \
    # GStreamer dependencies
    python3-pip \
    python3-dev \
    python3-gi \
    python3-setuptools \
    python3-wheel \
    libgcrypt20 \
    libgirepository-1.0-1 \
    glib-networking \
    libglib2.0-0 \
    libgudev-1.0-0 \
    alsa-utils \
    jackd2 \
    libjack-jackd2-0 \
    libpulse0 \
    libopus0 \
    libvpx-dev \
    x264 \
    x265 \
    libdrm2 \
    libegl1 \
    libgl1 \
    libopengl0 \
    libgles1 \
    libgles2 \
    libglvnd0 \
    libglx0 \
    wayland-protocols \
    libwayland-dev \
    libwayland-egl1 \
    wmctrl \
    xsel \
    xdotool \
    x11-utils \
    x11-xkb-utils \
    x11-xserver-utils \
    xserver-xorg-core \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxdamage1 \
    libxfixes3 \
    libxv1 \
    libxtst6 \
    libxext6 && \
    if [ "$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')" \> "20.04" ]; then apt-get install --no-install-recommends -y xcvt libopenh264-dev svt-av1 aom-tools; else apt-get install --no-install-recommends -y mesa-utils-extra; fi && \
    # Automatically fetch the latest Selkies-GStreamer version and install the components
    SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies-gstreamer/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).tar.gz" | tar -xzf - && \
    cd /tmp && curl -O -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && pip3 install --no-cache-dir --force-reinstall "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" "websockets<14.0" && rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    cd /opt && curl -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | tar -xzf - && \
    cd /tmp && curl -o selkies-js-interposer.deb -fsSL "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-js-interposer_v${SELKIES_VERSION}_ubuntu$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"')_$(dpkg --print-architecture).deb" && apt-get update && apt-get install --no-install-recommends -y ./selkies-js-interposer.deb && rm -f selkies-js-interposer.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*

COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod -f 755 /etc/entrypoint.sh
COPY selkies-gstreamer-entrypoint.sh /etc/selkies-gstreamer-entrypoint.sh
RUN chmod -f 755 /etc/selkies-gstreamer-entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod -f 755 /etc/supervisord.conf

# Configure coTURN script
RUN echo "#!/bin/bash\n\
    set -e\n\
    turnserver \
    --verbose \
    --listening-ip=\"0.0.0.0\" \
    --listening-ip=\"::\" \
    --listening-port=\"\${SELKIES_TURN_PORT:-3478}\" \
    --realm=\"\${TURN_REALM:-example.com}\" \
    --external-ip=\"\${TURN_EXTERNAL_IP:-\$(dig -4 TXT +short @ns1.google.com o-o.myaddr.l.google.com 2>/dev/null | { read output; if [ -z \"\$output\" ] || echo \"\$output\" | grep -q '^;;'; then exit 1; else echo \"\$(echo \$output | sed 's,\\\",,g')\"; fi } || dig -6 TXT +short @ns1.google.com o-o.myaddr.l.google.com 2>/dev/null | { read output; if [ -z \"\$output\" ] || echo \"\$output\" | grep -q '^;;'; then exit 1; else echo \"[\$(echo \$output | sed 's,\\\",,g')]\"; fi } || hostname -I 2>/dev/null | awk '{print \$1; exit}' || echo '127.0.0.1')}\" \
    --min-port=\"\${TURN_MIN_PORT:-49152}\" \
    --max-port=\"\${TURN_MAX_PORT:-65535}\" \
    --channel-lifetime=\"\${TURN_CHANNEL_LIFETIME:--1}\" \
    --lt-cred-mech \
    --user=\"selkies:\${TURN_RANDOM_PASSWORD:-\$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 24)}\" \
    --no-cli \
    --cli-password=\"\${TURN_RANDOM_PASSWORD:-\$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 24)}\" \
    --userdb=\"\${XDG_RUNTIME_DIR:-/tmp}/turnserver-turndb\" \
    --pidfile=\"\${XDG_RUNTIME_DIR:-/tmp}/turnserver.pid\" \
    --log-file=\"stdout\" \
    --allow-loopback-peers \
    \${TURN_EXTRA_ARGS} \$@\
    " > /etc/start-turnserver.sh && chmod -f 755 /etc/start-turnserver.sh

ENV PIPEWIRE_LATENCY="128/48000"
ENV XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
ENV PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
ENV PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
ENV PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

# dbus-daemon to the below address is required during startup
ENV DBUS_SYSTEM_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/tmp}/dbus-system-bus"

ENV SHELL=/bin/bash
ENV USER=root
ENV HOME=/home/root
WORKDIR /home/root

RUN printenv

RUN printenv > /etc/.env

# RUN ln -s /usr/bin/python3 /usr/bin/python
# RUN ln -s /usr/bin/pip3 /usr/bin/pip

EXPOSE 8080

# Install OpenSSH server
RUN apt-get update && apt-get install -y openssh-server

# Create SSH directory and set permissions
RUN mkdir /var/run/sshd

# Allow root login via SSH
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# Set root password
RUN echo 'root:rootpassword' | chpasswd

# Expose SSH port
EXPOSE 22




ENTRYPOINT ["/usr/bin/supervisord"]
