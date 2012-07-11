" Don't beep
set visualbell

" Start without the toolbar
set guioptions-=T

" Turn off scrollbars
set guioptions-=L
set guioptions-=R
set guioptions-=l
set guioptions-=r

if has("gui_gtk2")
  set guifont=Monospace\ 13
else
  set guifont=Inconsolata:h17
endif


" Lazy redraw, for MacVim speedups
set lazyredraw
