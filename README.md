# Wallpaper Library

An Omarchy shell plugin for browsing a categorized wallpaper collection
(one subfolder per category, e.g. [dharmx/walls](https://github.com/dharmx/walls)).

- **Bar widget** — click the icon for a list of categories with counts.
  Pick one to open Omarchy's image picker on it, or hit *Random wallpaper*.
- **Style menu** — `./wallpaper-library install-menu` writes a
  *Style › Wallpaper Library* submenu (with a Random row) into
  `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Rerun it after adding
  categories; `uninstall-menu` removes it.

Set the library folder with the widget's `libraryDir` setting (CLI:
`WALLPAPER_LIBRARY_DIR`). Categories open one at a time because the picker's
IPC argument is capped at 128KB, which a whole large library exceeds.

## Wallpapers

This plugin is built around [**dharmx/walls**](https://github.com/dharmx/walls),
a large wallpaper collection already sorted into category folders (anime,
nature, nord, gruvbox, …). The wallpapers belong to dharmx/walls and their
original artists, so check that repo for credits and licensing; none are
included here.

To use it, clone it into the plugin's default library folder:

```
git clone --depth 1 https://github.com/dharmx/walls ~/.config/omarchy/wallpapers/dharmx-walls-source
```

Any other folder of category subfolders works too. Point `libraryDir` at it.

## CLI

```
wallpaper-library list | pick <category> | random [category] | install-menu | uninstall-menu
```
