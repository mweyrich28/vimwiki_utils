# vimwikiUtils
## Introduction

This plugin is an extension for [VimWiki](https://github.com/vimwiki/vimwiki), trying to add on to its many
capabilities. It also comes with a predefined wiki structure which I use in my bioinformatics studies:
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
└── README.md
```

## Features
> [!NOTE] 
> This is a work in progress

1. `vimwikiUtils_link`: Allows you to quickly link to an existing file or to create a new file with a `TEMPLATE_HEADER`.  
2. (**COMING SOON**) `vimwikiUtils_sc`: Take screenshots on the fly by and embed them into the current markdown file. 
3. (**COMING SOON**) `vimwikiUtils_rough_note`: Creates a rough_note.md in your `1_rough_notes/`
4. (**COMING SOON**) `vimwikiUtils_edit_image`: Hovering over an embedded screenshot, opens [KolourPaint](https://apps.kde.org/kolourpaint/), a free 
   and simple program to edit images.
5. (**COMING SOON**) `vimwikiUtils_tags`: Easily create or link to existing `tags` in `3_tags/` which are meant to also 
   provide a structure to your wiki. Also automatically write all `tagged` files by `tag.md` into `tag.md`.
6. (**COMING SOON**) `vimwikiUtils_backlinks`: Find parent files linking to the currently opened file

## Installation
### Prerequisites
Make sure to also install [telescope](https://github.com/nvim-telescope/telescope.nvim) and (obviously) [VimWiki](https://github.com/vimwiki/vimwiki).

### Packer
```lua
    use {
        'mweyrich28/vimwikiUtils',
        requires = {
            'nvim-telescope/telescope.nvim',
            'vimwiki/vimwiki'
        }
    }
```

## Getting Started
For now I only implemented `vimwikiUtils_link`, you call the function using a keymap like this:

```lua
vim.api.nvim_set_keymap('i', '<C-b>', "<cmd>:lua require'vimwikiUtils'.vimwikiUtils_link()<CR>", { noremap = true, silent = true })
```
