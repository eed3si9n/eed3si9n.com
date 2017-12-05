Over the weekend I assembled an Ergodox.

- Infinity ErgoDox Ergonomic Keyboard Kit via massdrop
- Cherry MX Brown switches
- Datamancer Infinity Ergodox Hardwood Case (Black Walnut / Original) via massdrop
- Plum Blossom PBT Dye-Subbed Keycap Set (OEM, Blank) via [massdrop](https://www.massdrop.com/buy/37996)

### The waiting process

I joined massdrops for the above items at the end of May, and it wasn't the end of October that I got all the items shipped, so there was 5 months of waiting involved. There was apprently some shipping confusion in this particular round, so the future drop might go faster. ymmv. There is also an easier solution literally called [EZ](https://ergodox-ez.com/pages/customize) that ships in 3 weeks. The price becomes comparable by excluding keycaps etc.

### Other things you would need

- Precision screwdriver set for snapping things. $5 one from Target is fine
- Hakko Digital FX888D & CHP170 bundle, includes Soldering Station & CHP170 cutter
- Hakko T18-C2 - T18 Series Soldering Tip for Hakko FX-888/FX-8801
- DMiotech 0.8mm 50G 63/37 Rosin Core Tin Lead Soldering Solder Wire

### The assembly

The assembly was a bit pluzzing to be honest, just from reading Input Club's [build guide](https://input.club/devices/infinity-ergodox/infinity-ergodox-build-guide/). But, since there was no spaying lacquer or soldering of diode involved, the whole process took me just a day.

The trickiest part of the assembly by far is putting 4 keys with a Costar stablizer (non-Filco style?). It might help to look for some YouTube videos on what a stablizer is to get the general idea on what's going on.

A Costar stablizer consists of the following parts:
- 1 wire
- 2 plate clips (U-shaped part with some notches)
- 2 keycap inserts (smaller part)

After some trial and error, here's what I started doing.

1. Install the plate clips. Following the official guide, the wire notches would point away from the LCD.
2. Pick out a 2u keycap. If they are sculpted, you have to decide which one you want to use where.
3. Put the keycap inserts into the keycaps, with the longer notch pointing away from the wire side.
4. Hook the wire into the keycap inserts.
5. Snap in a key switch into the board, matching the orientation of the holes on the PCB.
6. Put the keycap + wire combo on the switch. Make sure the key moves smoothly. If not you have to push the clips apart. People also put grease on.
7. Snap the wire into the notches using mini flathead screwdriver.

<a href='/images/ergodox-1-1024.jpg'><img src='/images/ergodox-1-1024.jpg' style='width: 120%;'></a>

### Impressions of the keyboard

The first thing I noticed was the relatively low actuation force of Cherry MX Brown (45 cN) compared to Matias's 65 gf. The tactile bump is not as pronounced either. But the most noticible thing is how I'm bottoming out on each stroke, and how loud that is. I do bottom out on other keyboards too but there is some sort of dampening, where as with this I am clacking keycap or switch.

<a href='/images/ergodox-2-1920.jpg'><img src='/images/ergodox-2-1920.jpg' style='width: 120%;'></a>

This is apparently a solvable problem using O-rings, so I am looking forward to how it feels after making the modification.

From using Artreus, I'm now relatively used to the ortholinear layout so it didn't take too long to get used to the qwerty part of the keys. As for the rest of the keys, I feel like it needs some improvements in terms of mapping, like moving the Command key somewhere more reachable, and I also need some practice. In general though, it's nice to have keys like numbers and arrows without using chords etc.

In terms of the size, it's quite larger than Atreus. I can actually put it on MacBook Pro using the tray I made, but I am not sure if I'd use it that way.

<a href='/images/ergodox-3-1920.jpg'><img src='/images/ergodox-3-1920.jpg' style='width: 120%;'></a>

Another thing I noticed was the lack of tilt and wrist rest. This is partly to do with my choice of wooden case. Being Microsoft Natural Keyboard fan, I prefer slight tilt into the screen, which keeps the wrist angle to be flat combined with a big wrist/palm rest. This too hopefully is a fixable issue. For now I am using rolled up socks.

### The firmware

To update the firmware using the official route, go to [the configurator page](https://input.club/configurator-ergodox/) and start changing the keymap. CLR-KEY means clear. Here's how mine looks like.

<a href='/images/ergodox-keymap.png'><img src='/images/ergodox-keymap2.png' style='width: 100%;'></a>

Next, I had to change the firmware version to "lts" and then download the firmware.

<code>
$ brew install dfu-util
</code>

To flash the firmware, first connect just the left keyboard, and then poke the flash button on the bottom of the keyboard. This should turn the LCD to orange.

<code>
$ dfu-util -l
Password:
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found DFU: [1c11:b007] ver=0000, devnum=6, cfg=1, intf=0, path="20-5", alt=0, name="Kiibohd DFU", serial="mk20dx256vlh7"
$ dfu-util -D left_kiibohd.dfu.bin
</code>

Do the same for right using `right_kiibohd.dfu.bin`.
