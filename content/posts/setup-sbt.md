---
title: "setup-sbt GitHub Action"
type: story
date: 2024-06-22
url: /setup-sbt
tags: [ "sbt" ]
---

  [runner-images-9369]: https://github.com/actions/runner-images/issues/9369

I've created `sbt/setup-sbt` action to install the official `sbt` runner script and the launcher.

<!--more-->


### basic usage

Add this line to your YAML:

```yaml
- uses: sbt/setup-sbt@v1
```

This will download the official installer and installs `sbt`. For example:

```yaml
env:
  JAVA_OPTS: -Xms2048M -Xmx2048M -Xss6M -XX:ReservedCodeCacheSize=256M -Dfile.encoding=UTF-8
steps:
  - uses: actions/checkout@v4
  - name: Setup JDK
    uses: actions/setup-java@v4
    with:
      distribution: temurin
      java-version: 17
      cache: sbt
  - uses: sbt/setup-sbt@v1
  - name: Build and test
    shell: bash
    run: sbt -v +test
```

### before

![before](/images/setup-sbt-before.png)

### after

![after](/images/setup-sbt-after.png)

This confirms that `sbt` runner is on the PATH on `macos-13`, `macos-14`, and `ubuntu-24.04`.

### making of a custom GitHub Actions

In February 2024, GitHub released macOS 13 and 14 runner images, making it possible to run CI on ARM macs easily. However, people who started using it noticed that `sbt` runner script was missing from the new macOS images ([actions/runner-images#9369][runner-images-9369]). `ubuntu-24.04` is also missing `sbt` runner.

Follow [About custom actions](https://docs.github.com/en/actions/creating-actions/about-custom-actions) for the documentation of creating a custom GitHub Action. If you can express everything you want using Bash and other existing actions, you can create a _composite_ action, which is by default cross-platform.

setup-sbt is straightforward. It caches `setupsbt/` directory, downloads the official `.zip` file from GitHub Release, and make `sbt` available to PATH.

```yaml
name: "Setup sbt installer"
description: "Sets up sbt runner script"
inputs:
  sbt-runner-version:
    description: "The runner version (The actual version is controlled via project/build.properties)"
    required: true
    default: 1.10.3
runs:
  using: "composite"

  steps:
    - name: Set up cache paths
      id: cache-paths
      shell: bash
      run: |
        echo "sbt_toolpath=$RUNNER_TOOL_CACHE/sbt/${{ inputs.sbt-runner-version }}" >> "$GITHUB_OUTPUT"
        echo "sbt_downloadpath=$RUNNER_TEMP/_sbt" >> "$GITHUB_OUTPUT"

    - name: Check Tool Cache
      id: cache-tool-dir
      shell: bash
      run: |
        mkdir -p "${{ steps.cache-paths.outputs.sbt_toolpath }}"
        if [ -f "${{ steps.cache-paths.outputs.sbt_toolpath }}/sbt/bin/sbt" ]; then
          echo "cache-hit=true" >> "$GITHUB_OUTPUT"
        else
          echo "cache-hit=false" >> "$GITHUB_OUTPUT"
        fi

    - name: Cache sbt distribution
      id: cache-dir
      if: steps.cache-tool-dir.outputs.cache-hit != 'true'
      uses: actions/cache@v4
      with:
        path: ${{ steps.cache-paths.outputs.sbt_toolpath }}
        key: ${{ runner.os }}-sbt-${{ inputs.sbt-runner-version }}-1.1.4

    - name: "Download and Install sbt"
      shell: bash
      env:
        SBT_RUNNER_VERSION: ${{ inputs.sbt-runner-version }}
      if: steps.cache-tool-dir.outputs.cache-hit != 'true' && steps.cache-dir.outputs.cache-hit != 'true'
      run: |
        mkdir -p "${{ steps.cache-paths.outputs.sbt_downloadpath }}"
        curl -sL "https://github.com/sbt/sbt/releases/download/v$SBT_RUNNER_VERSION/sbt-$SBT_RUNNER_VERSION.zip" > \
          "${{ steps.cache-paths.outputs.sbt_downloadpath }}/sbt-$SBT_RUNNER_VERSION.zip"

        pushd "${{ steps.cache-paths.outputs.sbt_downloadpath }}"
        unzip -o "sbt-${{ inputs.sbt-runner-version }}.zip" -d "${{ steps.cache-paths.outputs.sbt_toolpath }}"
        popd

    - name: "Setup PATH"
      shell: bash
      run: |
        pushd "${{ steps.cache-paths.outputs.sbt_toolpath }}"
        ls sbt/bin/sbt
        echo "$PWD/sbt/bin" >> "$GITHUB_PATH"
        popd
```

### summary

Some newer runner images on GitHub Actions are now missing `sbt` runner script. `- uses: sbt/setup-sbt@v1` provides a one-liner workaround to this incovenience.
