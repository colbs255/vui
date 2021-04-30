setlocal completefunc=VUIArgValueCompletion
setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand call VUIOutputCommand()
command -buffer VUIExecuteCommand call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput call VUIExecuteCommandAndReadOuput()
command -buffer VUIWriteResults call VUIWriteResults()

function s:MapDefault(keys, value)
    if !hasmapto(a:value)
        execute 'nmap <buffer> <localleader>' . a:keys . ' ' . a:value
    endif
endfunction

call s:MapDefault('o', '<Plug>(vui-output-command)')
call s:MapDefault('e', '<Plug>(vui-execute-command)')
call s:MapDefault('r', '<Plug>(vui-execute-command-and-read)')
call s:MapDefault('w', '<Plug>(vui-write-results)')
call s:MapDefault('c', '<Plug>(vui-change-arg-for-line)')
call s:MapDefault('t', '<Plug>(vui-toggle-arg)')
