# svelte-layout-resizable

resizable layout component for svelte

## usage

in your `App.svelte` add

```html
<script>
  import L from 'svelte-layout-resizable';
</script>
<L row>
  <L>cell 1 in row</L>
  <L column>
    <L>cell 2.1 in column</L>
    <L>cell 2.2 in column</L>
    <L>cell 2.3 in column</L>
  </L>
  <L>cell 3 in row</L>
</L>
```

result:

![screenshot of svelte-layout-resizable demo](demo/screenshot.webp)

`<L row>` is a broad container with css `flex-direction: row`

`<L column>` is a tall container with css `flex-direction: column`

if you dont like the `<L>` syntax  
you can do `import Layout from 'svelte-layout-resizable';`  
and use `<Layout>cell</Layout>`

## style

the component defines only a minimal style  
to implement containers and resize-handles

most users want to add style to their `App.svelte`, like

```html
<style>
  /* layout */
  :global(body) {
    /* use full window size */
    padding: 0;
  }
  :global(.layout-cell>.middle>.center) {
    /* content cell: add scrollbars when needed */
    overflow: auto;
  }
  :global(.layout-cell>*>.frame) {
    /* frame color and border */
    /*background-color: #f4f4f4;*/
    border: solid 0.5px #a8a8a8;
  }
  :global(.layout-cell>*, .layout-cell>*>.frame) {
    /* frame size
       larger frames are better acccessible (touchscreen) */
    flex-basis: 2.5px !important;
  }
  /* use css classes on cells like
     <L class="overflow-hidden">....</L> */
  :global(.layout-cell>.middle>.center.overflow-hidden) {
    overflow: hidden !important;
  }
  /* use css classes on containers like
     <L row class="custom-row-container">....</L> */
  :global(.layout-row.custom-row-container) {
    color: orange;
  }
</style>
```

## related

* [goldenlayout.js](https://golden-layout.com/) (RIP jQuery)
* [svelte-subdivide](https://github.com/sveltejs/svelte-subdivide) [[v3](https://github.com/saabi/svelte-subdivide/tree/v3)]
* [svelte-grid](https://github.com/vaheqelyan/svelte-grid)
* [other svelte layout components](https://svelte-community.netlify.app/code/?tag=layout+and+structure) in svelte-community

## todo 

* online demo  
  problem: [inliner](https://github.com/remy/inliner) produces empty `<body>`  
  also `save page` in browser dont work

* avoid changing body style?  
  only 'stop selecting text' in layout containers?

* fix resize bug with many cells  
  like a 3x3 layout  
  in the center container

*  fix newStyle.marginLeft and newStyle.marginTop

* allow to hide/deactivate resize handles  
  on the outside of a class="root" container
  (better: find root container automatically)

* allow resize from corner handles?

* imitate goldenlayout.js and [qt dockable widgets](https://doc.qt.io/qt-5/qtwidgets-mainwindows-dockwidgets-example.html)  
  maybe as a separate node package, keep it small

  * allow to drag/move and dock cells to other containers

  * allow to expand one cell over the root layout

* add a tab widget? out of scope?  
  we already have [svelte-tabs](https://github.com/joeattardi/svelte-tabs)

* support 'live resize' of layout  
  con: need more CPU/GPU = debounce to like 10 FPS

* beforeUpdate or onMount  
  calculate sizes of all cells  
  so when we have
  ```
  <L>
    <L s="0.6">1</L>
    <L>2</L>
  </L>
  ```
  then cell 2 should have size 0.4  
  and not what css-flex suggests  
  based on content size  
  or did we use flex wrong?

* check bounds on resize  
  eventually shrink more cells

* verify overflow on resize  
  avoid unnecessary scrollbars

## changelog

will be removed for git

```
2020-08-25 = day 1

  resize is working with some bugs
  using manually inserted resize handles
  like <L t="r"/>

2020-08-26 = day 2

  remove manual resize handles
  use "frame" (padding elements)
  for every content box .layout-cell

  project name: svelte-layout-interactive
  shorter than: svelte-layout-resizable-draggable-dockable
  or: svelte-flex-interactive
  or: svelte-layout-resizable

2020-08-27 = day 3

  fixed resize bug
  setting size of one flex cell
  will change size of all other cells
  so we must copy all sizes
  before setting new sizes

  small problem:
  when text is selected before (across multiple cells)
  then dragging dont work on the resize handles
  instead the text is dragged

  bigger problem:
  sizes are wrong?
  set size only on one cell, like
  <L row>
    <L size="0.1">1</L>
    <L>2</L>
    <L>3</L>
  </L>
  expectation: 10 + 45 + 45 = 100
  reality: ?

  how to inherit props to child components?
  <slot {prop_name} />
  is not (always) working?
    allow to overwrite slot props
    im writing a recursive layout component
    and i need to overwrite slot props, like

  solution:
  remove head and body from layout cell
  use attributes 'style' and 'class'
  for cascading styles
  avoid setting any 'default style'
  even 'overflow: auto' cos thats a special case
  only set required styles for containers and handles

  css 'overflow: visible' is not supported?
  layout is always 100% size of container
```

## license

[license](LICENSE) is creative commons zero 1.0
