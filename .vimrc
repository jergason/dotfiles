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

Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'tpope/vim-surround'
Plugin 'ervandew/supertab'
Plugin 'mileszs/ack.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-obsession'
Plugin 'scrooloose/syntastic'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'airblade/vim-gitgutter'
"Plugin 'vim-airline/vim-airline' " seems to be causing some perf problems
"Plugin 'vim-airline/vim-airline-themes'
Plugin 'easymotion/vim-easymotion'
Plugin 'tmhedberg/matchit'

" javascript/web
Plugin 'mxw/vim-jsx'
Plugin 'wavded/vim-stylus'
Plugin 'cakebaker/scss-syntax.vim'
Plugin 'hail2u/vim-css3-syntax'
Plugin 'pangloss/vim-javascript'
Plugin 'mattn/emmet-vim'
Plugin 'trotzig/import-js' " TODO: learn to use this better
Plugin 'ElmCast/elm-vim'
" use a local eslint if it exists in ./node_modules/.bin
Plugin 'mtscout6/syntastic-local-eslint.vim'

" snippets
Plugin 'SirVer/ultisnips'
Plugin 'jergason/vim-snippets'

" clojure
Plugin 'luochen1990/rainbow'

" themes
Plugin 'tomasr/molokai'
Plugin 'altercation/vim-colors-solarized.git'
Plugin 'summerfruit256.vim'
Plugin 'nanotech/jellybeans.vim'
Plugin 'itchyny/landscape.vim'
Plugin 'adlawson/vim-sorcerer'
Plugin 'jpo/vim-railscasts-theme'
Plugin 'jordwalke/flatlandia'
Plugin 'zenorocha/dracula-theme', {'rtp': 'vim/'}
Plugin 'vim-scripts/light2011'

" haskell
Plugin 'dag/vim2hs'
Plugin 'bitc/vim-hdevtools'

" vim-scripts repos don't need username
Plugin 'SyntaxRange' " dependency for vimdeck



call vundle#end()

filetype plugin indent on       " load file type plugins + indentation
set showcmd                     " display incomplete commands

" make copy paste work with tmux
set clipboard=unnamed

" make it not yell when first running BundleInstall and the colorsheme doesn't
" exist yet
silent! colorscheme molokai

" Gutter
set number

set nocursorline "cursorline is slow
set norelativenumber "relativenumber is also slow :(

augroup perf_settings " {
  au VimEnter * NoMatchParen
augroup END " }


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

" statusline colors
hi User1 guifg=#ffdad8  guibg=#880c0e
hi User2 guifg=#000000  guibg=#F4905C
hi User3 guifg=#292b00  guibg=#f4f597
hi User4 guifg=#112605  guibg=#aefe7B
hi User5 guifg=#051d00  guibg=#7dcc7d
hi User7 guifg=#ffffff  guibg=#880c0e gui=bold
hi User8 guifg=#ffffff  guibg=#5b7fbb
hi User9 guifg=#ffffff  guibg=#810085
hi User0 guifg=#ffffff  guibg=#094afe

" always show status line
set laststatus=2
set statusline=
set statusline=%f " filename
"set statusline+=%1*\ %<%F\                                "File+path
set statusline+=%m " modified flag
set statusline+=%y " file type
" set statusline+=%{fugitive#statusline()} " current branch from fugitive
" (this is slow)
" syntastic statusline stuff
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

set statusline+=%= " separator between right and left items
set statusline+=%{StatusLineFileSize()} " number of bytes or K in file
set statusline+=col:%c\ 
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

" Airline config
"let g:airline_section_z='%{StatusLineFileSize()}'

"if !exists('g:airline_symbols')
  "let g:airline_symbols = {}
"endif

"" unicode symbols
"let g:airline_left_sep = ''
"let g:airline_left_alt_sep = ''
"let g:airline_right_sep = ''
"let g:airline_right_alt_sep = ''
"let g:airline_symbols.crypt = '🔒'
"let g:airline_symbols.linenr = '␊'
"let g:airline_symbols.linenr = '␤'
"let g:airline_symbols.linenr = '¶'
"let g:airline_symbols.branch = ''
"let g:airline_symbols.paste = 'ρ'
"let g:airline_symbols.spell = 'Ꞩ'
"let g:airline_symbols.notexists = '∄'
"let g:airline_symbols.whitespace = 'Ξ'


