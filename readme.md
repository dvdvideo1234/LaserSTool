# LaserSTool

[![](https://img.youtube.com/vi/QCbQLuknN9Y/0.jpg)](http://www.youtube.com/watch?v=QCbQLuknN9Y "")

### Description
This is the `LaserSTool` I've originally ported to GM13 since then I am
constantly improving it. My goal is making it behave as simiar to a
real laser beam. The original creator is `MadJawa`, and his repositoty
is [located here](https://svn.madjawa.net/lua/LaserSTOOL/). I cannot
tell you that the orinal autor will still supports this repo in the
future, but we can clearly see no commits are made since `2009`.

![LaserSTool][ref-screenshot]

### Installation
Just clone this repo in your addons folder or subscribe in the [workshop][ref-workshop].

### Features
1. Very stable [crystal][ref-crystal] calculating routine and beam trace
2. [Reflect][ref-reflect] beam traces via hit surface material override
3. [Refract][ref-refract-pic] beam traces via hit surface material override
4. Calculate [full internal reflection][ref-total-reflect] according to medium boundary
5. Code base and updates in tone with Garry's mod 13
6. Supports [wire][ref-wire] and every element supports advanced duplicator 1 and 2
7. [Wire inputs][ref-wire] override internals when connected
8. Internal [wire wrapper][ref-wire-wrap] taking care of the wire interface
9. Surface [reflection][ref-reflect] and medium [refraction][ref-refract] power [absorption][ref-reflect-rate]
10. Better model for the crystal entity not to get confused where beam comes out
11. [Material override][ref-mat-override] can be saved and restored with advanced duplicator 1 and 2
12. [Editable entity][ref-ent-edit] support option for changing every aspect of the laser and crystal
13. User customizable models for crystals and reflectors via convar tweak

### Workshop
I see many copies of this tool everywhere, but still, there is none that
have crated official repository for community contribution, besides, I think
the original author will not like that in general. If you want to try the tool
Go ahead and install it. If the original author asks I will take this down!

### Pull requests
I am a fan of this tool, so any help I get will be appreciated.

[ref-total-reflect]: https://en.wikipedia.org/wiki/Total_internal_reflection
[ref-reflect]: https://en.wikipedia.org/wiki/Reflection_(physics)
[ref-refract]: https://en.wikipedia.org/wiki/Refraction
[ref-screenshot]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/screenshot.jpg
[ref-reflect-rate]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/reflect_rate.jpg
[ref-refract-pic]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/refract.jpg
[ref-crystal]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/crystal.jpg
[ref-wire]: https://github.com/wiremod/wire
[ref-wire-wrap]: https://github.com/dvdvideo1234/LaserSTool/blob/main/lua/laseremitter/wire_wrapper.lua
[ref-ent-edit]: https://wiki.facepunch.com/gmod/Editable_Entities
[ref-mat-override]: https://wiki.facepunch.com/gmod/Entity:SetMaterial
[ref-workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=2546685571
