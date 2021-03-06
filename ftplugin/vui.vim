setlocal buftype=nofile
setlocal bufhidden=hide
setlocal noswapfile

command -buffer VUIOutputCommand call VUIOutputCommand()
command -buffer VUIExecuteCommand call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput call VUIExecuteCommandAndReadOuput()
command -buffer VUISaveResults call VUISaveResults()
command -buffer VUIParseArgsFromString call VUIParseArgsFromString()

function s:MapDefault(keys, value, maptype)
    if !hasmapto(a:value)
        execute a:maptype . 'map <buffer> ' . a:keys . ' ' . a:value
    endif
endfunction

function s:MapDefaultWithLocalLeader(keys, value)
    call s:MapDefault('<localleader>' . a:keys, a:value, 'n')
endfunction

call s:MapDefaultWithLocalLeader('o', '<Plug>(vui-output-command)')
call s:MapDefaultWithLocalLeader('e', '<Plug>(vui-execute-command)')
call s:MapDefaultWithLocalLeader('r', '<Plug>(vui-execute-command-and-read)')
call s:MapDefaultWithLocalLeader('s', '<Plug>(vui-save-results)')
call s:MapDefaultWithLocalLeader('c', '<Plug>(vui-clear-arg-for-line)')
call s:MapDefaultWithLocalLeader('t', '<Plug>(vui-toggle-arg)')
call s:MapDefaultWithLocalLeader('p', '<Plug>(vui-parse-args)')
call s:MapDefaultWithLocalLeader('h', '<Plug>(vui-help)')
call s:MapDefault('<CR>', '<Plug>(vui-change-arg-for-line)', 'n')

" Enter to select from completion else normal enter
inoremap <buffer><expr><silent> <CR> pumvisible() ? "\<C-y>\<ESC>"
            \ : "\<CR>"
" Tab for complete if on arg line, tab through completion results, normal tab otherwise
imap <buffer><expr><silent> <TAB> pumvisible()
            \ ? "\<C-n>"
            \ : VUIIsArgLine() ? "<Plug>(vui-complete)" : "\<TAB>"
inoremap <buffer><expr><silent> <S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
