_: {
  home.file.".ideavimrc".text =
    # vimrc
    ''
      let mapleader="\<Space>"

      " window navigation shortcuts
      nnoremap <leader>wl <C-W>l
      nnoremap <leader>wk <C-W>k
      nnoremap <leader>wj <C-W>j
      nnoremap <leader>wh <C-W>h

      " jump to next error
      nnoremap ]d :action GotoNextError<CR>
      nnoremap [d :action GotoPreviousError<CR>

      Plug 'tpope/vim-surround'
      Plug 'tpope/vim-commentary'
      Plug 'easymotion/vim-easymotion'

      " jump around
      map <leader>j <Plug>(easymotion-bd-w)

      set ideajoin
      set smartcase
      set easymotion

      " Disable all bells
      set visualbell
      set noerrorbells
      " yank highlight
      set highlightedyank
      let g:highlightedyank_highlight_duration="100"

      " TODO: works on darwin?
      set clipboard+=unnamed
    '';
}
