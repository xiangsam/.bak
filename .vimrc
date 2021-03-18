set nocompatible
syntax on
set number
set tabstop=4
set softtabstop=-1
set shiftwidth=4
set noexpandtab
set autoindent
set cindent
set smarttab
set laststatus=2
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'ycm-core/YouCompleteMe'
Plugin 'jiangmiao/auto-pairs'
Plugin 'dense-analysis/ale'
Plugin 'itchyny/lightline.vim'
Plugin 'Chiel92/vim-autoformat'
call vundle#end()
set completeopt=menu,menuone
let g:ycm_server_python_interpreter='/usr/bin/python3'
let g:ycm_global_ycm_extra_conf='~/.vim/bundle/YouCompleteMe/.ycm_extra_conf.py'
let g:ycm_add_preview_to_completeopt = 0
let g:ycm_server_log_level = 'info'
let g:ycm_min_num_identifier_candidate_chars = 2
let g:ycm_collect_identifiers_from_comments_and_strings = 0
let g:ycm_complete_in_strings=1
let g:ycm_show_diagnostics_ui = 0
highlight PMenu ctermfg=0 ctermbg=242 guifg=black guibg=darkgrey
let g:ycm_semantic_triggers =  {
                        \ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
                        \ 'cs,lua,javascript': ['re!\w{2}'],
                        \ }

let g:ale_linters_explicit = 1
let g:ale_completion_delay = 500
let g:ale_echo_delay = 20
let g:ale_lint_delay = 500
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:airline#extensions#ale#enabled = 1

let g:ale_c_gcc_options = '-Wall -O2 -std=c99'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'
let g:ale_c_cppcheck_options = '--enable=all'
let g:ale_cpp_cppcheck_options = '--enable=all'
let g:ale_python_pylint_options = '--disable=C0111,C0103'
let g:ale_linters = {
  \   'c': ['gcc', 'cppcheck'],
  \   'cpp': ['gcc','cppcheck'],
  \   'csh': ['shell'],
  \   'zsh': ['shell'],
  \   'go': ['gofmt', 'golint'],
  \   'python': ['pylint'],
  \}


let g:formatdef_clangformat_google = '"clang-format -style google -"'
let g:formatters_c = ['clangformat_google']
let g:formatter_yapf_style = 'google'

filetype plugin indent on
