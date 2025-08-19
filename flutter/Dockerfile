# Arch ベース
FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    fish git vim less tmux unzip which sudo cmake ninja clang pkg-config gtk3 jdk-openjdk \
    && pacman -Scc --noconfirm

RUN echo "tatzv ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# ユーザー作成
RUN useradd -ms /usr/bin/fish tatzv
USER tatzv
WORKDIR /app

# Flutter SDK をユーザー権限で clone
RUN git clone https://github.com/flutter/flutter.git /home/tatzv/flutter

# Android SDK 環境変数
ENV ANDROID_SDK_ROOT=/opt/android-sdk

# Java
ENV JAVA_HOME=/usr/lib/jvm/java-24-openjdk

# PATH を一発で全部まとめる
ENV PATH=$JAVA_HOME/bin:/home/tatzv/flutter/bin:/home/tatzv/flutter/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH


# Flutter 安定チャンネル & upgrade
RUN flutter channel stable
RUN flutter upgrade

# 動作確認
RUN flutter doctor

CMD ["fish"]
