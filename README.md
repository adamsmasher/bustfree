# Bustfree!
### A brick-busting arcade game for the Nintendo Game Boy

![biglogo](https://user-images.githubusercontent.com/246294/109725871-9f094e80-7b66-11eb-869d-a4e4547e348d.png)

![screenshot](https://user-images.githubusercontent.com/246294/109725777-813be980-7b66-11eb-8c4e-1d3cc05fb26f.png)

*Bustfree!* is a simple brick-busting game in the style of Atari's [Breakout](https://en.wikipedia.org/wiki/Breakout_(video_game)) or Taito's [Arkanoid](https://en.wikipedia.org/wiki/Arkanoid),
developed for the Nintendo Game Boy using freely available, unofficial tools.

(*Bustfree!* is not in any way affliated with or endorsed by Nintendo, Atari, Taito.)

Development is currently in [a very early state](https://github.com/adamsmasher/bustfree/blob/main/TODO); the interest here is primarily educational. You can watch development happen [live on Twitch](https://twitch.tv/EndOfCinema), or catch up with old streams on [Youtube](https://www.youtube.com/channel/UCYDFgp6XHM-4Xatefz7Iirg).
The current streaming schedule is Monday thru Friday at 2PM Pacific.

The code for *Bustfree!* is provided under the [MIT License](https://en.wikipedia.org/wiki/MIT_License) and is freely available, as-is, for use in your own games.
See [`LICENSE`](https://github.com/adamsmasher/bustfree/blob/main/LICENSE) for the full details.

## Compatibility

*Bustfree!* is primarily tested on [BGB](https://bgb.bircd.org/), a powerful Game Boy emulator and debugger.
I also intermittently test on a Nintendo [Super Game Boy](https://en.wikipedia.org/wiki/Super_Game_Boy) (version 1) using an [Everdrive GB](https://krikzz.com/store/) running through an [Analogue Super Nt](https://www.analogue.co/super-nt).
In theory there's no reason why it shouldn't work on [any other model of Game Boy or Game Boy Advance](https://en.wikipedia.org/wiki/Game_Boy_family) (except for the [Game Boy Micro](https://en.wikipedia.org/wiki/Game_Boy_Micro), which doesn't support Game Boy or Game Boy Color games).
If you encounter any compatibility issues with your hardware, please file a bug.

## Release History

* Alpha 5 - March 9, 2021
* Alpha 4 - March 2, 2021
* Alpha 3 - February 22, 2021
* Alpha 2 - February 15, 2021
* Alpha 1 - February 8, 2021

## Building Bustfree!

Right now I'm developing *Bustfree!* on Windows; the included "makefile", [`make.bat`](https://github.com/adamsmasher/bustfree/blob/main/make.bat), is just a batch file. If you're on Linux or macOS
you'll probably want to port it to `make` or `sh` (which should be easy enough, contributions appreciated ☺️)

*Bustfree!* is written using [RGBDS, the Rednex Game Boy Development System](https://rgbds.gbdev.io), version 0.4.2.
For `make.bat` to work you'll need it in your path; on Windows, I just put the executables right in the repo root.

## Credits, Thanks, Other Useful Links

For more information about homebrew Game Boy development, check out [gbdev.io](https://gbdev.io/).

The [Pan Docs](https://gbdev.io/pandocs/) are my primary technical reference for the Game Boy hardware. Much thanks to all those who have written, contributed to, and hosted them.

As the primary tools I use, I'd like to extend my thanks to [beware](https://www.bircd.org/), developer of BGB and to the developers of RGBDS ([history](https://rgbds.gbdev.io/docs/v0.4.2/rgbds.7), [current contributors on github](https://github.com/gbdev/rgbds/graphs/contributors)).

Bust Free! uses the [GBSoundSystem](https://github.com/BlitterObjectBob/GBSoundSystem/) audio driver. The [Tiled](https://www.mapeditor.org/) map editor is used to build levels. Some utility scripts are written in the [Python](https://www.python.org/) programming language.

Much thanks to Nintendo for making the Game Boy, and to [Gunpei Yokoi](https://en.wikipedia.org/wiki/Gunpei_Yokoi) in particular for dreaming of it.
