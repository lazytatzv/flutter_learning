## 経緯
一昨日までロボコン直前で切羽詰まっていて、コード書いたりロボットの調整したりと若干忙しかったのですが、ようやく開放されたということで、なんとなくロボットをGUIから動かしたいという欲求からFlutterを始めたという感じです。

## 前提条件
プログラミング経験があり、Docker, Linux, ROS2の基本を知っているとスムーズです。

## ホスト環境
本稿では Docker を使います。筆者の環境は以下の通りです。
- OS: Arch Linux (rolling)
- DE: GNOME

注: macOS / Windows では Docker のネットワーク挙動や X11/Wayland の取り扱いが異なるため、記事中の手順は Linux 向けの補足が中心です。


## Flutterとは？
ご存知の方も多いと思いますが、Googleが開発しているUIフレームワークです。Qtとか、ReactNativeとか、そういう類のモノです。使用言語はDart。JavaとJavaScriptを足して2で割った感じです。C++とかC#とか、その辺の言語を使っている人なら簡単だと思います。FWの学習コストは割と低めに感じます(ド素人なので何とも言えない)

https://dart.dev/language

https://flutter.dev/


# 何故にFlutter？
クロスプラットフォーム開発に強い。私は基本Android、またLinuxをよく使うのですが、実際の所殆どの人はiPhoneですし、macOSユーザもそれなりにいます。専らiOS用のアプリならSwift、Android用ならKotlin/Javaだと思いますが、クロスプラットフォームを実現したいなら割と有力な選択肢かなと。

## rosbridge_suiteとは？
rosbridge_suite は RobotWebTools が提供するツール群で、ROS と非 ROS クライアント（ブラウザや他言語アプリ）を WebSocket + JSON を使って接続するための実装です。典型的にはコンテナやホスト上で `rosbridge_server` を起動し、外部クライアントが WebSocket 経由でトピックの subscribe/publish、サービス呼び出し、パラメータ操作などを JSON フォーマットで行えるようにします。

主なポイント:
- WebSocket（通常ポート 9090）で ROS の操作を JSON メッセージとして送受信できる。
- ブラウザや Flutter、Node.js、Python 等、ROS ネイティブでない環境からも容易に接続できる。
- メッセージは ROS のメッセージ構造に合わせた JSON 形式になる（例: std_msgs/msg/String の data フィールドなど）。

注意: rosbridge はデフォルトで認証や暗号化を行わないので、外部に公開する場合は TLS（リバースプロキシでの HTTPS 化）や認証、ネットワーク制限を行う必要があるかもしれません。

公式: https://github.com/RobotWebTools/rosbridge_suite


## 本題

まず、ros2とflutterの環境を整えるのですが、単にArchLinuxにros2を入れるのが厳しいのと、環境を持ち運べるメリットを加味してDockerを使わせていただきます。特にflutter周りは詰まりやすいと思うので、普通は無理にDockerを使う必要はないと思います。

### ディレクトリ構成

今回は簡単の為にdemo_nodes_cppを使うので、ROSのworkspaceは省略しています。
flutter, ros2ディレクトリはmkdirしてください。

```
.
├── docker-compose.yml
├── flutter
│   ├── Dockerfile # Flutter用
│   └── my_app # Flutterのプロジェクト (後でflutter createで作る)
└─── ros2
    └── Dockerfile # ROS2用

```

## Docker 用のファイルを揃える

私が書いたテキトーなファイルなので参考程度に。恐らくそのまま使うのは厳しいです。

### docker-compose.yml
```
services:
  flutter:
    build:
      context: ./flutter
      dockerfile: Dockerfile
    volumes:
      - ./flutter:/app
      - /tmp/.X11-unix:/tmp/.X11-unix # X11転送
      - $HOME/Android/Sdk:/opt/android-sdk # Android SDK

  # network_mode: "host" を使うとコンテナはホストのネットワークを共有します。
  # - 便利: ポートマッピング不要でローカルのサービスに接続しやすい
  # - 注意: コンテナ名での名前解決（例: ws://ros2:9090）は働かないため、接続先は localhost やホストの IP を使う必要があります。
  # macOS/Windows では host モードが制限されるため、その場合は user-defined ブリッジネットワークを使いサービス名で接続する方法に切り替えてください。
  network_mode: "host"
    working_dir: /app
    privileged: true
    stdin_open: true
    tty: true
    environment:
      - DISPLAY=${DISPLAY}
    depends_on:
      - ros2

  ros2:
    build:
      context: ./ros2
      dockerfile: Dockerfile
    volumes:
      - ./ros2:/root/ros_ws
      - /tmp/.X11-unix:/tmp/.X11-unix # X11転送
    working_dir: /root/ros_ws
    tty: true
    privileged: true
    environment:
      - CCACHE_DIR=/root/.ccache
      - PATH="/usr/lib/ccache:$PATH"
      - CCACHE_MAXSIZE=30G
      - DISPLAY=${DISPLAY}
    network_mode: "host"

```
#### 注意 (X11 と表示)
Docker 越しに GUI を使う場合、X11 ソケットを共有し DISPLAY を渡す方法が簡単です。


