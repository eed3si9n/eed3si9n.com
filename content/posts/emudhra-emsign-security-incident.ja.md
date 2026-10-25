---
title: "eMudhra/emSign 中間CA証明書のセキュリティ・インシデントに関する Java/Scala 関連のお知らせ (CVE-2026-91403)"
type: story
date: 2026-10-25
url: /ja/emudhra-emsign-security-incident
tags: [ "scala" ]
---

eMudhra/emSign 中間CA証明書のインシデントに関する概要や一次情報としては、Mozilla社のエンジニアが始めた [eMudhra Intermediate CA Compromise](https://emudhra.we-have-a-problem.com/) がまとまっていて、[eMudhra中間CA証明書の秘密鍵の侵害について](https://emudhra.we-have-a-problem.com/ja.html)として要約も和訳されている:

> eMudhra中間CA証明書の秘密鍵が8件侵害されました。これらの証明書は，Mozilla，Microsoft，Apple，Chromeのルートプログラムで採用され，多くのトラストストアにも取り込まれたルート証明書につながっています。侵害された中間CAのいずれかの秘密鍵を持つ攻撃者は，任意のウェブサイトやサービスになりすますことができます。

HTTPS や mTLS は、エンドツーエンドで暗号化を行うことで、本来信頼性が低いインターネットのような環境でも安全な通信を行うことができているわけだが、そもそも送り先の末端が正規のサーバーなのかを確認するために、公開鍵暗号を予め信頼された認証局 (CA) によって署名しているという背景がある。「予め信頼された認証局」のリストは、ブラウザ、OS、プログラミング言語などのよって異なる。2026年10月17日に Firefox と Chrome が、危殆化した証明書を削除して、その後 Microsoft社、Apple社など各社の対応が進んでいる。JVM の場合は JVM そのものにリストが組み込まれている場合と、Linux のリストに委譲する 2パターンがある。Java では、この脆弱性は [CVE-2026-91403](https://www.oracle.com/security-alerts/alert-cve-2026-91403.html) という番号が与えられている。影響のある JDK は 8、11、17、21、25 と公表されているが、comodoaaaca を信用している JDK 7 なども危殆化した。

認証が危殆化しても、攻撃者が「なりすまし」をするには、ネットワークの乗っ取りも必要じゃないかと思われる人もいるかもしれないが、HTTPS が普及したことで野良 wifi に接続する心理的ハードルも下がったため、この状況で空港やカフェなどで wifi 機器を設置すれば乗っ取りが可能であるかもしれない。そこで Maven Central のみ詐称してもブラウザで開かなければ気付かないだろう。

### 自分に関係があるのかどうか

2026年10月22日以前に公開された JDK を使った場合、この脆弱性の影響を受けていると考えていいと思う。

今使っている JDK が、脆弱かどうか確認するためには [eed3si9n/emudhra-emsign-check](https://github.com/eed3si9n/emudhra-emsign-check) をローカル環境にチェックアウトして実行するか、ファイルをコピーして CI 環境で `CheckCompromisedCa.test` を呼び出すことができる。


```bash
$ sbt run
[info] welcome to sbt 1.13.0 (Azul Systems, Inc. Java 1.8.0_402)
[info] running main
Java 1.8.0_402 (/Users/xxx/.sdkman/candidates/java/zulu8.76.0.17-ca-jdk8.0.402-macosx_aarch64/zulu-8.jdk/Contents/Home/jre)
VULNERABLE (HTTP 200) https://dv-g3b-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://dv-g3c-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ov-g3b-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ov-g3c-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ev-g3b-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ev-g3c-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://dv-g3b-aaa-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://dv-g3c-aaa-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ov-g3b-aaa-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ov-g3c-aaa-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ev-g3b-aaa-emudhra.we-have-a-problem.com/
VULNERABLE (HTTP 200) https://ev-g3c-aaa-emudhra.we-have-a-problem.com/
[error] java.lang.RuntimeException: compromised CAs are in use, or we encountered a network error
[error]   at scala.sys.package$.error(package.scala:27)
[error]   at CheckCompromisedCa$.test(CheckCompromisedCa.scala:36)
[error]   at CheckCompromisedCa$.main(CheckCompromisedCa.scala:32)
[error]   at main.main(CheckCompromisedCa.scala:22)
[error]   at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
[error]   at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
[error]   at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[error]   at java.lang.reflect.Method.invoke(Method.java:498)
[error] stack trace is suppressed; run last Compile / run for the full output
[error] (Compile / run) compromised CAs are in use, or we encountered a network error
```

`https://dv-g3b-emudhra.we-have-a-problem.com/` は詐称された認証を使ったテスト用のサイトだが、それが HTTP 200 を返したということは、JDK が脆弱 (vulnerable) ということだ。

### 危殆化した証明書を手動で不信任とする

修正済みの JDK ディストリビューションに更新できるまでは、危殆化した証明書を手動で不信任とする (distrust) ことを勧める。

[distrust-emudhra.sh](https://github.com/eed3si9n/emudhra-emsign-check/blob/main/bin/distrust-emudhra.sh) をローカル環境もしくは CI にコピーして、`./distrust-emudhra.sh --dry-run $JAVA_HOME` で仮実行を行う:

```bash
$ java -version
openjdk version "17.0.12" 2024-07-16 LTS
OpenJDK Runtime Environment Zulu17.52+17-CA (build 17.0.12+7-LTS)
OpenJDK 64-Bit Server VM Zulu17.52+17-CA (build 17.0.12+7-LTS, mixed mode, sharing)
$ chmod +x distrust-emudhra.sh
$ ./distrust-emudhra.sh --dry-run $JAVA_HOME
(dry run — no changes will be made)
JAVA_HOME:   /Users/xxx/.jenv/versions/17.0
trust store: /Users/xxx/.jenv/versions/17.0/lib/security/cacerts
would remove:
  cert_91_emsign_root_ca___c191
  cert_92_emsign_ecc_root_ca___c392
  comodoaaaca [jdk]
  emsigneccrootcag3 [jdk]
  emsignrootcag1 [jdk]
  emsignrootcag2 [jdk]
remaining emSign/AAA entries (none expected, unless AAA deliberately kept):
cert_91_emsign_root_ca___c191, Jul 9, 2024, trustedCertEntry,
cert_92_emsign_ecc_root_ca___c392, Jul 9, 2024, trustedCertEntry,
comodoaaaca [jdk], Dec 31, 2003, trustedCertEntry,
emsigneccrootcag3 [jdk], Feb 18, 2018, trustedCertEntry,
emsignrootcag1 [jdk], Feb 18, 2018, trustedCertEntry,
emsignrootcag2 [jdk], Feb 18, 2018, trustedCertEntry,
```

次に、`--dry-run` 抜きで実行すると、実際の削除が行われる:

```bash
$ ./distrust-emudhra.sh $JAVA_HOME
JAVA_HOME:   /Users/xxx/.jenv/versions/17.0
trust store: /Users/xxx/.jenv/versions/17.0/lib/security/cacerts
Warning: use -cacerts option to access cacerts keystore
removed: cert_91_emsign_root_ca___c191
Warning: use -cacerts option to access cacerts keystore
removed: cert_92_emsign_ecc_root_ca___c392
Warning: use -cacerts option to access cacerts keystore
removed: comodoaaaca [jdk]
Warning: use -cacerts option to access cacerts keystore
removed: emsigneccrootcag3 [jdk]
Warning: use -cacerts option to access cacerts keystore
removed: emsignrootcag1 [jdk]
Warning: use -cacerts option to access cacerts keystore
removed: emsignrootcag2 [jdk]
remaining emSign/AAA entries (none expected, unless AAA deliberately kept):
  (none)
```

GitHub Actions を使っている場合は以下のようになる:

```yaml
    - name: Distrust compromised certs manually
      shell: bash
      run: |
        if [ "$RUNNER_OS" = "Windows" ]; then
          bash bin/distrust-emudhra.sh "$JAVA_HOME"
        else
          sudo -E bash bin/distrust-emudhra.sh "$JAVA_HOME"
        fi
```

[eed3si9n/emudhra-emsign-check](https://github.com/eed3si9n/emudhra-emsign-check)　を再実行して危殆化した証明書が無効となったことを確認する。もし成功すれば以下のようなアウトプットとなるはずだ:

```bash
$ sbt run
[info] running main
Java 17.0.12 (/Users/xxx/.sdkman/candidates/java/17.0.12-zulu/zulu-17.jdk/Contents/Home)
OK https://dv-g3b-emudhra.we-have-a-problem.com/
  SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
OK https://dv-g3c-emudhra.we-have-a-problem.com/
  SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
....
```

### 修正済みの JDK への更新

修正済みの JDK がリリースされしだい、更新することを推奨する。

|           JDK |  Oracle | Temurin |         Zulu |
|--------------:|--------:|--------:|-------------:|
|         JDK 8 | 8u511       | n/a     | 8u512-b08 |
|        JDK 11 | 11.0.33.0.2 | n/a     | 11.0.33+9 |
|        JDK 17 | 17.0.21.0.2 | 17.0.21+9 | 17.0.21+9  |
|        JDK 21 | 21.0.13.0.2 | 21.0.13+9 | 21.0.13+9 |
|        JDK 25 | 25.0.5.0.2 | 25.0.5+8 | 25.0.5+8 |
| Release notes |  |         | [Note](https://docs.azul.com/core/release/october-2026-respin/release-notes.html#) |

- **スタンドアローン JDK** (Coursier、SDKMAN!、Homebrew などを用いてインストールしたか、ベンダーから直接ダウンロードしたもの): 修正済みの JDK がリリースされ次第更新する。CI 環境や Docker イメージなどで使用している JDK も含む。
- **Linux ディストロによって提供される JDK** (Arch Linux、Debian、Fedora、Red Hat
  Enterprise Linux、Ubuntu など): これらはオペレーティング・システムの証明書に委譲するため、システムの CA証明局リストを更新する必要がある。

10月25日現在、[GitHub Actions](https://github.com/eed3si9n/emudhra-emsign-check/actions/runs/40123415266/job/121222090738) 上で setup-java を使った場合に修正済みの JDK が JDK 8、11、17、25 と出揃っているのは `zulu` つまり Azul社の Zulu JDK のみだ。

![](/images/emudhra-emsign-check_2026-10-24.png)

オープンソースでは Eclipse Temurin (旧AdoptOpenJDK) を使うのが定番だが、彼らは TCK (技術互換キット) を通過しているものをリリースするのが売りで、リリースに何日もかかっている ([temurin#317](https://github.com/adoptium/temurin/issues/317) で更新状況が見れる) ため、今回のようなゼロデイで全世界に脆弱性が明るみになった場合の対応の遅さが目立つ格好となっている。setup-java からも一部修正済みの JDK が使えるようになっているが、JDK11 はまだ、JDK 17 は ubuntu-latest と macos-latest は修正済みだが windows-latest は脆弱という感じだ。正式なリリースノートも出ていないためか、SDKMAN でも temurin は古いままだ。JDK 17 で ubuntu-latest と macos-latest だけあれば良いというのであれば、temurin 続行も可能だ。

SDKMAN! で Zulu の JDK 8 をインストールしようと思ったが、残念ながらまだ並んでいない:

```bash
$ sdk list java | rg zulu | rg '8\.'
                |     | 8.0.504+1          | 8.0.504+1-zulu
                |     | 8.0.502.fx         | 8.0.502.fx-zulu
```

### まとめ

- eMudhra/emSign 中間CA証明書が危殆化したしため、HTTPS などのなりすまし攻撃が可能となっていて、修正には ブラウザ、OS 及び、JDK での対応が必要。
- 大元の Oracle と OpenJDK は修正パッチを出したが、実際に setup-java で使用できるのは `zulu`。`temurin` は一部のみ。
- 修正版をインストールできるまでは、[distrust-emudhra.sh](https://github.com/eed3si9n/emudhra-emsign-check/blob/main/bin/distrust-emudhra.sh) などを使用して証明書を手動で不信任とするべき。
