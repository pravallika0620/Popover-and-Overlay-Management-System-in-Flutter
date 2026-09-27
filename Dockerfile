# Containerized build environment for PopoverPro.
#
# Based on Debian + the Flutter SDK (stable channel), with the Android
# SDK/command-line tools needed to build a release APK.

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:$PATH

# --- System dependencies ---------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        openjdk-17-jdk-headless \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- Flutter SDK -------------------------------------------------------------
ARG FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} \
    && cd ${FLUTTER_HOME} \
    && git checkout ${FLUTTER_VERSION} \
    && flutter config --no-analytics \
    && flutter precache --android

# --- Android command-line tools ---------------------------------------------
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl --http1.1 --retry 5 --retry-delay 3 -sSLo /tmp/cmdline-tools.zip \
        https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

WORKDIR /app

# Pre-fetch pub packages when only the pubspec is present, so dependency
# resolution is cached across rebuilds that only change source files.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get || true

COPY . .
RUN flutter pub get

CMD ["flutter", "--version"]
