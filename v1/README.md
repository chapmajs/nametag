LED Nametag Version 1
---------------------

[Here's a dark GIF of the nametag in action](https://github.com/chapmajs/nametag/blob/master/v1/nametag_v1.gif)

This nametag was cobbled together with a PIC16F88 and some DL2416 smart displays on a chunk of protoboard. A quick junk drawer solution to having run out of time to lay out the PC board for the device I actually wanted to build! This is the nametag I had at [The Eleventh HOPE](https://hope.net). Note that the PIC16F88 was used because I had some in my box of old PICs from previous projects, I wouldn't recommend it for new projects.

### Connections

I didn't draw up a schematic for this one, it was built point-to-point over two evenings on a piece of protoboard with Kynar wire. The display connects to the PIC as follows:

* Display `D0` - `D6` -> PIC `PORTB` `RB0` - `RB6`
* Display `A0`, `A1` -> PIC `PORTA` `RA0`, `RA1`
* Display `/WR` -> PIC `PORTA`, `RA7`
* Display `/BL` -> PIC `PORTA`, `RA6`

The displays' `/CE` lines are controlled by the PIC's `PORTA`, `RA2`. The rightmost display connects directly to `RA2`, while the leftmost display is driven through a one-transistor inverter. Any small signal NPN will work, I used a 2N3904. This allows the displays to appear as a single block of 8 consecutive addresses, which makes programming simpler.

### Programming

Making data appear on the display is documented in the code, but works basically as following:

* Ensure `/WR` is high (`OR 0x10000000` with `PORTA` if unsure)
* Move the character to be displayed to `PORTB`
* Move the character address to `PORTA` (enables `/WR` as long as the high bit is 0)
* Set `/WR` to high (`bsf PORTA, 7`)
* Set `/BL` to turn off blanking (`bsf PORTA, 6`)

If you're updating more than one character at a time (scrolling effect), you'll want to blank the display before starting to update the characters, and turn blanking off when you're done. Otherwise you get some character ghosting, especially at low CPU speeds.

### Display String

The display string is a NULL-terminated ASCII string in EEPROM starting at `0x00`. My firmware implements a circular array using the EEPROM so that you can keep calling `NEXTEE` and auto-wrap to the beginning of the array when you hit NULL. The 16-segment version of the DL2416 only supports uppercase ASCII characters; see [the datasheet](https://github.com/chapmajs/nametag/blob/master/datasheets/DL2416.pdf) for more information. If you're using one of the newer dot matrix DL2416 workalikes, you can use lowercase ASCII too.