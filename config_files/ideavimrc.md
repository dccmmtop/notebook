set clipboard+=unnamed
nnoremap <Space>ga :action Annotate<CR>
nnoremap <Space>k :action Back<CR>
nnoremap <Space>gs :action GenerateGetterAndSetter<CR>
nnoremap <Space>rr :action Rerun<CR>
nnoremap <Space>rd :action Debug<CR>
nnoremap <Space>ra :action RenameElement<CR>

nnoremap <Space>gi :action GotoImplementation<CR>
nnoremap <Space>gd :action GotoDeclaration<CR>

nnoremap <Space>f :action ReformatCode<CR>
nnoremap <Space>e :action GotoNextError<CR>
nnoremap <Space>cmd :action ChooseRunConfiguration<CR>
nnoremap <Space>oi :action OptimizeImports<CR>
nnoremap <Space>vs :source ~/_ideavimrc<CR>
nnoremap <Space>vv :e C:\Users\wb07440\_ideavimrc<CR>
nnoremap <Space>wc :action CloseContent<CR>
nnoremap <Space>cr :action CopyPathFromRepositoryRootProvider<CR>


nnoremap ; :

set hlsearch
set incsearch
set smartcase


nnoremap <Space>sc :nohlsearch<CR>

set esaymotion
let g:EasyMotion_override_acejump = 0


set rn
set nu
set so=5
map - $
map 0 ^
