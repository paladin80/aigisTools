* just_quotes.lua
Example:
>do just_quotes.lua

Nothing fancy here, just grabs all quotes and puts them in folder out\processed_files\just_quotes\.

I also made it automatically name the txt file with the unit name, but lua doesn't seem to support Japanese until it's been reduced to bytes form, so the filenames end up weird. I'm not quite sure how to fix this yet.


* mass_scale.lua
Example:
>do mass_scale.lua

Scales sprites, but this by itself won't do anything until you choose a mode between 'cards' or 'stands'.

>do mass_scale.lua stands

This scales all sprites in out\files\PlayerDotStand(.aar) and places it with similar folder structure in out\processed_files\.

>do mass_scale.lua cards

This scales all sprites in out\cards\ and puts them in the same folder the sprites came from, in their own 'scaled' folders.

ALSO: if you have pngout.exe and dropped it into the Utilities\ folder, this script will automatically pngout the resulting images.

mass_scale.lua is pretty customizeable to target specific units. Its full range of options look like this:

>do mass_scale.lua "modeandunitID" "force" "option"

-mode refers to the folder you want to target - as mentioned before, you put in either "card(s)" or "stand(s)"
-unitID are the units you want to target if you're working on the cards folder. Put in "cards 7" WITH the quotation marks to target Julian; put in "cards 7 20 23" again, with quotation marks to target Julian, Lilia, and Soma.
-force refers to whether you want to forcefully overwrite the images that are already put in "force" or "forced" (quotations optional) to force replace images, and anything else (such as "noforce") to skip an image that already exists.
-option has two different things for it.
--One is the keyword "keepnudge"; put that in if you want to keep the intermediary images of the "nudged" folder that has the sprites in its original resolution, but adjusted so that all sprites are the same size.
--The other is that you can adjust the scaling to something other than the game's set value. Putting in "2.0" for example results in scaled sprite images that are 2x its base size, in its own scaled_2.0 folder.

As a "more live" example, if I input these in succession:

>do mass_scale.lua "cards" "force" "keepnudge 2.0"
>do mass_scale.lua "cards 20" "" "keepnudge 3.0"
>do mass_scale.lua "cards 7 20" "" ""
>do mass_scale.lua "cards" "" "2.0"

By the first command, all units currently in out\cards will be forced to have their nudged and scaled images created. Instead of having their ordinary scale factor, however, all the units are resized by a factor of 2 rather than 1.5. In addition, the "nudged" folder is kept.

By the second command, only unit 20 (Lilia) will have new scaled images created, unless she already has them. These ones will be her sprites increased by a factor of 3. Once again the "nudged" folder is kept.

By the third command, two units (Julian and Lilia) will have their regular, 1.5x scaled sprite images created, unless they already have them. Their nudge folders are deleted after the script confirms these units have their scaled sprites.

By the fourth command, no new images are created because all units already have their 2x scaled images. However, the script will delete all the "nudged" folders that remains in each units' folder.

I admit I have no real good reason to go so far defining these specifc commands, except that I'd personally rather do it this way than to shuffle folders around.

With luck, you'll probably only need the vanilla "do mass_scale.lua cards" or "do mass_scale.lua stands".


*gif_make.lua
Example:
>do gif_make.lua

Similarly to mass_scale.lua, all units with sprites that are nudged and/or scaled will have them compiled into a gif and placed in the unit's gifs\ folder.

NOTE: unfortunately GraphicsMagick by itself wasn't capable of making accurate gifs. It can't adjust its frames per second rate to something other than 100 per second, and it doesn't seem to be capable of using "-dispose previous" command if each composed image have their own -delay values.

To use gif_make.lua you'll have to install ImageMagick, and allow it to add "application directory to your system path". It should be the second checkmark before it starts to install.

ALSO NOTE that I opted not to add in the final frame of each gif, because I don't know about image displaying programs but at least Firefox can't seem to acknowledge that last final frame without making it last longer than the 1/60th of a second it should be lasting.

And finally, attack gifs aren't *really* right without adding in the idle cooldown time between each attack. I'm not completely sure how this works yet though, whether it adds in the first x frames of the standing animation or divides each section of the standing animation by the same proportion, so I opted to leave the attack animations as-is.

Now for the options. The following two are equivalent commands:

>do gif_make.lua
>do gif_make.lua "noforce" "" "" "" "x60"

-"noforce" is, similarly to mass_scale.lua, whether you want to force the creation of the gifs. Put in "force" if you do want to force creation; put in "" or "noforce" if otherwise.
-The second variable, the first empty string "", is your selection of units. This is again similar to mass_scale.lua in the "20" selects just Lilia, "7 20 23" selects Julian, Lilia and Soma, and so on.
-The third variable and the second empty string "" is your choice of cc levels. Putting in "0" makes gifs of all available units at base class, "1" for units with CC class, "2" for all units with AW class, and "0 2" for all units at base and AW class. ("3" and "4" are AW2v1 and AW2v2, respectively.)
-The fourth variable and the third empty string "" is your choice of which animations to compile. "1" refers to standing animation, "3" is attack, "6" is standing during skill, and "8" is attacking during skill. ("5" is for collapsed sprite, but there's only one image for that so no gifs to make.)
-The fifth variable is speed in a fraction of a second. Default is x60 for "one frame = 1/60th of a second", but you can speed it up by going up to "x100" or slow it down by going down to "x30", for example.

Last note that if you never deleted the "nudged" folders, this script will attempt to make a gif for those too, marking the resulting gifs with "_(unscaled)".

Again, in the normal course of things you'll probably only use the vanilla "do gif_make.lua".



Log of fixes I made:
-lib\unit.lua didn't address units with dotIDs over 20000 (placeholder for AW2'd units without new art). Subtracting by that 20000 resulted in the unit's regular unitID.
-New ClassID range added for "chibi" characters that go over 20000. Changed melee/ranged check in unit.lua into checking for class.ApproachFlag instead, which indicates block ability.
-CObjHomeMenu.amt and TabDefaultPage.amt cannot be decoded by current version of lib\parse_al.lua. I edited to make parse_al.lua skip them specifically.
-minor extraneous part in unit.lua that was solved by collating both versions of max levels table and the cc check.
-I seem to have given get_file.lua a new "last modified" date when I was poking around and probably accidentally saved after making and saved after reverting an edit. I shouldn't have added anything new in there. Same with lib\class.lua and lib\gif_make.lua...I think.
-scale_image.lua had a part sectioned off into lib\scale_calcs.lua so other scripts could use its calculations.
-unit.lua when compiling affection quotes didn't have a check to see whether secretary quotes were included, so I added that in.
-added just_quotes.lua, mass_scale.lua, and gif_make.lua