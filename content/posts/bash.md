---
title:       "Bash memo"
type:        story
date:        2019-05-09
draft:       true
sticky:      false
url:         /bash
tags:        [ "bash" ]
---

### copy array

```bash
arr1=(foo bar "foo 1" "bar two")
arr2=("${arr1[@]}")
```

### how to return an array

```bash
f () { local retarr; retarr=(foo bar "foo 1" "bar two"); declare -p retarr; }
# substitute arr2 with the array name you want
miniscript=$(f) && eval ${miniscript/retarr/arr2}
```
