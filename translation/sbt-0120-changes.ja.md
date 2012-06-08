[#304]: https://github.com/harrah/xsbt/issues/304
[#315]: https://github.com/harrah/xsbt/issues/315
[#327]: https://github.com/harrah/xsbt/issues/327
[#335]: https://github.com/harrah/xsbt/issues/335
[#393]: https://github.com/harrah/xsbt/issues/393
[#396]: https://github.com/harrah/xsbt/issues/396
[#380]: https://github.com/harrah/xsbt/issues/380
[#389]: https://github.com/harrah/xsbt/issues/389
[#388]: https://github.com/harrah/xsbt/issues/388
[#387]: https://github.com/harrah/xsbt/issues/387
[#386]: https://github.com/harrah/xsbt/issues/386
[#378]: https://github.com/harrah/xsbt/issues/378
[#377]: https://github.com/harrah/xsbt/issues/377
[#368]: https://github.com/harrah/xsbt/issues/368
[#394]: https://github.com/harrah/xsbt/issues/394
[#369]: https://github.com/harrah/xsbt/issues/369
[#403]: https://github.com/harrah/xsbt/issues/403
[#412]: https://github.com/harrah/xsbt/issues/412
[#415]: https://github.com/harrah/xsbt/issues/415
[#420]: https://github.com/harrah/xsbt/issues/420
[#462]: https://github.com/harrah/xsbt/pull/462
[#472]: https://github.com/harrah/xsbt/pull/472
[Launcher]: https://github.com/harrah/xsbt/wiki/Launcher

# sbt 0.12 の変更点

## 0.11.2 から 0.12.0 までの変更点

 * プラグイン設定ディレクトリの優先順位。 (詳細は以下の項目)
 * JLine 1.0 (詳細は以下の項目)
 * ソース依存性の修正。 (詳細は以下の項目)
 * 並列実行の制御の改善。 (詳細は以下の項目)
 * sbt 0.12 以降と Scala 2.10 以降のクロスビルド規約の変更。 (詳細は以下の項目)
 * 集約がより柔軟になった。 (詳細は以下の項目)
 * タスク軸の構文が <code>key(for task)</code> から <code>task::key</code> へと変更された。 (詳細は以下の項目)
 * sbt の organization が <code>org.scala-sbt</code> へと変更された。(元は、org.scala-tools.sbt) 特に、scripted プラグインのユーザはこの影響を受ける。
 * <code>test-quick</code> ([#393]) は引数で指定されたテスト（引数がない場合は全てのテスト）のうち以下の条件を一つでも満たすものを実行する:
  1. まだ実行されていない。
  2. 前回実行時に失敗した。
  3. 最後に成功した後で間接的にでも依存するコードが再コンパイルされた場合。
 * 引数のクオート ([#396])
  * <code>> command "空白 のある 引数\n エスケープは解釈される"</code>
  * <code>> command """空白 のある 引数\n エスケープは解釈されない"""</code>
  *  最初のリテラルは Windows のパス記号であるバックスラッシュをエスケープ (<code>\\</code>) する必要があることに注意。2つ目のリテラルを使えばその必要は無い。
  * バッチモードから使う場合は、ダブルクオートそのものをシェルからエスケープする必要がある。
 * <code>help</code> コマンドは正規表現を受け付け、ヘルプの検索を行うことができるようになった。詳細は <code>help help</code> を参照。
 * sbt プラグインリポジトリがプラグインとプラグインの定義にデフォルトで加わった。 [#380]
 * Ctrl+Z で停止した後 JLine を正しくリセットするようにした。(Unix のみ) [#394]
 * <code>session save</code> は <code>build.sbt</sbt> 内の設定を（適切な時に）上書きするようにした。[#369]
 * その他の修正および機能改善: [#368], [#377], [#378], [#386], [#387], [#388], [#389]
 * テストのフォークのサポート。 ([#415])
 * 直接実行された場合、強制的に <code>update</code> を実行するようにした。 ([#335])
 * 一時的に他のビルドと作業したい時は <code>projects add/remove <URI></code>。
 * 再コンパイルをせずに unchecked と deprecation の警告を表示する <code>print-warnings</code> タスクを追加した。(Scala 2.10+ のみ)
 * <code>help</code> と <code>task</code> コマンドの様々な改善、および新たな <code>settings</code> コマンド。([#315])
 * Java ソースの親の検知の修正。
 * `update-sbt-classifiers` に用いられる resolver の修正。([#304])
 * プラグインの自動インポートの修正。([#412]) 
 * 多くのアーティファクトの POM が repo.typesafe.com の仮想リポジトリから入手できるようになった。 ([#420])
 * jsch バージョンを 0.1.46 へと更新。 ([#403])
 * Ivy 設定ファイルを URL から読み込めるようにした。
 * リポジトリ設定のグローバルなオーバライドをサポートした。 ([#472]) <code>[repositories]</code> 項目を <code>~/.sbt/repositoreies</code> に書いて、sbt に <code>-Dsbt.override.build.repos=true</code> を渡すことでリポジトリを定義する。([Launcher] のページを参照) ランチャーが sbt と Scala を取得し、sbt がプロジェクトの依存性を取得するのにファイルで指定されたリポジトリが使われるようになる。 (@jsuereth)
 * ランチャーが 0.7.0 以降全ての sbt を起動できるようになった。
 * スタックトレースが抑制された場合、`last` を呼ぶようにより洗練されたヒントが表示されるようになった。
 * Java 7 の Redirect.INHERIT を用いて子プロセスの入力ストリームを継承するようになった。 ([#462],[#327]). これでインタラクティブなプログラムをフォークした場合に起こる問題が解決されるはず。 (@vigdorchik)
 * 再帰的にディレクトリを削除するときに、シンボリックリンクが指す先のコンテンツを削除しないようにした。
 * [新サイト](http://www.scala-sbt.org/)の [howto](http://www.scala-sbt.org/howto.html) ページを読みやすくした。
 * スナップショットやマイルストーンにもクロスビルドにはバイナリバージョンを用いることになった。ユーザが Scala もしくは sbt リリースの安定版とスナップショットに対して同じ安定版を publish しないことを当てにする。
 * 差分コンパイルを組み込むための API。このインターフェイスは今後変更する可能性があるが、既に [scala-maven-plugin のブランチ](https://github.com/davidB/scala-maven-plugin/tree/feature/sbt-inc)で利用されている。
 * Scala コンパイラの常駐の実験的サポート。 sbt に <code>-Dsbt.resident.limit=n</code> を渡すことで設定を行う。<code>n</code> は常駐させるコンパイラの最大数。

## 大きな変更の詳細点

## Plugin configuration directory

In 0.11.0, plugin configuration moved from `project/plugins/` to just `project/`, with `project/plugins/` being deprecated.  Only 0.11.2 had a deprecation message, but in all of 0.11.x, the presence of the old style `project/plugins/` directory took precedence over the new style.  In 0.12.0, the new style takes precedence.  Support for the old style won't be removed until 0.13.0.

  1. Ideally, a project should ensure there is never a conflict.  Both styles are still supported, only the behavior when there is a conflict has changed.  
  2. In practice, switching from an older branch of a project to a new branch would often leave an empty `project/plugins/` directory that would cause the old style to be used, despite there being no configuration there.
  3. Therefore, the intention is that this change is strictly an improvement for projects transitioning to the new style and isn't noticed by other projects.

## JLine

Move to jline 1.0.  This is a (relatively) recent release that fixes several outstanding issues with jline but, as far as I can tell, remains binary compatible with 0.9.94, the version previously used. In particular:

  1. Properly closes streams when forking stty on unix.
  2. Delete key works on linux.  Please check that this works for your environment as well.
  3. Line wrapping seems correct.

## Parsing task axis

There is an important change related to parsing the task axis for settings and tasks that fixes [#202](https://github.com/harrah/xsbt/issues/202)

  1. The syntax before 0.12 has been `{build}project/config:key(for task)`
  2. The proposed (and implemented) change for 0.12 is `{build}project/config:task::key`
  3. By moving the task axis before the key, it allows for easier discovery (via tab completion) of keys in plugins.
  4. It is not planned to support the old syntax.  It would be ideal to deprecate it first, but this would take too much time to implement.

## Aggregation

Aggregation has been made more flexible.  This is along the direction that has been previously discussed on the mailing list.

  1. Before 0.12, a setting was parsed according to the current project and only the exact setting parsed was aggregated.
  2. Also, tab completion did not account for aggregation.
  3. This meant that if the setting/task didn't exist on the current project, parsing failed even if an aggregated project contained the setting/task.
  4. Additionally, if compile:package existed for the current project, *:package existed for an aggregated project, and the user requested 'package' run (without specifying the configuration) *:package wouldn't be run on the aggregated project (it isn't the same as the compile:package key that existed on the current).
  5. In 0.12, both of these situations result in the aggregated settings being selected.  For example,
    1. Consider a project `root` that aggregates a subproject `sub`.
    2. `root` defines `*:package`.
    3. `sub` defines `compile:package` and `compile:compile`.
    4. Running `root/package` will run `root/*:package` and `sub/compile:package`
    5. Running `root/compile` will run `sub/compile:compile`
  6. This change depends on the change to parsing the task axis.

## Parallel Execution

Fine control over parallel execution is supported as described here: https://github.com/harrah/xsbt/wiki/Parallel-Execution

  1. The default behavior should be the same as before, including the `parallelExecution` settings.
  2. The new capabilities of the system should otherwise be considered experimental.
  3. Therefore, `parallelExecution` won't be deprecated at this time.

## Source dependencies

A fix for issue [#329](https://github.com/harrah/xsbt/issues/329) is included.  This fix ensures that only one version of a plugin is loaded across all projects.  There are two parts to this.

  1. The version of a plugin is fixed by the first build to load it.  In particular, the plugin version used in the root build (the one in which sbt is started in) always overrides the version used in dependencies.
  2. Plugins from all builds are loaded in the same class loader.

Additionally, Sanjin's patches to add support for hg and svn URIs are included.

  1. sbt uses subversion to retrieve URIs beginning with `svn` or `svn+ssh`.  An optional fragment identifies a specific revision to checkout.
  2. Because a URI for mercurial doesn't have a mercurial-specific scheme, sbt requires the URI to be prefixed with `hg:` to identify it as a mercurial repository.
  3. Also, URIs that end with `.git` are now handled properly.

## Cross building

The cross version suffix is shortened to only include the major and minor version for Scala versions starting with the 2.10 series and for sbt versions starting with the 0.12 series.  For example, `sbinary_2.10` for a normal library or `sbt-plugin_2.10_0.12` for an sbt plugin.  This requires forward and backward binary compatibility across incremental releases for both Scala and sbt.

  1. This change has been a long time coming, but it requires everyone publishing an open source project to switch to 0.12 to publish for 2.10 or adjust the cross versioned prefix in their builds appropriately.
  2. Obviously, using 0.12 to publish a library for 2.10 requires 0.12.0 to be released before projects publish for 2.10.
  3. At the same time, sbt 0.12.0 itself should be published against 2.10.0 or else it will be stuck in 2.9.x for the 0.12.x series.
  4. There is now the concept of a binary version.  This is a subset of the full version string that represents binary compatibility.  That is, equal binary versions implies binary compatibility.  All Scala versions prior to 2.10 use the full version for the binary version to reflect previous sbt behavior.  For 2.10 and later, the binary version is `<major>.<minor>`.
  5. The cross version behavior for published artifacts is configured by the crossVersion setting.  It can be configured for dependencies by using the `cross` method on `ModuleID` or by the traditional %% dependency construction variant.  By default, a dependency has cross versioning disabled when constructed with a single % and uses the binary Scala version when constructed with %%.
  6. For snapshot/milestone versions of Scala or sbt (as determined by the presence of a '-' in the full version), dependencies use the binary Scala version by default, but any published artifacts use the full version.  The purpose here is to ensure that versions published against a snapshot or milestone do not accidentally pollute the compatible universe.  Note that this means that declaring a dependency on a version published against a milestone requires an explicit change to the dependency definition.
  7. The artifactName function now accepts a type ScalaVersion as its first argument instead of a String.  The full type is now `(ScalaVersion, ModuleID, Artifact) => String`.  ScalaVersion contains both the full Scala version (such as 2.10.0) as well as the binary Scala version (such as 2.10).
  8. The flexible version mapping added by Indrajit has been merged into the `cross` method and the %% variants accepting more than one argument have been deprecated.  Some examples follow.

These are equivalent:

```scala
"a" % "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.Disabled
```

These are equivalent:

```scala
"a" %% "b" % "1.0"
"a" % "b" % "1.0" cross CrossVersion.binary
```

This uses the full Scala version instead of the binary Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.full
```

This uses a custom function to determine the Scala version to use based on the binary Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.binaryMapped {
  case "2.9.1" => "2.9.0" // remember that pre-2.10, binary=full
  case x => x
}
```

This uses a custom function to determine the Scala version to use based on the full Scala version:

```scala
"a" % "b" % "1.0" cross CrossVersion.fullMapped {
  case "2.9.1" => "2.9.0"
  case x => x
}
```

Using a custom function is used when cross-building and a dependency isn't available for all Scala versions.  This feature should be less necessary with the move to using a binary version.

### Binary sbt plugin dependency declarations in 0.12.0-M2

Declaring sbt plugin dependencies, as declared in sbt 0.11.2, will not work 0.12.0-M2. Instead of declaring a binary sbt plugin dependency within your plugin definition with:

```scala
  addSbtPlugin("a" % "b" % "1.0")
```

You instead want to declare that binary plugin dependency with:

```scala
libraryDependencies +=
  Defaults.sbtPluginExtra("a" % "b" % "1.0, "0.12.0-M2", "2.9.1")
```

This will only be an issue with binary plugin dependencies published for milestone releases of sbt going forward.

For convenience in future releases, a variant of `addSbtPlugin` will be added to support a specific sbt version with

```scala
  addSbtPlugin("a" % "b" % "1.0", sbtVersion = "0.12.0-M2")
```
