# Contents

- [VimwikiUtils](#vimwikiutils)
    - [Introduction](#introduction)
- [Features](#features)
    - [Linking And Creating New Notes](#linking-and-creating-new-notes)
        - [`VimwikiUtilsLink`](#vimwikiutilslink)
        - [`VimwikiUtilsBacklinks` Find parent files linking to the currently opened](#vimwikiutilsbacklinks-find-parent-files-linking-to-the-currently-opened)
        - [`VimwikiUtilsRough` Press `<leader>nn` to create a `rough_note.md` in your](#vimwikiutilsrough-press-leadernn-to-create-a-rough_notemd-in-your)
        - [`VimwikiUtilsSource` Using this function you can linkt to your `soure](#vimwikiutilssource-using-this-function-you-can-linkt-to-your-soure)
    - [Organizing Notes](#organizing-notes)
        - [`VimwikiUtilsTags` Easily create or link to existing `tags` in `3_tags/`,](#vimwikiutilstags-easily-create-or-link-to-existing-tags-in-3_tags)
        - [`VimwikiUtilsEmbed` Helps handling notes stored in `1_rough_notes/` (or](#vimwikiutilsembed-helps-handling-notes-stored-in-1_rough_notes-or)
        - [`VimwikiUtilsGenerateIndex` Generates a list of all files in `3_tags`. You](#vimwikiutilsgenerateindex-generates-a-list-of-all-files-in-3_tags-you)
        - [`VimwikiUtilsRename` Due to the adjusted `wiki structure`, the default](#vimwikiutilsrename-due-to-the-adjusted-wiki-structure-the-default)
    - [Embedding And Editing Of Screenshots](#embedding-and-editing-of-screenshots)
        - [`VimwikiUtilsSc`](#vimwikiutilssc)
        - [`VimwikiUtilsEditImage` Hovering over an embedded screenshot  and pressing](#vimwikiutilseditimage-hovering-over-an-embedded-screenshot-and-pressing)
    - [Anki Related](#anki-related)
        - [Anki Cloze](#anki-cloze)
- [Default Key mappings](#default-key-mappings)
- [Installation](#installation)
    - [Packer](#packer)
    - [Lazy](#lazy)
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
Allows you to quickly link to an existing file or to create a new file based on
a `template`. Pressing `<C-f>` in `insert` mode opens a `telescope prompt`
showing all files in `4_atomic_notes/`. Either hit `<CR>` on an existing `note`
(creating a link to it), or press `<A-CR>` (options + enter) to forcefully
create a new note (based on where you are currently at), which will be named
after what you typed into the promt. If you type a new note name and there's no
other similar note in the fuzzy findings of telescope, you can also just hit
`<CR>` to create the new note. This helps you to dynamically create new notes or
link to already existing notes.  If you accidentally create a new `atomic_note`
in e.g `3_tags/` or at `root` level of your wiki, just use
[`VimwikiUtilsEmbed`](#vimwikiutilsembed) in order to move it to
`4_atomic_notes/`.

Choose a `template`, which you can create in your `templates/` dir. For now,
`templates` support a `HEADER` token, which gets replaced with the formatted
name of your newly created note, and a `DATE` token, which gets replaced by the
current date.

If you link to a new note (pressing `<A-CR>` while in `VimwikiUtilsLink`) from
within a `tag note` (a note which is stored `3_tags/`), a link to the
corresponding `tag` will automatically be substituted into your template.
> [!NOTE] This behavior only works, if your `template` contains the following
> pattern: `> **tags:**`.

### `VimwikiUtilsBacklinks` Find parent files linking to the currently opened
file by pressing `<leader>fb`. Currently implemented pretty janky: The function
calls `telescope.live_grep()` and inserts a formatted backlink pattern into the
`prompt`. While in `VimwikiUtilsBacklinks`, press `<A-CR>` (options + enter) to
generate an index containing all files linking to the current note.

### `VimwikiUtilsRough` Press `<leader>nn` to create a `rough_note.md` in your
`1_rough_notes/` based on a chosen template. I use this for taking notes during
the lecture. These notes should only be temperate and serve as additional
information when creating an actual `atomic_note`.

### `VimwikiUtilsSource` Using this function you can linkt to your `soure
files` (e.g lectures, papers, etc) stored in `2_source_material/`. Make sure to
name your sources clearly in order to prevent chaos.


## Organizing Notes

### `VimwikiUtilsTags` Easily create or link to existing `tags` in `3_tags/`,
which are meant to also structure your wiki. An index can be generated, holding
all files tagged by the current tag file. While in insert mode, press `<C-e>`
to open a `telescope prompt`. Here all your tags will be displayed. Hit `<CR>`
to create a link to the selected tag or hit `<A-CR>` (options + enter) to
forcefully create a new tag (named after what you typed in the promt). If you
type a new tag name and there's no other similar tag in the fuzzy findings of
telescope, you can also just hit enter to create the new tag (same behavior as
[`VimwikiUtilsLink`](#VimwikiUtilsLink)).

### `VimwikiUtilsEmbed` Helps handling notes stored in `1_rough_notes/` (or
anywhere but `4_atomic_notes/`) by automatically moving the currently opened
`note` into your `4_atomic_notes/` dir after you abstract and summarize it.

### `VimwikiUtilsGenerateIndex` Generates a list of all files in `3_tags`. You
can put this list into your root `README.md` / `index.md`.

### `VimwikiUtilsRename` Due to the adjusted `wiki structure`, the default
`VimwikiRename` doesn't work as expected. This `function` fixes said issue, it
uses several matching patterns to identify links and replaces them using `sed`.


## Embedding And Editing Of Screenshots

### `VimwikiUtilsSc`
> [!NOTE] This function currently calls `gnome-screenshot`
> but I will make it more dynamic soon...

Take screenshots on the fly by and embed them into the current markdown file.
After calling `VimwikiUtilsSc` you need to provide an image name. If that image
already exists, nothing will happen, otherwise `nvim` will call the screenshot
script after a 5 second delay. This way, you have enough time to set everything
up.

### `VimwikiUtilsEditImage` Hovering over an embedded screenshot  and pressing
`<leader>ii` opens [KolourPaint](https://apps.kde.org/kolourpaint/), a free and
simple program for editing images. You can also replace it with any other light
weight image editing software.


## Anki Related
### Anki Cloze
I personally like to summarize my lectures in `.md` and during so I mark `key
words` using the `inline code syntax`. Having summarized a lecture, it is
sometimes tedious to create good [Anki](https://apps.ankiweb.net/) cards
afterwars. That's why I try to already format my summary into smaller chunks, f.e:

```md
## Multi-modal registration using MIND
- **MIND**: `Modality-Independent Non-local descriptor` 
- Idea: Converting `multi-modal` into `mono-modal` problem
- For each `image pixel`, a set of `local weights` are calculated over `non-local image patches`
- These `weights` can be directly compared between images of different `modalities`
```

If I now want to quickly create a `cloze` type `Anki` card, I can select this
paragraph in `VISUAL` (block or line) mode and hit `<leader>ac` to call `VimwikiUtilsAnkiCloze`.
There are three options for converting the paragraph into a `cloze` style `Anki` card:

**Default (`''`)**:  
All `inline code` parts share the same `cloze` id:
```md
## Multi-modal registration using MIND
- **MIND**: {{c1::`Modality-Independent Non-local descriptor`}} 
- Idea: Converting {{c1::`multi-modal`}} into {{c1::`mono-modal`}} problem
- For each {{c1::`image pixel`}}, a set of {{c1::`local weights`}} are calculated over {{c1::`non-local image patches`}}
- These {{c1::`weights`}} can be directly compared between images of different {{c1::`modalities`}}
```

**Per word (`'0'`)**:
```md
## Multi-modal registration using MIND
- **MIND**: {{c1::`Modality-Independent Non-local descriptor`}} 
- Idea: Converting {{c2::`multi-modal`}} into {{c3::`mono-modal`}} problem
- For each {{c4::`image pixel`}}, a set of {{c5::`local weights`}} are calculated over {{c6::`non-local image patches`}}
- These {{c7::`weights`}} can be directly compared between images of different {{c8::`modalities`}}
```

**Per line (`'1'`)**
```md
## Multi-modal registration using MIND
- **MIND**: {{c1::`Modality-Independent Non-local descriptor`}} 
- Idea: Converting {{c2::`multi-modal`}} into {{c2::`mono-modal`}} problem
- For each {{c3::`image pixel`}}, a set of {{c3::`local weights`}} are calculated over {{c3::`non-local image patches`}}
- These {{c4::`weights`}} can be directly compared between images of different {{c4::`modalities`}}
```

The converted text is saved to your `systems clipboard`.


# Default Key mappings

| **Keymap**            | **Function**                                              |
|-----------------------|-----------------------------------------------------------|
| *INSERT*  `<C-f>`     | [`VimwikiUtilsLink`](#Vimwikiutilslink)                   |
| *INSERT*  `<C-e>`     | [`VimwikiUtilsTags`](#vimwikiutilstags)                   |
| *NORMAL* `<leader>nn` | [`VimwikiUtilsRough`](#vimwikiutilsrough)                 |
| *NORMAL* `<leader>fb` | [`VimwikiUtilsBacklinks`](#vimwikiutilsbacklinks)         |
| *NORMAL* `<leader>sc` | [`VimwikiUtilsSc`](#vimwikiutilssc)                       |
| *NORMAL* `<leader>ii` | [`VimwikiUtilsEditImage`](#vimwikiutilseditimage)         |
| *NORMAL* `<leader>sm` | [`VimwikiUtilsSource`](#vimwikiutilssource)               |
| *NORMAL* `<leader>m`  | [`VimwikiUtilsEmbed`](#vimwikiutilsembed)                 |
| *NORMAL* `<leader>wm` | [`VimwikiUtilsGenerateIndex`](#vimwikiutilsgenerateindex) |
| *NORMAL* `<leader>wr` | [`VimwikiUtilsRename`](#vimwikiutilsrename)               |
| *VISUAL* `<leader>ac` | [`VimwikiUtilsAnkiCloze`](#vimwikiutilsankicloze)         |

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

## Lazy
```lua
return {
    'mweyrich28/vimwiki_utils',
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'vimwiki/vimwiki',
    },
    config = function()
        require('vimwiki_utils').setup({})
    end,
}
```


# Getting Started
```lua
require('vimwiki_utils').setup({})
```
Or configure your keymaps and dirs like this:
```lua
require('vimwiki_utils').setup({
    global = {
        rough_notes_dir = "1_rough_notes",
        source_dir = "2_source_material",
        tag_dir = "3_tags",
        atomic_notes_dir = "4_atomic_notes",
        screenshot_dir = "assets/screenshots",
        kolourpaint = "/snap/bin/kolourpaint"
    },
    keymaps = {
        vimwiki_utils_link_key = '<C-b>',
        vimwiki_utils_tags_key = '<C-e>',
        vimwiki_utils_rough_key = '<leader>nn',
        vimwiki_utils_backlinks_key = '<leader>fb',
        vimwiki_utils_sc_key = '<leader>sc',
        vimwiki_utils_edit_image_key = '<leader>ii',
        vimwiki_utils_source_key = '<leader>sm',
        vimwiki_utils_embed_key = '<leader>m',
        vimwiki_utils_generate_index_key = '<leader>wm'
        vimwiki_utils_rename_key  = '<leader>wr'
    }
})
```

Make sure to create a `wiki` in your `vimwiki.lua` config like so:

```lua
vim.g.vimwiki_auto_chdir = 1 -- this is currently necessary
vim.g.vimwiki_list = {
    {
        path = '~/path/to/zettelkasten/',
        syntax = 'markdown',
        ext = '.md',
        index = 'README'
    }
}
```
