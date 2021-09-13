---
title:       "Jar Jar Abrams 1.8.0 and sbt-assembly 1.1.0"
type:        story
date:        2021-09-01
draft:       false
promote:     true
sticky:      false
url:         /jarjar-abrams-1.8.0-sbt-assembly-1.1.0
aliases:     [ /node/402 ]
tags:        [ "sbt" ]
---

Jar Jar Abrams 1.8.0 and sbt-assembly 1.1.0 are released.

[Jar Jar Abrams](https://eed3si9n.com/jarjar-abrams) is an experimental extension to Jar Jar Links, intended to shade Scala libraries. Thus far we have been using Pants team's fork of Jar Jar Links, but now that it's been abandaned, Eric Peters has in-sourced it to jarjar-abrams repo so we can patch it.

Our `jarjar` fork is released under `com.eed3si9n.jarjar` organization name and package name.

## bug fixes

- Eric has fixed a bug around `ShadeRules.keep`.

## enhancement

- ASM was updated to 9.2.

sbt-assembly 1.1.0 upgrades the Jar Jar Abrams dependency to 1.8.0.
