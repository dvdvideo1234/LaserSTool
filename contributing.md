### General
1. Use two spaces instead of one tab for indentation
2. All new files must be lower case for linux support
3. Line endings must always be unix complaint `LF`
4. Trim the tailing space before you save

### Entities
1. Create files `init.lua`, `cl_init.lua` and `shared.lua`
2. Create a folder with the name of the class [`here`][ref-entities]
3. Put all your files from point `(1)` in your new folder
4. Use [Paint.NET][ref-paint-net] to draw your `*.jpg` image or download from google
5. Make sure the image has green laser, as it is pleaseing to human eyes.
6. Import the image to [VTFEdit][ref-vtf-edit] and create a texture `256x256`
7. Store the new texture in the [vgui folder][ref-vgui] and create a `*.vmt`
8. Open your new `*.vmt` file with text editor and update `$basetexture`
9. Use your texture in game by calling [`resource.AddFile()`][ref-txmat-add] on the `*.vmt`

[ref-entities]: https://github.com/dvdvideo1234/LaserSTool/tree/main/lua/entities
[ref-vgui]: https://github.com/dvdvideo1234/LaserSTool/tree/main/materials/vgui/entities
[ref-paint-net]: https://www.getpaint.net/
[ref-vtf-edit]: https://nemstools.github.io/pages/VTFLib-Download.html
[ref-vgui]: https://github.com/dvdvideo1234/LaserSTool/tree/main/materials/vgui/entities
[ref-txmat-add]: https://wiki.facepunch.com/gmod/resource.AddFile
