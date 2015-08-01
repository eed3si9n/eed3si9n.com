最近 Mac と Ubuntu、それから Java 6 と Java 7 を行ったり来たりしてる。
Java の切り替え方を統一したいので、ここにメモしておく。

**追記**: [jEnv](http://www.jenv.be/) という便利なものを Yoshida-san に教えてもらったので、それを使ったほうがいいかも。

### Zshrc

OS によるシェルスクリプトの切り替えはこんなふうにやってる:

    ## basic
    [ -f $HOME/dotfiles/zshrc.basic ] && source $HOME/dotfiles/zshrc.basic
     
    ## aliases
    [ -f $HOME/dotfiles/zshrc.alias ] && source $HOME/dotfiles/zshrc.alias
     
    case "${OSTYPE}" in
    # MacOSX
    darwin*)
      [ -f $HOME/dotfiles/zshrc.osx ] && source $HOME/dotfiles/zshrc.osx
      ;;
    # Linux
    linux*)
      [ -f $HOME/dotfiles/zshrc.linux ] && source $HOME/dotfiles/zshrc.linux
      ;;
    esac
     
    ## color
    [ -f $HOME/dotfiles/zshrc.color ] && source $HOME/dotfiles/zshrc.color

### 環境変数

`zshrc.osx` と `zshrc.linux` のそれぞれに Java 6、7、8用の環境変数を定義する。まずは Mac:

    export JAVA_1_6_HOME=`/usr/libexec/java_home -v 1.6`
    export JAVA_1_7_HOME=`/usr/libexec/java_home -v 1.7`
    export JAVA_1_8_HOME=`/usr/libexec/java_home -v 1.8`

次が Ubuntu:

    export JAVA_1_6_HOME="/usr/lib/jvm/java-1.6.0-openjdk-amd64"
    export JAVA_1_7_HOME="/usr/lib/jvm/java-1.7.0-openjdk-amd64"
    export JAVA_1_8_HOME="/usr/lib/jvm/java-8-oracle"

### エイリアス

この環境変数をシェルコマンド一回の実行する間だけに使うために、`env` コマンドを使う。以下を `zshrc.alias` にて定義する。

    alias jdk6='env JAVA_HOME=$JAVA_1_6_HOME PATH=$JAVA_1_6_HOME/bin:"$PATH" JDK_SET="1"'
    alias jdk7='env JAVA_HOME=$JAVA_1_7_HOME PATH=$JAVA_1_7_HOME/bin:"$PATH" JDK_SET="1"'
    alias jdk8='env JAVA_HOME=$JAVA_1_8_HOME PATH=$JAVA_1_8_HOME/bin:"$PATH" JDK_SET="1"'

使い方はこんな感じ:

    $ java -version
    java version "1.8.0_40-ea"
    Java(TM) SE Runtime Environment (build 1.8.0_40-ea-b23)
    Java HotSpot(TM) 64-Bit Server VM (build 25.40-b25, mixed mode)
    $ echo $JAVA_HOME
    /Library/Java/JavaVirtualMachines/jdk1.8.0_40.jdk/Contents/Home
    $ jdk6 java -version
    java version "1.6.0_65"
    Java(TM) SE Runtime Environment (build 1.6.0_65-b14-466.1-11M4716)
    Java HotSpot(TM) 64-Bit Server VM (build 20.65-b04-466.1, mixed mode)

`jdk6 COMMAND` のコマンドが走ってる間だけ、JDK 6 が使われるようになった。セッションごとずっと使いたければ新しいシェルを立ち上げればいい:

    $ jdk6 zsh
    $ java -version
    java version "1.6.0_65"
    Java(TM) SE Runtime Environment (build 1.6.0_65-b14-466.1-11M4716)
    Java HotSpot(TM) 64-Bit Server VM (build 20.65-b04-466.1, mixed mode)

`JDK_SET` という変数が何のためにいるのかは、次で説明する。

### システムレベル Java

システムレベルでのデフォルトの JDK を切り替えたい場合もあると思う。Ubuntu は以下で行える:

    $ update-java-alternatives -l
    java-1.6.0-openjdk-amd64 1061 /usr/lib/jvm/java-1.6.0-openjdk-amd64
    java-1.7.0-openjdk-amd64 1071 /usr/lib/jvm/java-1.7.0-openjdk-amd64
    java-8-oracle 1072 /usr/lib/jvm/java-8-oracle
    $ sudo update-java-alternatives -s java-1.7.0-openjdk-amd64

Mac の状況はもっと変な感じだ。本当にシステムレベルで Java を変更したい場合は、多分最新のインストーラーを探してきて、最後にインストールするというようなことを行わなければならないと思う。ただ、ターミナル上から見える `java` が何なのかしか気にしないのだったら以下でいけるはずだ:

    if [ -z "$JDK_SET" ]; then
      export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
      export PATH=$JAVA_HOME/bin:$PATH
    fi

これは、`$JDK_SET` が設定されてるかをチェックして、されてなければ JDK 1.7 を強制する。
