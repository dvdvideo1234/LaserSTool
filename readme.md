# LaserSTool

![LaserSTool][ref-screenshot]

### Description
This the `LaserSTool` I've originally ported to GM13 since then I am
constantly improving it. My goal is making it behave as simiar to a
real laser beam. The original creator is `MadJawa`, and his repositoty
is [located here](https://svn.madjawa.net/lua/LaserSTOOL/). I cannot
tell you that the orinal autor will still supports this repo in the
future, but we can clearly see no commits are made since `2009`.

### Installation
Just clone this repo in your addons folder and you are done.

### Planned roadmap
1. Fix the laser entity ( `DONE` )
2. Fix the reflector entity ( `DONE` )
3. Implement reflection based on the traced texture ( `DONE` )
4. Code refurbish and made in tone with GM13 ( `DONE` )
5. Optimize and fix the think and draw routines ( `DONE` )
6. Develop a system which uses props as mirrors ( `DONE` )
7. Fix the crystal power converge entity ( `DONE` )
8. Fix crystals output not get affected by the source [reflection rate][ref-reflect-rate] ( `DONE` )
![][ref-reflect-rate]

9. Develop a way to use props as refraction meduims via texture [refractors][ref-refract] ( `DONE` )
10. Develop [refract][ref-refract] rate similar as [reflect rate][ref-reflect-rate] ( `DONE` )
11. Develop [total internal reflection][ref-total-reflect] at the medium boundary (`DONE`)
![][ref-refract-pic]

### Workshop
No. I see many copies of this tool everywhere, but still, there is none that
have crated official repository for community contribution, besides, I think
the original author will not like that in general. If you want to try the
tool. Go ahead and install it, but do not ask me to put it into the workshop.

### Pull requests
I am a fan of this tool, so any help I get will be appreciated.

[ref-total-reflect]: https://en.wikipedia.org/wiki/Total_internal_reflection
[ref-reflect]: https://en.wikipedia.org/wiki/Reflection_(physics)
[ref-refract]: https://en.wikipedia.org/wiki/Refraction
[ref-screenshot]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/screenshot.jpg
[ref-reflect-rate]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/reflect_rate.jpg
[ref-refract-pic]: https://raw.githubusercontent.com/dvdvideo1234/LaserSTool/main/data/laseremitter/tools/pictures/refract.jpg
