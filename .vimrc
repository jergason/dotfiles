set nocompatible
syntax enable
set encoding=utf-8

" Load Vundle plugins
" required for Vundle
filetype off
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" manage Vundle w/ Vundle. Required
Plugin 'gmarik/Vundle.vim'

" My bundles from github

Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'jergason/gocode-vimscripts'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-surround'
Plugin 'mileszs/ack.vim'
Plugin 'ervandew/supertab'
Plugin 'kien/ctrlp.vim'
Plugin 'jnwhiteh/vim-golang'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-obsession'
Plugin 'scrooloose/syntastic'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'

" javascript/web
Plugin 'mxw/vim-jsx'
Plugin 'Shutnik/jshint2.vim'
Plugin 'nono/vim-handlebars'
Plugin 'digitaltoad/vim-jade'
Plugin 'wavded/vim-stylus'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'


" clojure
Plugin 'tpope/vim-fireplace'
Plugin 'tpope/vim-leiningen'
Plugin 'tpope/vim-classpath'
Plugin 'guns/vim-clojure-static'
Plugin 'kien/rainbow_parentheses.vim'

" themes
Plugin 'tomasr/molokai'
Plugin 'chriskempson/base16-vim'
Plugin 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Plugin 'noahfrederick/Hemisu'
Plugin 'altercation/vim-colors-solarized.git'
Plugin 'bclear'
Plugin 'summerfruit256.vim'

" haskell
Plugin 'dag/vim2hs'
Plugin 'bitc/vim-hdevtools'

" vim-scripts repos don't need username
Plugin 'nginx.vim'
Plugin 'SyntaxRange'

call vundle#end()

filetype plugin indent on       " load file type plugins + indentation
set showcmd                     " display incomplete commands

" make copy paste work with tmux
set clipboard=unnamed
" Color stuff

set background=dark
let g:solarized_termcolors=256

" make it not yell when first running BundleInstall and solarized doesn't
" exist yet
silent! colorscheme solarized

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
set shiftround " round indentation with > and < to multiples of shiftwidth
set nofoldenable " disable folding
set autoread " automatically reload file when changed outside of vim

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

" jump back and forth between previous panes
nnoremap <leader>p <C-W><C-P>

" toggle paste mode off and on
nnoremap <leader>o :set paste!<CR>

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

" nerdtree
" don't ask to delete buffer after file deleted
let NERDTreeAutoDeleteBuffer = 1

" nerdcommentor
" better haskell comments
let g:NERDCustomDelimiters = {
    \ 'haskell': { 'left': '--' },
    \ }


" Setup ctrlp.vim
" Ignore version control and binary files
let g:ctrlp_custom_ignore = {
 \ 'dir': '\.git$\|\.hg$\|\.svn$\|node_modules$',
 \ 'file': '\.o$\|\.exe$\|\.bin$'
 \ }


au FileType python set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0
au FileType go set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0 noexpandtab

au FileType haskell set softtabstop=2 tabstop=2 shiftwidth=2 textwidth=0
" Automatically call gofmt on golang files when saving as per
" http://stackoverflow.com/questions/10969366/vim-automatically-formatting-golang-source-code-when-saving
au FileType go au BufWritePre <buffer> Fmt

" .json files are javascript
au BufRead,BufNewFile *.json set ft=javascript

" These are all actually ruby files
au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,config.ru,*.gemspec} set ft=ruby

au BufRead,BufNewFile *.java set ft=java

""" syntastic stuff
" use eslint for javascript
let g:syntastic_javascript_checkers = ["eslint"]
" check syntax on file open
let g:syntastic_check_on_open=1
" close on no errors, open on errors
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list=2
let g:syntastic_haskell_checkers = ['hdevtools']

""" turn on rainbow parens always!
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces
