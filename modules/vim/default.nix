# Home manager module that configures neovim with some plugins
{ pkgs, config, lib, ... }:
{
  programs.neovim =
    {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins =
        with pkgs.vimPlugins; [
          vim-surround
        ];
      extraConfig =
        ''
          syntax on

          let mapleader="\<Space>"

          nnoremap <leader>wl <C-w>l
          nnoremap <leader>wk <C-w>k
          nnoremap <leader>wj <C-w>j
          nnoremap <leader>wh <C-w>h

          nnoremap <silent> <leader>ws :split<CR>
          nnoremap <silent> <leader>wv :vsplit<CR>
          " close the _window_, not the buffer
          nnoremap <silent> <leader>wd <C-w>c

          set number relativenumber
          set modelines=1
          set autoindent
          set ignorecase
          set smartcase incsearch
          filetype plugin on

          " cursor shapes in insert/normal modes
          let &t_SI = "\e[6 q"
          let &t_EI = "\e[2 q"
        '';
    };
}
