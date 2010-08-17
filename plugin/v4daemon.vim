" ------------------------------------------------------------------------------
" File:		plugin/v4daemon.vim: vim for daemon
"			  Run a daemon and feed it from vim buffers.
" Author:	Umit Kablan <uKa>
" Maintainer:	<ctrl-y> :-)
"
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
"		This program is distributed in the hope that it will be
"		useful, but WITHOUT ANY WARRANTY; without even the implied
"		warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
"
" Version:	0.1a ALPHA
"
" Files:	The plugin consists of the following files:
"		plugin/v4daemon.vim
"		g:v4d_sendcmd_directory/v4d_sendcmd.sh
" Variables:   g:v4d_sendcmd_directory - Change the default location of
"  v4d_sendcmd.sh shipped with the pack.

if exists("loaded_v4daemon")
  finish
endif
let loaded_v4daemon = 1

au! VimLeavePre * :call <SID>StopDaemon()<cr>

let s:V4d_Pipe = ""
let s:V4d_Progname = ""

if !exists("g:v4d_sendcmd_directory")
    let g:v4d_sendcmd_directory = $HOME . "/.vim"
endif

com! -nargs=*        V4dStart    call <SID>StartDaemon(<f-args>)
com! -nargs=0        V4dStop     call <SID>StopDaemon()
com! -nargs=0 -range V4dSendLine <line1>,<line2>call <SID>SendLine()
com! -nargs=0 -range V4dSendWord <line1>,<line2>call <SID>SendWord()

function! <SID>StartDaemon(progname, ...)
    if s:V4d_Pipe != ""
        echoerr "A Daemon -" . s:V4d_Progname . "- is already running: Stop it first."
        return
    endif

    let s:V4d_Progname = a:progname
    let s:V4d_Pipe = tempname()
    let res = system('mkfifo ' . s:V4d_Pipe)
    "if res != "0"
    "    echoerr "could not create " . s:V4d_Pipe . " :" . ress
    "    return
    "endif
    
    let cmd = "!sh " . g:v4d_sendcmd_directory . "/v4d_sendcmd.sh " . s:V4d_Pipe . " | " . a:progname
    for i in range(1,a:0)
        let cmd = cmd . " " . a:{i}
    endfor
    let cmd = cmd . "&"
    
    exe cmd
endfunction

function! <SID>StopDaemon()
    if s:V4d_Pipe != ""
        let res = system("echo __EOF__ > " . s:V4d_Pipe)
        let res = system('rm -f ' . s:V4d_Pipe)
        let res = system('killall ' . s:V4d_Progname)
        let s:V4d_Progname = ""
        let s:V4d_Pipe = ""
    endif
endfunction

function! s:Send(str)
    if s:V4d_Pipe != ""
        let res = system('echo -n '. shellescape(a:str) . ' > ' . s:V4d_Pipe)
    endif
endfunction

function! <SID>SendLine() range
    for i in range(a:firstline, a:lastline)
        call s:Send(getline(i))
    endfor
endfunction

function! <SID>SendWord() range
    if visualmode() == "\<c-v>"
       echoerr "Visual block mode is not supported"
       return
    endif
    if visualmode() ==# "V"
       echoerr "Use SendLine instead"
       return
    endif
    let y1      = line("'<")
    let y2      = line("'>")
    let leftcol = virtcol("'<")
    let rghtcol = virtcol("'>")
    if y1 < y2 
        call s:Send(strpart(getline(y1), leftcol-1))
        let i = y1+1
        while i < y2
            call s:Send(getline(i))
            let i = i+1
        endwhile
        call s:Send(strpart(getline(y2), 0, rghtcol))
    endif
    if y1 == y2 
        call s:Send(strpart(getline(y1), leftcol-1, (rghtcol-leftcol)))
    endif
endfunction

