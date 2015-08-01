I've been switching between Mac and Ubuntu, and between Java 6 and 7 lately.
This is a memo of how to switch Java versions on both Mac and Ubuntu.

**Update**: Yoshida-san told me about this thing called [jEnv](http://www.jenv.be/), which does all this.

### Zshrc

Here's one way of loading different shell files depending on the OS:

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

### environment variables

In `zshrc.osx` and `zshrc.linux` respectively you can define environment variables for Java 6, 7, and 8. Here's for Mac:

    export JAVA_1_6_HOME=`/usr/libexec/java_home -v 1.6`
    export JAVA_1_7_HOME=`/usr/libexec/java_home -v 1.7`
    export JAVA_1_8_HOME=`/usr/libexec/java_home -v 1.8`

and here's for Ubuntu:

    export JAVA_1_6_HOME="/usr/lib/jvm/java-1.6.0-openjdk-amd64"
    export JAVA_1_7_HOME="/usr/lib/jvm/java-1.7.0-openjdk-amd64"
    export JAVA_1_8_HOME="/usr/lib/jvm/java-8-oracle"

### aliases

To use the environment variables for a duration of one shell command, we can use `env` command. Define these in `zshrc.alias`.

    alias jdk6='env JAVA_HOME=$JAVA_1_6_HOME PATH=$JAVA_1_6_HOME/bin:"$PATH" JDK_SET="1"'
    alias jdk7='env JAVA_HOME=$JAVA_1_7_HOME PATH=$JAVA_1_7_HOME/bin:"$PATH" JDK_SET="1"'
    alias jdk8='env JAVA_HOME=$JAVA_1_8_HOME PATH=$JAVA_1_8_HOME/bin:"$PATH" JDK_SET="1"'

Here's how to use this:

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

For the duration of the command `jdk6 COMMAND` will run using JDK 6. If you want it for the duration of the session, you start a new shell as follows:

    $ jdk6 zsh
    $ java -version
    java version "1.6.0_65"
    Java(TM) SE Runtime Environment (build 1.6.0_65-b14-466.1-11M4716)
    Java HotSpot(TM) 64-Bit Server VM (build 20.65-b04-466.1, mixed mode)

If you've noticed that I'm setting `JDK_SET` variable, you'll see why soon.

### system-level Java

You might also be interested in switching the default JDK for the system. For Ubuntu, you can use:

    $ update-java-alternatives -l
    java-1.6.0-openjdk-amd64 1061 /usr/lib/jvm/java-1.6.0-openjdk-amd64
    java-1.7.0-openjdk-amd64 1071 /usr/lib/jvm/java-1.7.0-openjdk-amd64
    java-8-oracle 1072 /usr/lib/jvm/java-8-oracle
    $ sudo update-java-alternatives -s java-1.7.0-openjdk-amd64

The situation with Mac is weirder. To really change the system-level Java, you would have to find the latest installer and install it last to take effect. If you care only about how `java` runs in your terminal, the following should work:

    if [ -z "$JDK_SET" ]; then
      export JAVA_HOME=`/usr/libexec/java_home -v 1.7`
      export PATH=$JAVA_HOME/bin:$PATH
    fi

This checks if `$JDK_SET` has been set by us, and if not forces JDK 1.7.

