---
title:       "Atreus"
type:        story
date:        2017-06-19
changed:     2021-09-13
draft:       false
promote:     true
sticky:      false
url:         /atreus
aliases:     [ /node/225 ]
tags:        [ "diy" ]
---

  [quiet]: http://matias.ca/switches/quiet/
  [linear]: http://matias.ca/switches/linear/
  [apple]: https://deskthority.net/wiki/Apple_Standard_Keyboard
  [atreus]: https://atreus.technomancy.us/

Last night I finished making my [Atreus keyboard][atreus] from a DYI kit that I got a while back.
Here are some of the details:

- I chose [Matias Quiet Click][quiet] switch option (gray slider). There's no clicking.
- The modifiers use [Matias Quiet Linear][linear] switches (red slider).
- There are 42 keys in split ortholinear layout.
- Mahogany ply case.

### The materials

The kit comes with almost everything you need to assemble the Arteus keyboard. You need lacquer, a soldering iron, solder, and wire cutters.

- Minwax Clear Aerosol Lacquer, Clear Gloss
- Hakko Digital FX888D & CHP170 bundle, includes Soldering Station & CHP170 cutter
- Hakko T18-C2 - T18 Series Soldering Tip for Hakko FX-888/FX-8801
- DMiotech 0.8mm 50G 63/37 Rosin Core Tin Lead Soldering Solder Wire

Note that Matias switches are clones of Alps SKCM that was used in the 80s and 90s for keyboards like [Apple Standard Keyboard][apple]. This means that all the fancy keycaps available for Cherry MX switches will not work. If you want, you have to order a partial kit that is Cherry compatible.

### The assembly

The kit comes with detailed instruction so not much to mention here.
The first step is sanding the wooden case and putting the protective finish. This might be an unexpectedly time-consuming process since it's recommended to put eight to ten coats of the lacquer. Even if you spray at exactly 30 minute interval it will take some time. Plus you can't use it for 24 hours. At that point you might consider using polyurethane since it will come out more durable and requires fewer coats.

![image1](/images/atreus_1_1024.jpeg)

In parallel, you can start soldering the diodes.

![image2](/images/atreus_2_1024.jpeg)

Then solder the controller, and the switches.
The switches are bigger part than the diodes so there's a bit of adjustment you have to make in terms of making sure its heated and soldered properly, but overall not that difficult using the temperature controlled Hakko.

### The firmware

Here's how firmware flashing looks on Mac:

```bash
$ brew tap osx-cross/avr
$ brew install avrdude
# disconnect
$ ls /dev > dev-off.txt
# connect
$ ls /dev > dev-on.txt
$ diff dev-off.txt dev-on.txt
268a269
> cu.usbmodem22
432a434
> tty.usbmodem22
$ avrdude -p atmega32u4 -c avr109 -U flash:w:atreus-qwerty.hex -P /dev/tty.usbmodem22

Connecting to programmer: .
Found programmer: Id = "CATERIN"; type = S
    Software Version = 1.0; No Hardware Version given.
Programmer supports auto addr increment.
Programmer supports buffered memory access with buffersize=128 bytes.

....

avrdude done.  Thank you.
```

The firmware itself is straight up qwerty, but I switch super and option/alt on the macos setting.

### Impressions of the keyboard

![image3](/images/atreus_3_1024.jpeg)

My everyday keyboard is Microsoft Natural Ergonomic Keyboard 4000, but in the last year or so I've been coding more and more using the MacBook Pro keyboard, often from the kitchen where I hang out.
This started to wear out the flimsy MacBook Pro keyboard to the point that some keys that I assigned to slide out the terminal started to miss the strokes.
So a small size split keyboard sounnded like a good idea.

The Matias Quiet Click has definite tactile bump when activated even though they're quiet, and also relatively high actuation of 60±5gf. I'd love to compare it against MX clear, which seems comparable at leat in terms of the spec. In terms of the feel and the quietness, I think I like the switch.

The jury is still out, but the layout of Atreus requires some practice. It has significantly fewer keys compared even to laptop keyboards, so space (not a bar), shift, enter, backspace are all crammed on the bottom row as normal sized key. In addition, ortholinear layout means that I need to re-develop some of the muscle memory on where some of the keys are located. I have hard time particularly with 'c'.

Even if I can overcome the layout and memorize the various symbol locations, there's the issue of the placement. If I place the keyboard in between me and the laptop the screen becomes too far.

I did genuinely have fun building Atreus. It will take some more practice for it to feel more natural.
(This took me a while to type..)