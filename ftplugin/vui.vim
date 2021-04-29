setlocal completefunc=ArgValueCompletion
setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand :call VUIOutputCommand()
command -buffer VUIExecuteCommand :call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput :call VUIExecuteCommandAndReadOuput()
