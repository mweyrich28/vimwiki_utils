# vimwikiUtils
> [!NOTE] 
> This is a work in progress.

## Introduction
This plugin is an extension for [VimWiki](https://github.com/vimwiki/vimwiki), trying to add on to its many
capabilities. It also comes with a predefined wiki structure which I use in my bioinformatics studies. 
The structure was inspired by this [YouTube video](https://www.youtube.com/watch?v=hSTy_BInQs8&list=WL&index=1&t=1507s).
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
│  ├── screenshots
│  │  ├── screenshot_1.png
│  │  ├── screenshot_2.png
│  │  └── ...
│  ├── gifs
│  └── ...
├── templates/
│  ├── template_1.md
│  ├── template_2.md
│  └── ...
└── README.md
```

## Features
### `VimwikiUtilsLink` 
Allows you to quickly link to an existing file or to create a new file based on a `template`:

Press `<enter>` to create a `.md` link for the selected note or press `<C-b>` while in `insert`, to create a new note. 
Based on what you typed into the `Telescope` prompt, the new note will be named after the input provided and automatically 
created in your designated notes directory with a `template` which you can create in your `templates/` dir. For now,
`templates` support a `HEADER` token, which gets replaced with the formatted name of your newly created note and a `DATE` token, 
which gets replaced by the current date.

### (**COMING SOON**) `VimwikiUtilsSc`
Take screenshots on the fly by and embed them into the current markdown file. 

### (**COMING SOON**) `VimwikiUtilsRoughNote`
Creates a rough_note.md in your `1_rough_notes/`

### (**COMING SOON**) `VimwikiUtilsEditImage`
Hovering over an embedded screenshot, opens [KolourPaint](https://apps.kde.org/kolourpaint/), a free and simple program to edit images.

### (**COMING SOON**) `VimwikiUtilsTags`
Easily create or link to existing `tags` in `3_tags/` which are meant to also provide a structure to your wiki. Also automatically write all `tagged` files by `tag.md` into `tag.md`.

### (**COMING SOON**) `VimwikiUtilsBacklinks`
Find parent files linking to the currently opened file.

## Installation
### Prerequisites
Make sure to also install [Telescope](https://github.com/nvim-telescope/telescope.nvim) and (obviously) [VimWiki](https://github.com/vimwiki/vimwiki).

### Packer
```lua
    use {
        'mweyrich28/vimwiki_utils',
        requires = {
            'nvim-telescope/telescope.nvim',
            'vimwiki/vimwiki'
        }
    }
```

## Getting Started
For now I only implemented `vimwikiUtils_link`.
```lua
    require('vimwiki_utils').setup()
```
