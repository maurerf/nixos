with import <nixpkgs> {};

vim_configurable.customize {
    name = "vim";
    vimrcConfig.customRC = ''
set nocompatible                " choose no compatibility with legacy vi
syntax enable
set encoding=UTF-8
set showcmd                     " display incomplete commands
set nu
filetype plugin indent on       " load file type plugins + indentation

"" Whitespace
set nowrap                      " don't wrap lines
set tabstop=4 shiftwidth=4      " a tab is two spaces (or set this to 4)
"" set expandtab                   " use spaces, not tabs (optional)
set backspace=indent,eol,start  " backspace through everything in insert mode

"" Searching
set hlsearch                    " highlight matches
set incsearch                   " incremental searching
set ignorecase                  " searches are case insensitive...
"" set smartcase                   " ... unless they contain at least one capital letter

let g:tex_flavor = "latex"
    '';
}
