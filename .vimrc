set nocompatible
syntax enable
set encoding=utf-8

call pathogen#infect()
filetype plugin indent on       " load file type plugins + indentation
au FileType python set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0
set showcmd                     " display incomplete commands

set background=dark
colorscheme solarized

" Gutter
set number
set cursorline

" Allow background buffers without writing to them,
" and save marks/undo for background buffers.
set hidden

"" Whitespace
set nowrap                      " don't wrap lines
set tabstop=2                   " a tab is two spaces
set shiftwidth=2
set softtabstop=2
set expandtab                   " use spaces, not tabs
set backspace=indent,eol,start  " backspace through everything in insert mode

" How to display tabs, trailing whitespace, and lines that extend to left of screen
set listchars=tab:\ \ ,trail:·,extends:>,precedes:\<
set list

" Searching
set hlsearch                    " highlight matches
set incsearch                   " incremental searching
set ignorecase                  " searches are case insensitive...
set smartcase                   " ... unless they contain at least one capital letter

" Store swapfiles and backup files in .vim/tmp
set dir=~/.vim/tmp
set backupdir=~/.vim/tmp


" Mappings
let mapleader="," " use , for leader instead of backslash
" use jj for esc
inoremap jj <esc>
" use leader leader to jump to the previously edited file
nnoremap <leader><leader> <C-^>

" clear search buffer when hitting return, so what you search for is not
" highlighted anymore. From Gary Bernhardt of Destroy All Software
:nnoremap <CR> :nohlsearch<cr>

" remap coffeescript compilation
vmap <leader>c <esc>:'<,'>:CoffeeCompile<CR>
map <leader>c :CoffeeCompile<CR>

" compile the whole coffeescript file and jumpt to a line
" useful for debugging stack traces
command -nargs=1 C CoffeeCompile | :<args>


" .json files are javascript
au BufRead,BufNewFile *.json set ft=javascript

" These are all actually ruby files
au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,config.ru,*.gemspec} set ft=ruby

" Open NerdTree when Vim starts
au VimEnter * NERDTree
au VimEnter * wincmd p


" Highlight coloumns over 80 characters long
if exists('+colorcoloumn')
  set cc=80
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif
