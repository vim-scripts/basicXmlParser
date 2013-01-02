" Documentation {{{1
"
" Name: basicXmlParser.vim
" Version: 1.0
" Description: Plugin create object trees and get them or save them as xml, and to create object trees from a xml files. May be used as an object tree, the xml is the file format for load and save the object tree from and to a file. Serialization to xml is optional, the user is not required to load or to save to xml, the tree may be builded manually or programmatically. This plugin was created as a utility plugin to load and save configuration files. See the usage section on how to use the plugin.
" Author: Alexandre Viau (alexandreviau@gmail.com)
" Installation: Copy the plugin to the vim plugin directory.
"
" Usage: {{{2

" The following examples create, save to file and load from file the following xml tree: {{{3
"
" <root>
"    <Marks>
"       <A>
"          C:\Usb\i_green\apps
"          <myLevel3>
"             myLevel3Value
"             <myLevel4>
"                myLevel4Value
"             </myLevel4>
"          </myLevel3>
"       </A>
"       <B>
"          C:\Users\User\Desktop\
"       </B>
"       <C>
"          C:\
"       </C>
"    </Marks>
"    <LastPath>
"       d:\
"    </LastPath>
" </root>
"
"
" Create object trees and get them or save them as xml {{{3
"
" Root level
" let myRoot = g:Item.New()

" First level
" cal myRoot.Add(g:Item.New2('LastPath', 'd:\'))
" echo myRoot.LastPath.Value

" cal myRoot.Add(g:Item.New1('Marks'))
" echo myRoot.Marks.Value

" Second level
" cal myRoot.Marks.Add(g:Item.New2('A', 'C:\Usb\i_green\apps'))
" cal myRoot.Marks.Add(g:Item.New2('B', 'C:\Users\User\Desktop'))
" cal myRoot.Marks.Add(g:Item.New2('C', 'C:\'))
" echo myRoot.Marks.A.Value
" echo myRoot.Marks.B.Value
" echo myRoot.Marks.C.Value
" Show how many items there is in the second level
" echo myRoot.Marks.Count()

" Third level
" cal myRoot.Marks.A.Add(g:Item.New2('myLevel3', 'myLevel3Value'))
" echo myRoot.Marks.A.myLevel3.Value
" Show how many items there is in the third level
" echo myRoot.Marks.A.Count()

" Fourth level
" cal myRoot.Marks.A.myLevel3.Add(g:Item.New2('myLevel4', 'myLevel4Value'))
" echo myRoot.Marks.A.myLevel3.myLevel4.Value

" To get the xml as a list
" let myXmlList = myRoot.ToXmlList()
" echo myXmlList

" To save the xml to a file
" cal myRoot.SaveToXml('c:/temp/cfg.xml')

" Example to copy from third level to a new root
" let myRoot2 = myRoot.Marks.A.myLevel3
" Display value from new root, now what was 4th level is now first level
" echo myRoot2.myLevel4.Value

" Create object trees from a xml files {{{3
 
" Load the file created in the previous example
" let rootItem2 = g:Item.LoadFile('c:/temp/cfg.xml')
 
" Show some elements from the loaded xml file
" echo rootItem2.LastPath.Value
" echo rootItem2.Marks.A.Value
" echo rootItem2.Marks.B.Value
" echo rootItem2.Marks.A.myLevel3.Value
" echo rootItem2.Marks.A.myLevel3.myLevel4.Value
" echo rootItem2.Marks.C.Value
" echo rootItem2.Marks.Value
" 
" Create object trees from expressions {{{3
" 
" There is another way of creating the object trees using expressions, the "g:RootItem.LoadFile()" function is an example how to do this. By expressions, I mean that something like exe 'cal items.Items' . level . '.Add(g:Item.New("' . tag . '", ""))' may be used where the "level" variable would contain a string of the path to the items like for example "myItem1.Items.myItem2.Items".
" Todo: {{{2
" 1. Automatically put every tag and values each on his own line (it should be like this to be parsed correctly)
" 2. Get multiline values inside tags
"
" History: {{{2
"
" 1.0 Initial release
"
" Class Item {{{1

" Define the class as a dictionnary
let g:Item = {}

" Variables {{{2
let s:Level = 0

" Constructors {{{2

" g:Item.New() {{{3
" Constructor for root item
function! g:Item.New() dict
    " Reset the item depth level when the root item is created
    let s:Level = 0
    return g:Item.New2('root', '')
endfunction

" g:Item.New1(name) {{{3
function! g:Item.New1(name) dict
    return g:Item.New2(a:name, '')
endfunction

