setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand call VUIOutputCommand()
command -buffer VUIExecuteCommand call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput call VUIExecuteCommandAndReadOuput()
command -buffer VUIWriteResults call VUIWriteResults()

function s:MapDefault(keys, value)
    if !hasmapto(a:value)
        execute 'nmap <buffer> ' . a:keys . ' ' . a:value
    endif
endfunction

function s:MapDefaultWithLocalLeader(keys, value)
    call s:MapDefault('<localleader>' . a:keys, a:value)
endfunction

call s:MapDefaultWithLocalLeader('o', '<Plug>(vui-output-command)')
call s:MapDefaultWithLocalLeader('e', '<Plug>(vui-execute-command)')
call s:MapDefaultWithLocalLeader('r', '<Plug>(vui-execute-command-and-read)')
call s:MapDefaultWithLocalLeader('w', '<Plug>(vui-write-results)')
call s:MapDefaultWithLocalLeader('c', '<Plug>(vui-clear-arg-for-line)')
call s:MapDefaultWithLocalLeader('t', '<Plug>(vui-toggle-arg)')
call s:MapDefaultWithLocalLeader('<CR>', '<Plug>(vui-change-arg-for-line)')

" NEED HASMAPTO
imap <buffer> <F5> <Plug>(vui-complete)
inoremap <buffer><silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <buffer><silent><expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
