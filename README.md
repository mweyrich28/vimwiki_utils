**Contents**
- [VimwikiUtils](#vimwikiutils)
    - [Introduction](#introduction)
- [Features](#features)
    - [Linking And Creating New Notes](#linking-and-creating-new-notes)
        - [`VimwikiUtilsLink`](#vimwikiutilslink)
        - [`VimwikiUtilsBacklinks`](#vimwikiutilsbacklinks)
        - [`VimwikiUtilsRough`](#vimwikiutilsrough)
    - [Organizing Notes](#organizing-notes)
        - [`VimwikiUtilsTags`](#vimwikiutilstags)
        - [`VimwikiUtilsEmbed`](#vimwikiutilsembed)
    - [Embedding And Editing Of Screenshots](#embedding-and-editing-of-screenshots)
        - [`VimwikiUtilsSc`](#coming-soon-vimwikiutilssc)
        - [`VimwikiUtilsEditImage`](#vimwikiutilseditimage)
- [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [Packer](#packer)
- [Getting Started](#getting-started)

# VimwikiUtils
> [!NOTE] 
> This is a work in progress and my first time implementing a plugin for nvim. 

## Introduction
This plugin is an extension for [VimWiki](https://github.com/vimwiki/vimwiki), trying to add to its many
capabilities. It also has a predefined wiki structure, which I use in my bioinformatics studies. 
The wiki structure was inspired by this [YouTube video](https://www.youtube.com/watch?v=hSTy_BInQs8&list=WL&index=1&t=1507s). 

```bash
/home/usr/zettelkasten/
.
├── 1_rough_notes/
│  ├── unprocessed_note.md
│  └── ...
├── 2_source_material/
│  ├── lecture_slides_1.pdf
│  └── ...
├── 3_tags/
│  ├── rna.md
│  ├── computer_science.md
│  ├── biochemistry.md
│  └── ...
├── 4_atomic_notes/
│  ├── atomic_note_1.md
│  ├── atomic_note_2.md
│  ├── atomic_note_3.md
│  └── ...
├── assets/
│  ├── screenshots/
│  │  ├── screenshot_1.png
│  │  ├── screenshot_2.png
│  │  └── ...
│  ├── gifs/
│  └── ...
├── templates/
│  ├── template_1.md
│  ├── template_2.md
│  └── ...
└── README.md
```

# Features

## Linking And Creating New Notes

### `VimwikiUtilsLink` 
Allows you to quickly link to an existing file or to create a new file based on a `template`. 
Pressing `<C-b>` in `insert` mode opens a `telescope prompt` showing all files in `4_atomic_notes`.
Either hit `<CR>` on an existing `note` (creating a link to it), or press `<A-CR>` (options + enter) to create a new note (in `4_atomic_notes`), 
which will be named after what you typed into the promt. This helps you to dynamically create new notes or link to already existing notes.
Choose a `template`, which you can create in your `templates/` dir. For now,
`templates` support a `HEADER` token, which gets replaced with the formatted name of your newly created note, and a `DATE` token, 
which gets replaced by the current date.

### `VimwikiUtilsBacklinks`
Find parent files linking to the currently opened file by pressing `<leader>fb`.
Currently implemented pretty janky: The function calls `telescope.live_grep()` and inserts a formatted backlink pattern into the `prompt`. 
While in `VimwikiUtilsBacklinks`, press `<A-CR>` (options + enter) to generate an index containing all files linking to the current note.

### `VimwikiUtilsRough`
Press `<leader>nn` to create a `rough_note.md` in your `1_rough_notes/` based on a chosen template.

### `VimwikiUtilsSource`
Using this function you can linkt to your `soure files` (e.g. lectures, papers, etc) stored in `2_source_material`.


## Organizing Notes

### `VimwikiUtilsTags`
Easily create or link to existing `tags` in `3_tags/`, which are meant to also structure your wiki. An index can be generated, holding all files tagged by the current tag file.
While in insert mode, press `<C-e>` to open a `telescope prompt`. Here all your tags will be displayed. Hit `<CR>` to create a link to the selected tag or hit `<A-CR>` (options + enter) to create a new tag 
(named after what you typed in the promt)

### `VimwikiUtilsEmbed`
Helps handling notes stored in `1_rough_notes/` by automatically moving the currently opened `rough_note`
into your `4_atomic_notes/` dir after you added `tags` and maybe created links to other files.


## Embedding And Editing Of Screenshots

### `VimwikiUtilsSc`
> [!NOTE]
> This function calls a `bash` script which calls `gnome-screenshot` but you can replace it with any other script. 

Take screenshots on the fly by and embed them into the current markdown file. 

### `VimwikiUtilsEditImage`
Hovering over an embedded screenshot  and pressing `<leader>ii` opens [KolourPaint](https://apps.kde.org/kolourpaint/), a free and simple program for editing images. 
You can also replace it with any other light weight image editing program.


# Default Key mappings

| **Keymap**            | **Function**                                      |
|-----------------------|---------------------------------------------------|
| *INSERT*  `<C-b>`     | [`VimwikiUtilsLink`](#Vimwikiutilslink)           |
| *INSERT*  `<C-e>`     | [`VimwikiUtilsTags`](#vimwikiutilstags)           |
| *NORMAL* `<leader>nn` | [`VimwikiUtilsRough`](#vimwikiutilsrough)         |
| *NORMAL* `<leader>fb` | [`VimwikiUtilsBacklinks`](#vimwikiutilsbacklinks) |
| *NORMAL* `<leader>sc` | [`VimwikiUtilsSc`](#vimwikiutilssc)               |
| *NORMAL* `<leader>ii` | [`VimwikiUtilsEditImage`](#vimwikiutilseditimage) |
| *NORMAL* `<leader>sm` | [`VimwikiUtilsSource`](#vimwikiutilssource)       |
| *NORMAL* `<leader>em` | [`VimwikiUtilsEmbed`](#vimwikiutilsembed)         |

# Installation
## Packer
```lua
use {
    'mweyrich28/vimwiki_utils',
    requires = {
        'nvim-telescope/telescope.nvim',
        'vimwiki/vimwiki'
    }
}
```

# Getting Started
```lua
require('vimwiki_utils').setup()
```
