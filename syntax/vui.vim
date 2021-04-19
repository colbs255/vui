syntax keyword enabled_keyword _enabled_
syntax keyword disabled_keyword _disabled_
syntax match argName /^:\w\+:/
syntax match title /^=\w\+=/

hi def link title Keywork
hi def link enabled_keyword Boolean
hi def link disabled_keyword Boolean
hi def link argName Type
