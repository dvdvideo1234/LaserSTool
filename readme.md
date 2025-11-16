# LaserSTool

[![][ref-iyt]][ref-yt]

[![][ref-ws-down]][ref-workshop] [![][ref-ws-date]][ref-ws-updt]

### Description
This is the `LaserSTool` I've originally ported to [Garry's mod 13][ref-gmod-link]
since then, I have been constantly improving it. My goal is to make it behave similarly to a
real [laser beam][ref-laser-beam]. The repository contains [MadJawa][ref-author-org]'s
original SVN, but drastically changed to include a lot of added features, better user
experience, and improved beam physics behavior accuracy. This is by far the most
bug-free laser addon that is up to date and with active development.

### Brief history
The original creator and huge credit goes to the one and only [MadJawa][ref-author-org].
His repository is [located here][ref-org-repo]. I cannot tell you that he will still
and eventually support this repo in the future, but we can clearly see that no commits have been
made since `2009`. This has been quite a ride since `January 2020` when I first started
fixing this, but as time flew by, I got hooked on other projects [IRL][ref-exp-irl]
and this was forgotten. I did not make a repository at the time, so I kept
fixing it on my local machine at home, thinking that no one would eventually get interested
in me reviving this gem, but here we are now, and boy, was I wrong! Last, I decided to push
it to GitHub, so the code will not get lost again, or something may happen to this marvel!

![LaserSTool][ref-screenshot]

### Installation
Just clone this repo in your addons folder or subscribe to the [workshop][ref-workshop].

### Features
The code base has been drastically changed now and does not correspond to the original `2.0`
version anymore. This was the only way I could support the things I needed the most from the addon:

1. Very stable [crystal][ref-crystal] calculating routine and beam trace
2. [Reflect][ref-reflect] beam traces via hit surface material override
3. [Refract][ref-refract-pic] beam traces via hit surface material override
4. Calculate [full internal reflection][ref-total-reflect] according to [medium boundary][ref-boundary]
5. Code base and updates in tone with [Garry's mod 13][ref-gmod-link]
6. Supports [wire][ref-wire] and every element supports advanced duplicator [1][ref-adv-dupe1] and [2][ref-adv-dupe2]
7. [Wire inputs][ref-wire] override internals when connected
8. Internal [wire wrapper][ref-wire-wrap] taking care of the wire interface
9. Surface [reflection][ref-reflect] and medium [refraction][ref-refract] power [absorption][ref-reflect-rate]
10. A better model for the crystal entity so as not to get confused about where the beam comes out
11. [Material override][ref-mat-override] can be saved and restored with advanced duplicator [1][ref-adv-dupe1] and [2][ref-adv-dupe2]
12. [Editable entity][ref-ent-edit] support option for changing internals of the laser elements
13. User customizable models for active entities and reflectors via convar tweak
14. Absorption [degradation and self-sustained beam loop][ref-crystal] for crystal entities
15. Wiremod [API][ref-wire-api] for retrieving beam source settings and making control feedback
16. A bunch of different laser addon dedicated elements you can find [here in the wiki page][ref-wiki-page]
17. Coding an effective wrapper for [editable entity][ref-ent-edit] manipulation and adjustment
18. You can combine the refraction with [Shadowscion's primitive][ref-primitive] for using lenses

### Workshop
I see many copies of this tool everywhere, but still, there is none that
have created an official repository for community contribution, besides, I
think the original author will not like that in general. If you want to try the tool
go ahead and install it.

### Versioning
Small modifications are pushed to the workshop when they are tested. Large
modifications require a dedicated [PR][ref-git-pr], which, when it gets tested
and merged, is pushed to the workshop [automatically][ref-ws-publish].

### Pull requests
I am a fan of this tool, so any help I get will be appreciated.

[ref-total-reflect]: https://en.wikipedia.org/wiki/Total_internal_reflection
[ref-reflect]: https://en.wikipedia.org/wiki/Reflection_(physics)
[ref-refract]: https://en.wikipedia.org/wiki/Refraction
[ref-screenshot]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/screenshot.jpg
[ref-reflect-rate]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/reflect_rate.jpg
[ref-refract-pic]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/refract.jpg
[ref-crystal]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/crystal.jpg
[ref-boundary]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/optic-cable.jpg
[ref-wire-api]: https://github.com/dvdvideo1234/LaserSTool/wiki/Wiremod-API
[ref-wire]: https://github.com/wiremod/wire
[ref-wire-wrap]: https://github.com/dvdvideo1234/LaserSTool/blob/main/lua/laseremitter/wire_wrapper.lua
[ref-wiki-page]: https://github.com/dvdvideo1234/LaserSTool/wiki
[ref-ent-edit]: https://wiki.facepunch.com/gmod/Editable_Entities
[ref-mat-override]: https://wiki.facepunch.com/gmod/Entity:SetMaterial
[ref-gmod-link]: https://gmod.facepunch.com/
[ref-laser-beam]: https://en.wikipedia.org/wiki/Laser
[ref-author-org]: https://forum.facepunch.com/u/madjawa-legacy
[ref-org-repo]: https://svn.madjawa.net/lua/LaserSTOOL/
[ref-git-pr]: https://github.com/dvdvideo1234/LaserSTool/pulls
[ref-ws-publish]: https://github.com/dvdvideo1234/WindowsBatches/tree/master/SteamGames/GmodAddons/WorkshopPublish
[ref-exp-irl]: https://www.grammarly.com/blog/irl-meaning/
[ref-adv-dupe1]: https://github.com/wiremod/advduplicator
[ref-adv-dupe2]: https://github.com/wiremod/advdupe2
[ref-yt]: http://www.youtube.com/watch?v=QCbQLuknN9Y
[ref-iyt]: https://img.youtube.com/vi/QCbQLuknN9Y/0.jpg
[ref-ws-down]: https://img.shields.io/steam/downloads/2546685571
[ref-workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=2546685571
[ref-ws-date]: https://img.shields.io/steam/update-date/2546685571
[ref-ws-updt]: https://steamcommunity.com/sharedfiles/filedetails/changelog/2546685571
[ref-primitive]: https://github.com/shadowscion/Primitive
