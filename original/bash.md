### copy array

<code>
arr1=(foo bar "foo 1" "bar two")
arr2=("${arr1[@]}")
</code>

### how to return an array

<code>
f () { local retarr; retarr=(foo bar "foo 1" "bar two"); declare -p retarr; }
# substitute arr2 with the array name you want
miniscript=$(f) && eval ${miniscript/retarr/arr2}
</code>
