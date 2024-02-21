" Derived from cppman.vim
"
" Copyright (C) 2010 -  Wei-Ning Huang (AZ) <aitjcize@gmail.com>
" Copyright (C) 2023 -  Matthias Kretz <m.kretz@gsi.de>
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software Foundation,
" Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
"
"
" Vim syntax file
" Language:	Man page
" Maintainer:	SungHyun Nam <goweol@gmail.com>
" Modified:	Wei-Ning Huang <aitjcize@gmail.com>
" Previous Maintainer:	Gautam H. Mudunuri <gmudunur@informatica.com>
" Version Info:
" Last Change:	2008 Sep 17

" Additional highlighting by Johannes Tanzler <johannes.tanzler@aon.at>:
"	* manSubHeading
"	* manSynopsis (only for sections 2 and 3)

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded

function s:reload()
  setl noro
  setl ma
  echo "Loading... ".b:page_name
  silent exec "%d"
  let cppman = 'cppman --force-columns ' . winwidth(0)
  silent exec "0r! ".cppman." ".shellescape(b:page_name, 1)
  if getline(1) =~ '^No manual entry for ' && b:page_name =~ '_[tv]$'
    silent exec "%d"
    silent exec "0r! ".cppman." ".shellescape(b:page_name[:-3], 1)
  endif
  setl ro
  setl noma
  setl nomod
endfunction

function! s:ParseIdent()
  let s = getline( '.' )
  let i = col( '.' ) - 1
  while i > 0 && strpart( s, i, 1 ) =~ '[:A-Za-z0-9_]'
    let i = i - 1
  endwhile
  while i < col('$') && strpart( s, i, 1 ) !~ '[:A-Za-z0-9_]'
    let i = i + 1
  endwhile
  let start = match( s, '[:A-Za-z0-9_]\+', i )
  let end = matchend( s, '[:A-Za-z0-9_]\+', i )
  return substitute(strpart( s, start, end - start ),
        \ "stdx::", "std::experimental::", "")
endfunction

function! s:MaybeLoadNewPage()

  let page_names = systemlist("cppman -f ".s:ParseIdent())
  if len(page_names) == 1
    if page_names[0] =~ 'nothing appropriate'
      call popup_notification(page_names[0], #{
            \ pos: 'botleft',
            \ line: 'cursor-1',
            \ col: 'cursor',
            \ moved: 'WORD',
            \ })
    else
      call s:LoadNewPage(-1, page_names[0])
    endif
  else
    call popup_menu(page_names, #{
          \ callback: '<SID>LoadNewPage',
          \ })
  endif
endfunction

function! s:LoadNewPage(id, key)
  if a:id < 0
    let ident = a:key
  elseif a:key < 0
    return
  else
    let ident = getbufline(winbufnr(a:id), a:key)[0]
  endif
  " Save current page to stack
  call add(b:stack, [b:page_name, getpos(".")])
  let b:page_name = substitute(ident, " - .*$", "", "")
  setl noro
  setl ma
  call s:reload()
  normal! gg
  setl ro
  setl noma
  setl nomod
endfunction

function! s:BackToPrevPage()
  if len(b:stack) > 0
    let context = b:stack[-1]
    call remove(b:stack, -1)
    let b:page_name = context[0]
    call s:reload()
    call setpos('.', context[1])
  end
endfunction

function! OpenCpppage()
endfunction

function! s:Cppman(ident)
  let page_names = systemlist("cppman -f ".a:ident)
  if len(page_names) == 1
    if page_names[0] =~ 'nothing appropriate'
      call popup_notification(page_names[0], #{
            \ pos: 'botleft',
            \ line: 'cursor-1',
            \ col: 'cursor',
            \ moved: 'WORD',
            \ })
    else
      call s:CppmanOpen(-1, page_names[0])
    endif
  else
    call popup_menu(page_names, #{
          \ callback: '<SID>CppmanOpen',
          \ })
  endif
endfunction

function! s:CppmanOpen(id, key)
  if a:id < 0
    let ident = a:key
  elseif a:key < 0
    return
  else
    let ident = getbufline(winbufnr(a:id), a:key)[0]
  endif
  let lastbuf = bufnr()
  silent vertical bo new
  if (lastbuf == bufnr() || bufname() != "")
    echoerr "Creating a new window & buffer failed for some reason. Aborting."
    return
  endif
  silent vertical resize 80
  let b:page_name = substitute(ident, " - .*$", "", "")
  setl nonu
  setl nornu
  setl noma
  setl buftype=nofile
  setl bufhidden=delete
  setl noswapfile

  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif

  syntax on
  syntax case ignore
  syntax match  manReference       "[a-z_:+-\*][a-z_:+-~!\*<>()]\+ ([1-9][a-z]\=)"
  syntax match  manTitle           "^\w.\+([0-9]\+[a-z]\=).*"
  syntax match  manSectionHeading  "^[a-z][a-z_ \-:]*[a-z]$"
  syntax match  manSubHeading      "^\s\{3\}[a-z][a-z ]*[a-z]$"
  syntax match  manOptionDesc      "^\s*[+-][a-z0-9]\S*"
  syntax match  manLongOptionDesc  "^\s*--[a-z0-9-]\S*"

  syntax include @cppCode runtime! syntax/cpp.vim
  syntax match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained

  syntax region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition
  syntax region manSynopsis start="^EXAMPLE"hs=s+7 end="^       [^ ]"he=s-1 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition

  " Define the default highlighting.
  " For version 5.7 and earlier: only when not done already
  " For version 5.8 and later: only when an item doesn't have highlighting yet
  if version >= 508 || !exists("did_man_syn_inits")
    if version < 508
      let did_man_syn_inits = 1
      command -nargs=+ HiLink hi link <args>
    else
      command -nargs=+ HiLink hi def link <args>
    endif

    HiLink manTitle	    Title
    HiLink manSectionHeading  Statement
    HiLink manOptionDesc	    Constant
    HiLink manLongOptionDesc  Constant
    HiLink manReference	    PreProc
    HiLink manSubHeading      Function
    HiLink manCFuncDefinition Function

    delcommand HiLink
  endif

  """ Vim Viewer
  setl mouse=a
  setl colorcolumn=0

  let b:stack = []

  call s:reload()
  normal! gg

  noremap <buffer> <S-K> :call <SID>MaybeLoadNewPage()<CR>
  map <buffer> <CR> <S-K>
  map <buffer> <C-]> <S-K>
  map <buffer> <2-LeftMouse> <S-K>

  noremap <buffer> <C-o> :call <SID>BackToPrevPage()<CR>
  map <buffer> <RightMouse> <C-o>
  map <buffer> <C-[> <C-o>

  let b:current_syntax = "man"
endfunction

nmap <Leader>c :call <SID>Cppman(<SID>ParseIdent())<CR>

command! -nargs=+ Cppman call s:Cppman(expand(<q-args>))
