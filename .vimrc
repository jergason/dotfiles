set nocompatible
syntax enable
set encoding=utf-8

" Load all plugins with pathogen
call pathogen#infect()
call pathogen#helptags()

filetype plugin indent on       " load file type plugins + indentation
set showcmd                     " display incomplete commands

" Color stuff
set background=dark
colorscheme molokai

" Gutter
set number
set cursorline

" Show a vertical line at 80 characters
if exists('+colorcolumn')
  set cc=80
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif

" Allow background buffers without writing to them,
" and save marks/undo for background buffers.
set hidden

" Whitespace
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
set smartcase                   " ... unless they contain at least one capital letter

" Store swapfiles and backup files in .vim/tmp
set dir=~/.vim/tmp
set backupdir=~/.vim/tmp


" statusline
" see :help statusline for more info on these options
" always show status line
set laststatus=2
set statusline=file:%f " filename
set statusline+=[%{strlen(&fenc)?&fenc:'none'}, " file encoding
set statusline+=%{&ff}] " file format
set statusline+=%m " modified flag
set statusline+=%y " file type
set statusline+=%= " separator between right and left items
set statusline+=%{StatusLineFileSize()} " number of bytes or K in file
set statusline+=%l/%L " current line / total lines
set statusline+=\ %P " percentage through file

function! StatusLineFileSize()
  let size = getfsize(expand('%%:p'))
  if (size < 1024)
    return size . 'b '
  else
    let size = size / 1024
    return size . 'k '
  endif
endfunction

" Mappings
let mapleader="," " use , for leader instead of backslash
" use jj for esc
inoremap jj <esc>
" use leader leader to jump to the previously edited file
nnoremap <leader><leader> <C-^>

nnoremap <leader>p <C-W><C-P>

" Easier opening and closing of nerdtree
nnoremap <leader>t :NERDTreeToggle<CR>

" Eliminate all trailing whitespace
nnoremap <leader>w :%s/\s\+$//e<CR>

" clear search buffer when hitting return, so what you search for is not
" highlighted anymore. From Gary Bernhardt of Destroy All Software
nnoremap <CR> :nohlsearch<cr>

" CoffeeScript compilation
" Compile a highlighted section of code
vmap <leader>c <esc>:'<,'>:CoffeeCompile<CR>
" Compile the entire file if nothing is highlighted
map <leader>c :CoffeeCompile<CR>

" compile the whole coffeescript file and jump to a line
" useful for debugging stack traces
" Run with :C [line_number]
command -nargs=1 C CoffeeCompile | :<args>


" Plugin Setup
" ********************

" Setup ctrlp.vim
" Ignore version control and binary files
let g:ctrlp_custom_ignore = {
  \ 'dir': '\.git$\|\.hg$\|\.svn$',
  \ 'file': '\.o$\|\.exe$\|\.bin$'
  \ }


au FileType python set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0
au FileType go set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0

" .json files are javascript
au BufRead,BufNewFile *.json set ft=javascript

" These are all actually ruby files
au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,config.ru,*.gemspec} set ft=ruby

au BufRead,BufNewFile *.java set ft=java