" g:Item.New2(name, value) {{{3
function! g:Item.New2(name, value) dict
    " Member variables
    let self.name = a:name 
    let self.Value = a:value
    let self.level = 0
    " Create the new object
    return deepcopy(self)
endfunction

" Properties {{{2

" g:Item.GetName() {{{3
function! g:Item.GetName() dict
    return self.name
endfunction

" g:Item.GetLevel() {{{3
function! g:Item.GetLevel() dict
    return self.level
endfunction

" g:Item.Count() {{{3
function! g:Item.Count() dict
    let nbItems = 0
    " Count the number items already
    for key in keys(self)
        " If the type is a dictionary
        if type(self[key]) == type({})
            let nbItems += 1 
        endif
    endfor
    return nbItems
endfunction

" Methods {{{2

" g:Item.Add(item) {{{3
" Add a new item
function! g:Item.Add(item) dict
    " If this is the first item added, it means it is a new level, so increase the level number.
    if self.Count() == 0
        let s:Level = s:Level + 1
    endif
    " Set the item's level
    let a:item.level = s:Level
    " Add the item
    exe "call extend(self, {'".a:item.name."':a:item}, 'force')"
endfunction

" g:Item.ToXmlListR(item, xmlList) {{{3
" Recusive function to go through all items levels
function! g:Item.ToXmlListR(item, xmlList)
    for key in keys(a:item)
        " If the type is a dictionary
        if type(a:item[key]) == type({})
            " Get the tabs for indentation
            let tabs = ''
            for i in range(1, a:item[key].GetLevel())
               let tabs .= '   '    
            endfor
            cal add(a:xmlList, tabs . '<' . a:item[key].GetName() . '>')
            if a:item[key].Value != ''
                cal add(a:xmlList, tabs . '   ' . a:item[key].Value)
            endif
            " Recursive call
            cal g:Item.ToXmlListR(a:item[key], a:xmlList)
            cal add(a:xmlList, tabs . '</' . a:item[key].GetName() . '>')
        endif
    endfor
endfunction

" g:Item.ToXmlList() {{{3
" To return the items as a list containing xml data
function! g:Item.ToXmlList() dict
    let xmlList = []
    cal add(xmlList, '<' . self.name . '>')
    cal self.ToXmlListR(self, xmlList)
    cal add(xmlList, '</' . self.name . '>')
    return xmlList
endfunction


" g:Item.SaveToXml(file) {{{3
function! g:Item.SaveToXml(file) dict
    cal writefile(self.ToXmlList(), a:file)
endfunction

" g:Item.LoadFile(file) {{{3
" Load items from xml file
function! g:Item.LoadFile(file) dict
    " Check if the file exists {{{4
    if !filereadable(a:file)
        return {}
    endif

    " Load the xml file {{{4
    let xmlList = readfile(a:file)

    " Each new tag encountered is added to this list as a level deeper into the tree {{{4
    let levelTags = []

    " Remove root "Items" in the xml file {{{4
    cal remove(xmlList, len(xmlList) - 1)
    cal remove(xmlList, 0)

    " Put every tag and values each on his own line in the "xmlList" list {{{4
    " Here to put code to automatically put every tag and values each on his own line (it should be like this to be parsed correctly)

    " Create the root item {{{4
    let myRoot = g:Item.New()

    " Parse the xml tree {{{4
    " Go throught all the tags and values contained in the xml tree, each tag and values are on their own line in the "xmlList" list
    for line in xmlList
        " Remove indentation {{{5
        let line = substitute(line, "^\\s\\+", '', '')
        " End tag {{{5
        let tagType = strpart(line, 0, 2)
        if tagType == '</'
             " Get text inside de tag {{{6
             let tag = strpart(line, 2, len(line) - 3)
             " Remove a level {{{6
             " Loop the items backwards, the last tag name corresponding to this name is remove
             for i in range(len(levelTags) - 1, 0, -1)
                 if levelTags[i] == '.' . tag
                     cal remove(levelTags, i)
                     break
                 endif
             endfor
        else
             " Start tag {{{5
             let tagType = strpart(line, 0, 1)
             if tagType == '<'
                 " Get text inside de tag {{{6
                 let tag = strpart(line, 1, len(line) - 2)
                 " Add the tag as an item {{{6
                 let level = join(levelTags, '')
                 exe 'cal myRoot' . level . '.Add(g:Item.New1("' . tag . '"))'
                 " Add a level {{{6 
                 cal add(levelTags, '.' . tag)
             " Data {{{5
             else
                " Set the value of the last item (tag) added {{{6
                exe "let myRoot" . level . "." . tag . ".Value = '" . line . "'"
             endif
         endif
    endfor
    " Return the root object {{{4
    return myRoot
endfu

