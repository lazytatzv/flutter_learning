# Arch ベース
FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    fish git vim less tmux unzip which sudo cmake ninja clang pkg-config gtk3 \
    && pacman -Scc --noconfirm

RUN echo "tatzv ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# ユーザー作成
RUN useradd -ms /usr/bin/fish tatzv
USER tatzv
WORKDIR /app

# Flutter SDK をユーザー権限で clone
RUN git clone https://github.com/flutter/flutter.git /home/tatzv/flutter
ENV PATH="/home/tatzv/flutter/bin:/home/tatzv/flutter/bin/cache/dart-sdk/bin:$PATH"

# stable チャンネル & upgrade
RUN flutter channel stable
RUN flutter upgrade

# 動作確認
RUN flutter doctor

CMD ["fish"]
