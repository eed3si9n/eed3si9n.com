---
title: "hashing bakeoff"
type: story
date: 2026-05-30
url: /hashing-bakeoff
tags: [ "sbt" ]
---

  [activator]: https://web.archive.org/web/20140323170739/typesafe.com/activator
  [part4]: /sudori-part4
  [part5]: /sudori-part5
  [part7]: /sudori-part7-client-side-run-with-sbt
  [sbt-remote-cache]: /sbt-remote-cache
  [sbt-2.0-ideas]: /sbt-2.0-ideas
  [sbt-server-reboot]: /sbt-server-reboot
  [rfc-4]: /rfc-4-persistent-worker

This is a blog post on sbt 2.x development, continuing from [sbt 2.x remote cache][sbt-remote-cache], [sudori part 4][part4], [part 5][part5], [part 7][part7] etc.

### background

Hashing comes up while developing sbt, often in the context of caching and incremental compilation. Basically when we have either a list of files or some parameters, we want to figure out if the calculation has ever been done before. That require hashing the inputs. It's a neat trick to be able to treat various shape of data as numbers.

The downside of this approach is that we are hashing things all the time, which takes time. In 2020, I ran a small experiment to hash 1000 JAR files on my laptop to compare hashing algorithms. This is how I settled on using non-cryptographic [FarmHash](https://opensource.googleblog.com/2014/03/introducing-farmhash.html) via [Zero-Allocation-Hashing (ZAHa)](https://github.com/openhft/zero-allocation-hashing) in sbt 1.x and Zinc 1.x [VirtualFile](https://github.com/sbt/zinc/pull/712).

Fast forward to 2026, the relevance of hashing has only increased as sbt 2.x attempts to cache more tasks. One issue with ZAHa is its use of `sun.misc.Unsafe`, which will be removed in future JDK:

```
WARNING: Please consider reporting this to the maintainers of class net.openhft.hashing.UnsafeAccess
WARNING: sun.misc.Unsafe::arrayBaseOffset will be removed in a future release
WARNING: A restricted method in java.lang.System has been called
```

### XXHash and WyHash

Since Scala 3.x and sbt 2.x are collectively leaping forward to JDK 17, we can port non-cryptographic hashing functions to Scala 3 using [Variable Handles](https://openjdk.org/jeps/193), or VarHandles.

In [sbt#9267](https://github.com/sbt/sbt/pull/9267) I've ported XXHash and WyHash to Scala 3.

### kcrypt/scala-blake3

I've added Kcrypt Lab's Blake3 implementation into the benchmark. The original C implementation of [Blake3](https://github.com/BLAKE3-team/BLAKE3) boasts impressive performance.

Blake3 can output a range of digest length, 64-bit or 256-bit. It's also a cryptographic hash that's recognized by Bazel cache system.

### FarmHash reimplementation

**2026-06-01 Update**: I've ported FarmHash to Scala 3 using VarHandles in [#9278](https://github.com/sbt/sbt/pull/9278).

### benchmarking hashing fuctions

Here's JMH benchmark result of hashing 2048 bytes on [GitHub Actions](https://github.com/sbt/sbt/actions/runs/26678487225/job/78634585318):

```
[info] Benchmark                                 Mode  Cnt     Score    Error  Units
[info] FarmHashHashBenchmark.hashByteArray       avgt    5     0.255 ±  0.001  us/op
[info] FarmHash64HashSbtBenchmark.hashByteArray  avgt    5     0.330 ±  0.002  us/op
[info] XXHash64HashBenchmark.hashByteArray       avgt    5     0.216 ±  0.001  us/op
[info] WyHash64HashBenchmark.hashByteArray       avgt    5     0.377 ±  0.002  us/op
[info] MurmurHash32HashBenchmark.hashByteArray   avgt    5     1.340 ±  0.007  us/op
[info] MurmurHash64HashBenchmark.hashByteArray   avgt    5     2.368 ±  0.020  us/op
[info] Blake3HashBenchmark.hashByteArray         avgt    5     6.639 ±  0.067  us/op
[info] Md5HashBenchmark.hashByteArray            avgt    5     7.936 ±  0.059  us/op
[info] Sha256HashBenchmark.hashByteArray         avgt    5     9.299 ±  0.103  us/op
```

I've included the current ZAHa FarmHash as the baseline, as well as `scala.util.MurmurHash` from the Scala standard library, MD5, and SHA256. I sometimes wonder if MD5 can be a "non-cryptographic" hash. The result shows that FarmHash took `255 ns` to hash 2048 bytes. To normalize the score, we can convert it to GB/s:

|     Hash |  Score<br>(lower is better) |   GB/s |      Speedup |
|---------:|--------:|-------:|-------------:|
| FarmHash (ZAHa) | `0.255` | `7.48` |            `1` |
| FarmHash (sbt) | `0.330` | `5.78` |            `1.29x` slower |
| XXHash64 | `0.216` | `8.83` | `1.18x` faster |
| WyHash64 | `0.377` | `5.06` | `1.5x` slower  |
| MurmurHash32 (Scala.util) | `1.340` | `1.42` | `5.3x` slower  |
| MurmurHash64 | `2.368` | `0.805` | `9.3x` slower  |
| Blake3 (scala-blake3 3.1.2) | `6.639` | `0.287` | `26x` slower  |
| Md5Hash | `7.936` | `0.240` | `31x` slower  |
| Sha256 | `9.299` | `0.205` | `36x` slower  |

This doesn't necessarily mean that we'd be able to hash 7 GB in 1s, but it gives us a rough idea. This also shows that XXHash64 is faster than ZAHa FarmHash on GitHub Actions, and that non-crypograph hash functions are order of magnitude faster than MD5, Blake3, or SHA256.

I've reimplemented FarmHash64Na for situation where we need the same hashing result as before. Interestingly, the VarHandle implementation is at 5.78 GB/s, which is 1.29x slower than ZAHa.

### benchmarking the file hashes

Here is a hashing benchmark of hashing 1MB file:

```
[info] Benchmark                                Mode  Cnt     Score    Error  Units
[info] ImoXXHash64FileHashBenchmark.hashFile    avgt    5    26.312 ±  0.199  us/op
[info] ImoWyHash64FileHashBenchmark.hashFile    avgt    5    27.851 ±  0.046  us/op
[info] XXHash64FileHashBenchmark.hashFile       avgt    5   239.858 ±  1.517  us/op
[info] WyHash64FileHashBenchmark.hashFile       avgt    5   282.985 ±  1.474  us/op
[info] Sha1FileHashBenchmark.hashFile           avgt    5   783.139 ±  5.554  us/op
[info] Sha256FileHashBenchmark.hashFile         avgt    5   827.696 ±  3.025  us/op
[info] Blake3FileHashBenchmark.hashFile         avgt    5  3147.657 ±  1.786  us/op
```

ImoXXHash64 uses the [ImoHash](https://github.com/kalafut/imohash), which hashes only the beginning, middle, and the tail of the file. It would hash any file in approx `26` μs.

|         Hash |     Score<br>(lower is better) |   GB/s |
|-------------:|----------:|-------:|
|  ImoXXHash64 |  `26.312` | n/a |
| ImoWhyHash64 |  `27.851` | n/a |
|     XXHash64 | `239.858` | `4.1` |
|     WyHash64 | `282.985` | `3.5` |
|         Sha1 | `783.139` | `1.2` |
|       Sha256 | `827.696` | `1.2` |
| Blake3 (scala-blake3 3.1.2) | `3147.657` | `0.3` |

This shows that for file hashing, the difference between XXHash64 vs SHA256 difference isn't as dramatic.

Regardless, constant-time ImoHash would be significantly faster than either XXHash64 or SHA256. I'm a bit surprised that Blake3 is order-of-magnitude slower than everything else, including SHA256. I wonder if this is due to some GC that needs to be optimized out using VarHandle etc.

### see also hash4j

To drop the usage of ZAHa I've opted to port hashing functions to Scala myself, but there's also a Java library called [hash4j](https://github.com/dynatrace-oss/hash4j), which implements these functions. I have not tested them.

### summary

- Based on the microbenchmark of hashing 2048 byte array and 1MB file, handrolled XXHash64 out-performed the FarmHash (ZAHa) in the array case, as well as SHA1 or SHA256 hash in the file case.
- XXHash64 consistently out-performed WyHash64.
- Blake3 (scala-blake3 3.1.2) did better than SHA256 in the array case, but significantly worse for 1MB file hashing.
- For constant-time file hashing, ImoHash-like jumping can be combined with an existing hashing function.

  [benchmark1]: https://github.com/sbt/sbt/actions/runs/26618072165/job/78437915695
