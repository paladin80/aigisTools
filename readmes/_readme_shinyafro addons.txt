AigisTools
By, lzlis

These is a bunch of programming I have to do help with decoding and presenting game information from the browser game Millennium War Aigis (NSFW).

These tools are not really made to be user-friendly. There is no GUI, and they all operate from the command line.

==========
DISCLAIMER
==========

See _license.txt for information about software/data licensing.

For the software provided by lzlis, it is provided "as is", without warranty of any kind, express or implied, including but not limited to warranties of merchantibility, fitness for a particular purpose and noninfringement. In no event shall the author be liable for any claim, damages, or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Lzlis also disclaims any reprecussions using this software may have on your Nutaku or DMM acount.

Nutaku accounts are governed by their own terms of service (https://www.nutaku.net/terms/). You are responsible for complying with those terms.

DMM account are also governed by their own terms of service (https://terms.dmm.co.jp/member/).


===========
Addons
===========

Release 2 by illumini9
Wikitools overhaul by shiny

===============
Installation
===============

Same as before, except you put the download url and xml locations in the config.

===============
Basic usage
===============
unit

unit is the new unit functions, you can use the old one still, but it will not have any improvements.
it supports multiple units which are dynamically translated via the unit translation table in the translations folder.

>do unit name mode

for multiple modes or names, do

>do unit "names name_(Special)" "mode1 mode2"

Modes:
  Text: Just the info.txt, can be configured to dump to console like before using the config.lua
  Page: Makes wiki-style pages. Not perfect, make sure to correct any errors. Also does stats page.
  Image: Images only. Supports special args which are functionally aditional modes
    States: (Base, CC, AW, AW2, AW2v1, AW2v2)
	Images: (Gif, Sprite, Icon, Render)
	Dump: Dumps files to a location specified in the config.
  HCG: Hentai Content-Graphics. Supports the dump arg.
  Full: All of the above.
  Legacy: Old style, but multiple units (if it works)
  
For units to be translated, make sure to keep the unit.lua in the translations folder updated.



welp
i made the laziest thing
get unit "#special:150-200" "hcg dump"
guess wat that does. Granted, i used HCG cuz they are quick to mine as i don't run hcgs through pngout
maybe i should rename it #range:xxx-xxx

When A comes out set it to "#range:all" and "render dump" if it's just a new file list and it works without breaking shit on the dataminer side.

should be able to mine shit without causing much of a fuss