" Mappings
let mapleader="," " use , for leader instead of backslash
" use jj for esc
inoremap jj <esc>
" use leader leader to jump to the previously edited file
nnoremap <leader>a <C-^>

" jump back and forth between previous panes
nnoremap <leader>p <C-W><C-P>

" join lines together and remove whitespace between the newly joined lines
nnoremap J Jdw

" toggle paste mode off and on
nnoremap <leader>o :set paste!<CR>

" Easier opening and closing of nerdtree
nnoremap <leader>t :NERDTreeToggle<CR>

" Eliminate all trailing whitespace
nnoremap <leader>w :%s/\s\+$//e<CR>

" clear search buffer when hitting return, so what you search for is not
" highlighted anymore. From Gary Bernhardt of Destroy All Software
nnoremap <CR> :nohlsearch<cr>

" format selected text in visual mode as json
" from http://blog.realnitro.be/2010/12/20/format-json-in-vim-using-pythons-jsontool-module/
" i have no idea why this works
map <Leader>j :%!python -m json.tool<CR>

" Large file management
let g:large_file = 1024 * 1024 * 5 " 5 MB
augroup large_file
  autocmd!
  function! ManageLargeFiles()
    let f = expand("<afile>")
    if getfsize(f) > g:large_file
      setlocal bufhidden=unload " save memory when other file is viewed
      setlocal noswapfile " no swapfiles of large files
      setlocal undolevels=1 " only 1 undo level
      setlocal syntax=off " turn off syntax highlighting by default
    endif
  endfunction

  au BufReadPre * :call ManageLargeFiles()
augroup END


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
 \ 'dir': '\.git$\|\.hg$\|\.svn$\|node_modules$\|coverage$\|elm-stuff$',
 \ 'file': '\.o$\|\.exe$\|\.bin$'
 \ }

augroup file_type_settings " {
  au FileType python setlocal softtabstop=4 tabstop=4 shiftwidth=4 textwidth=0

  au FileType haskell setlocal softtabstop=2 tabstop=2 shiftwidth=2 textwidth=0

  au FileType javascript setlocal suffixesadd+=.js,.jsx

  au FileType elm map <Leader>m :ElmMake<CR>
  au FileType elm map <Leader>b :ElmMakeMain<CR>
  au FileType elm map <Leader>r :ElmRepl<CR>
  "au FileType elm map <Leader>t :ElmTest<CR>
  au FileType elm map <Leader>e :ElmErrorDetail<CR>
  au FileType elm map <Leader>d :ElmShowDocs<CR>
  au FileType elm map <Leader>f :ElmFormat<CR>

  au BufRead,BufNewFile *.icss setlocal ft=css
  au BufRead,BufNewFile *.istyl setlocal ft=stylus

  au BufRead,BufNewFile {.eslintrc,.eslintignore} setlocal ft=json

  " These are all actually ruby files
  au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,config.ru,*.gemspec} setlocal ft=ruby

  au BufRead,BufNewFile {*.ex,*.exs} setlocal ft=ruby

  au BufRead,BufNewFile *.java setlocal ft=java
augroup END " }

" Autoreload vimrc on changes woo!
augroup reload_vimrc " {
  autocmd!
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" Elm stuff
let g:elm_jump_to_error = 0
let g:elm_setup_keybindings = 0

" Syntastic stuff
" disable vim-flow syntax checking, we want to use syntastic
let g:flow#enable=0
" use flow not flow check for syntax checking
" let g:syntastic_javascript_flow_exe = 'flow'

" syntastic stuff
" use eslint for javascript
let g:syntastic_javascript_checkers = ["eslint"]

" elm woo
let g:syntastic_elm_checkers = ["elm_make"]

" check syntax on file open
let g:syntastic_check_on_open=1
" close on no errors, open on errors
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list=2
let g:syntastic_haskell_checkers = ['hdevtools']


" omnicomplete/supertab interaction
" TODO: figure this out better
set omnifunc=syntaxcomplete#Complete
" make supertab use omnicomplete
"let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
" make supertab examine the context to decide whether to use omnicomplete
let g:SuperTabDefaultCompletionType = "context"


" rainbow parens
let g:rainbow_active = 0
