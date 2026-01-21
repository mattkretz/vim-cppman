vim9script
# Derived from cppman.vim
#
# Copyright (C) 2010 -  Wei-Ning Huang (AZ) <aitjcize@gmail.com>
# Copyright © 2023–2026  GSI Helmholtzzentrum fuer Schwerionenforschung GmbH
#                        Matthias Kretz <m.kretz@gsi.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
# Vim syntax file
# Language:	Man page
# Maintainer:	SungHyun Nam <goweol@gmail.com>
# Modified:	Wei-Ning Huang <aitjcize@gmail.com>
# Previous Maintainer:	Gautam H. Mudunuri <gmudunur@informatica.com>
# Version Info:
# Last Change:	2008 Sep 17

# Additional highlighting by Johannes Tanzler <johannes.tanzler@aon.at>:
#	* manSubHeading
#	* manSynopsis (only for sections 2 and 3)

def Reload()
  setl noro
  setl ma
  echo "Loading... " .. b:page[1]
  silent exec ":%d"
  var cppman = expand('<script>:p:h:h') .. '/cppman_wrapper.sh ' .. b:page[0] .. ' --force-columns ' .. winwidth(0)
  silent exec ":0r! " .. cppman .. " -n 30 -f " .. shellescape(b:page[1], 1)
  silent exec ":normal! ggd/^NAME$\<CR>"
  setl ro
  setl noma
  setl nomod
enddef

def ParseIdent(): string
  var s = getline( '.' )
  var i = col( '.' ) - 1
  while i > 0 && strpart( s, i, 1 ) =~ '[:A-Za-z0-9_]'
    i = i - 1
  endwhile
  while i < col('$') && strpart( s, i, 1 ) !~ '[:A-Za-z0-9_]'
    i = i + 1
  endwhile
  var start = match( s, '[:A-Za-z0-9_]\+', i )
  var end = matchend( s, '[:A-Za-z0-9_]\+', i )
  return substitute(strpart( s, start, end - start ),
    "stdx::", "std::experimental::", "")
enddef

def MaybeLoadNewPage()
  var ident = ParseIdent()
  var page_names = systemlist("cppman -n 30 -f " .. ident)
  if page_names[0] =~ 'nothing appropriate'
    popup_notification(page_names[0], {
      pos: 'botleft',
      line: 'cursor-1',
      col: 'cursor',
      moved: 'WORD',
    })
  elseif page_names[0] != ''
    LoadNewPage(1, ident)
  else
    filter(page_names, 'v:val =~ "^[0-9]"')
    popup_menu(page_names, {
      callback: (_, id) => {
        LoadNewPage(id, ident)
      }
    })
  endif
enddef

def LoadNewPage(id: number, ident: string)
  # Save current page to stack
  add(b:stack, [b:page, getpos(".")])
  b:page = [id, ident]
  setl noro
  setl ma
  Reload()
  normal! gg
  setl ro
  setl noma
  setl nomod
enddef

def BackToPrevPage()
  if len(b:stack) > 0
    var context = b:stack[-1]
    remove(b:stack, -1)
    b:page = context[0]
    Reload()
    setpos('.', context[1])
  endif
enddef

def Cppman(ident: string)
  var page_names = systemlist("cppman -n 30 -f " .. ident)
  if page_names[0] =~ 'nothing appropriate'
    popup_notification(page_names[0], {
      pos: 'botleft',
      line: 'cursor-1',
      col: 'cursor',
      moved: 'WORD',
    })
  elseif page_names[0] != ''
    CppmanOpen(1, ident)
  else
    filter(page_names, 'v:val =~ "^[0-9]"')
    popup_menu(page_names, {
      callback: (_, id) => {
        CppmanOpen(id, ident)
      },
    })
  endif
enddef

def CppmanOpen(id: number, ident: string)
  var lastbuf = bufnr()
  silent vertical bo new
  if (lastbuf == bufnr() || bufname() != "")
    echoerr "Creating a new window & buffer failed for some reason. Aborting."
    return
  endif
  silent vertical resize 80
  b:page = [id, ident]
  setl nonu
  setl nornu
  setl noma
  setl buftype=nofile
  setl bufhidden=delete
  setl noswapfile

  if exists("b:current_syntax")
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

  # Define the default highlighting.
  hi def link manTitle	    Title
  hi def link manSectionHeading  Statement
  hi def link manOptionDesc	    Constant
  hi def link manLongOptionDesc  Constant
  hi def link manReference	    PreProc
  hi def link manSubHeading      Function
  hi def link manCFuncDefinition Function

  # Vim Viewer
  setl mouse=a
  setl colorcolumn=0

  b:stack = []

  Reload()
  normal! gg

  noremap <buffer> <S-K> :call <SID>MaybeLoadNewPage()<CR>
  map <buffer> <CR> <S-K>
  map <buffer> <C-]> <S-K>
  map <buffer> <2-LeftMouse> <S-K>

  noremap <buffer> <C-o> :call <SID>BackToPrevPage()<CR>
  map <buffer> <RightMouse> <C-o>
  map <buffer> <C-[> <C-o>

  b:current_syntax = "man"
enddef

nmap <Leader>c :call <SID>Cppman(<SID>ParseIdent())<CR>

command! -nargs=+ Cppman call <SID>Cppman(expand(<q-args>))
