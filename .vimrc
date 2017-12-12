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
Plugin 'mileszs/ack.vim'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-rhubarb'
Plugin 'plasticboy/vim-markdown'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'airblade/vim-gitgutter'
Plugin 'easymotion/vim-easymotion' " TODO: figure this out more
Plugin 'tmhedberg/matchit'
Plugin 'mitermayer/vim-prettier'
Plugin 'w0rp/ale'
Plugin 'valloric/youcompleteme'

Plugin 'janko-m/vim-test'
" for writing
Plugin 'junegunn/goyo.vim'

" javascript/web
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'digitaltoad/vim-pug'
Plugin 'wavded/vim-stylus'
Plugin 'cakebaker/scss-syntax.vim'
Plugin 'hail2u/vim-css3-syntax'
Plugin 'mattn/emmet-vim'
Plugin 'ElmCast/elm-vim'
Plugin 'posva/vim-vue'

Plugin 'fatih/vim-go'

" snippets
Plugin 'SirVer/ultisnips'
Plugin 'jergason/vim-snippets'

" clojure
Plugin 'luochen1990/rainbow'

" elixir
Plugin 'elixir-lang/vim-elixir'
Plugin 'slashmili/alchemist.vim'


" themes
Plugin 'tomasr/molokai'
Plugin 'altercation/vim-colors-solarized.git'
Plugin 'summerfruit256.vim'
Plugin 'itchyny/landscape.vim'
Plugin 'jergason/toothpaste'
Plugin 'nanotech/jellybeans.vim'
Plugin 'zenorocha/dracula-theme', {'rtp': 'vim/'}
Plugin 'jordwalke/flatlandia'
Plugin 'trevordmiller/nova-vim'


call vundle#end()

filetype plugin indent on       " load file type plugins + indentation
set showcmd                     " display incomplete commands

" use terminal gui colors (makes some themes work)
set termguicolors

" soft wrap all lines (why doesn't this work?)
set wrap
set lbr

" don't change directory when opening files
set noautochdir

" make copy paste work with tmux
set clipboard=unnamed

" enable modeline support
set modelines=1
set modeline

" make it not yell when first running BundleInstall and the colorsheme doesn't
" exist yet
silent! colorscheme landscape

" Gutter
set number

set nocursorline "cursorline is slow
set norelativenumber "relativenumber is also slow :(

augroup perf_settings " {
  "au VimEnter * NoMatchParen
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
set statusline=
set statusline=%f " filename
"set statusline+=%1*\ %<%F\                                "File+path
set statusline+=%m " modified flag
set statusline+=%y " file type

" ale statusline stuff
set statusline+=%{ALEGetStatusLine()}
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

" search for word under the cursor
nnoremap <leader>s :Ack <C-R><C-W><CR>

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

" vim-test mappings
" test the current file
map <Leader>e :TestFile<CR>
" test the last file that was tested
map <Leader>l :TestLast<CR>

" show or hide bottom status bar. useful for egghead recordings
" see http://unix.stackexchange.com/questions/140898/vim-hide-status-line-in-the-bottom
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction

function! EggheadMode()
  :call ToggleHiddenAll()
  :set nu!
endfunction

nnoremap <S-h> :GitGutterToggle<CR> :call EggheadMode()<CR>

" prettier stuff
" override the vim-prettier changing default prettier settings
let g:prettier#config#single_quote = 'false'
let g:prettier#config#trailing_comma = 'none'
let g:prettier#config#bracket_spacing = 'true'
let g:prettier#config#jsx_bracket_same_line = 'false'
let g:prettier#config#parser = 'babylon'

let g:PrettierToggle = 1
augroup prettier
    autocmd!
    autocmd BufWritePre *.js,*.css,*.scss,*.less PrettierAsync
augroup END

function! TogglePrettier()
    " Switch the toggle variable
    let g:PrettierToggle = !get(g:, 'PrettierToggle', 1)

    " Reset group
    augroup prettier
        autocmd!
    augroup END

    " Enable if toggled on
    if g:PrettierToggle
        augroup prettier
            autocmd! BufWritePre *.js,*.css,*.scss,*.less PrettierAsync
        augroup END
    endif
endfunction


nnoremap <leader>pr :call TogglePrettier()<CR>

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

" vim-jsx should apply to .js files too
let g:jsx_ext_required = 0

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

  au FileType go setlocal softtabstop=4 tabstop=4 noexpandtab shiftwidth=4 autoindent

  au FileType javascript setlocal suffixesadd+=.js,.jsx

  au FileType elm map <Leader>m :ElmMake<CR>
  au FileType elm map <Leader>b :ElmMakeMain<CR>
  au FileType elm map <Leader>r :ElmRepl<CR>
  "au FileType elm map <Leader>t :ElmTest<CR>
  au FileType elm map <Leader>e :ElmErrorDetail<CR>
  au FileType elm map <Leader>d :ElmShowDocs<CR>
  au FileType elm map <Leader>f :ElmFormat<CR>

  au FileType markdown setlocal wrap lbr spell
  au FileType markdown nnoremap <Leader>g :Goyo<CR>

  au BufRead,BufNewFile *.icss setlocal ft=css
  au BufRead,BufNewFile *.istyl setlocal ft=stylus

  au BufRead,BufNewFile {.eslintrc,.eslintignore} setlocal ft=json

  " These are all actually ruby files
  au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,config.ru,*.gemspec} setlocal ft=ruby

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

" Neoformat stuff
"let g:neoformat_run_all_formatters = 1
"let g:neoformat_enabled_javascript = ['prettier']

" check syntax on save
let g:ale_lint_on_text_changed = 'never'
" use the globally installed flow (makes it easier to reproduce errors on
" command line, harder to manage different versions of flow per project
let g:javascript_flow_use_global = 0
let g:ale_statusline_format = ['⨉ %d', '⚠ %d', '⬥ ok']

" rainbow parens
let g:rainbow_active = 0

" try to load a .vimlocal file with custom project-specific settings
silent! so .vimlocal