```fish
xhost +local:docker
```

注: macOS / Windows では X11 ソケットの扱いが異なるため、別途手順が必要です。

### Dockerfile (for Flutter)

転がっていたflutterのイメージをベースにしていたのですが、古かったようなのでgithubから自分で取ってくることにしました。archlinuxベースなのは完全に宗教上の問題です。fishシェルも私が好きだから採用しているだけです。他のOSベースでも基本は変わらないと思います。

```Dockerfile
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

# PATH
ENV PATH=$JAVA_HOME/bin:/home/tatzv/flutter/bin:/home/tatzv/flutter/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH


# Flutter 安定チャンネル & upgrade
RUN flutter channel stable
RUN flutter upgrade

CMD ["fish"]

```
#### 注意
ユーザを作らずにrootのままだと恐らく途中でエラーが出ます。Flutter側はマストです。

### Dockerfile (for ros2)

```Dockerfile
FROM osrf/ros:humble-desktop

# 注意: 使用する ROS 2 ディストリビューション(humble / iron / ...)に合わせてイメージを選んでください。
RUN apt-get update && apt-get install -y \
  fish \
  vim \
  git \
  less \
  sudo \
  tmux \
  fzf \
  lsof \
  ccache \
  ros-jazzy-rosbridge-server \
  && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc

WORKDIR /root/ros_ws

CMD ["bash"]

```
### Docker Build

```bash
# docker-compose.yml があるディレクトリにいることを確認
$ docker compose build  # 初回は時間がかかります

$ docker compose up -d   # 起動

$ docker compose ps      # コンテナ起動確認
```

### ROS2側

```bash
# コンテナに入る（例）
$ docker compose exec -it ros2 bash

# ===== ここからコンテナ内 =====

$ ros2  # ros2 CLI が利用できるか確認。shell が起動時に setup.bash を読み込んでいない場合は手動で読み込む
# 例: source /opt/ros/jazzy/setup.bash

# rosbridge を起動します（Default Portは9090）
$ ros2 launch rosbridge_server rosbridge_websocket_launch.xml &

# テスト用に demo の talker を起動
$ ros2 run demo_nodes_cpp talker
# コンソールにメッセージが表示されれば publish は成功しています。
```

### flutter側

```bash

# Flutter 側コンテナに入る（例）
$ docker compose exec -it flutter fish

# ===== ここからコンテナ内 =====

# プロジェクトを作成
$ flutter create my_app

$ cd my_app # 作成したディレクトリに移動


$ flutter pub get   # 依存関係を取得

# 実行: エミュレータや接続したデバイスでアプリが起動すれば成功
$ flutter run

注: `flutter run` はホストのデバイスやエミュレータに依存します。Android 実機やエミュレータを使う場合は、Android SDK が正しくマウントされ、`flutter doctor` で問題がないことを確認してください。

```



### my_app/lib/main.dart

```dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROS2 Flutter Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _rosMessage = 'No data';

  @override
  void initState() {
    super.initState();
    _connectToRos();
  }

  void _connectToRos() async {
    try {
      final ws = await WebSocket.connect('ws://ros2:9090');
      ws.add(jsonEncode({
        "op": "subscribe",
        "topic": "/chatter",
        "type": "std_msgs/msg/String"
      }));

      ws.listen((data) {
        final msg = jsonDecode(data);
        setState(() {
          _rosMessage = msg['msg']['data'] ?? 'No data';
        });
      });
    } catch (e) {
      print('WebSocket error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROS2 Flutter Demo')),
      body: Center(
        child: Text(
          _rosMessage,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

```



