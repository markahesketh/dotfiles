" == SETTINGS ============================================================
syntax on       			       " Coloured syntax
set background=light	           " Theme
set number                         " Line numbers
set autoread		               " Update files that change
set cursorline                     " Highlight current line

" Ignore these files/folders
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*.,*/.DS_Store
set wildignore+=*/vendor/**

" Tabs - use 4 spaces
set expandtab
set softtabstop=4
set shiftwidth=4

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif
