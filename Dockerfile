FROM cirrusci/flutter:latest

# 色々と欲しいものをインストール
RUN apt-get update && apt-get install -y \
    fish \
    git \
    vim \
    less \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリ
WORKDIR /app

CMD ["fish"]