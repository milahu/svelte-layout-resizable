<svelte:body
  on:mouseup={handleMoveEnd}
  on:mouseleave={handleMoveEnd}
  on:touchend={handleMoveEnd}
/>

<!--
  class:moving={isMoving} - set on body
-->

{#if column || row}

  <!-- layout container -->
  <!-- TODO verify class concat -->
  <div
    class:layout-column={column}
    class:layout-row={row}
    class:layout-reverse={reverse}

    style={styleStr + style}
    {...$$restProps}
  >

    <slot/>

  </div>

{:else}

  <!-- layout cell -->
  <div
    class="layout-cell"
    style={styleStr}
  >
    <div class="top">
      <div class="frame left" on:mousedown={handleMoveStart} />
      <div class="frame center" on:mousedown={handleMoveStart} />
      <div class="frame right" on:mousedown={handleMoveStart} />
    </div>

    <div class="middle">
      <div class="frame left" on:mousedown={handleMoveStart} />

      <div class:center={true} {style} {...$$restProps}>
        <slot/>
      </div>

      <div class="frame right" on:mousedown={handleMoveStart} />
    </div>

    <div class="bottom">
      <div class="frame left" on:mousedown={handleMoveStart} />
      <div class="frame center" on:mousedown={handleMoveStart} />
      <div class="frame right" on:mousedown={handleMoveStart} />
    </div>
  </div>

{/if}

<script>

  import {onMount,beforeUpdate} from 'svelte';

  /*
  onMount(() => {
    console.dir(`column = `, column, `row = `, row);
  })
  */



  // props ....

  export let row = false; // row container = left to right
  export let column = false; // column container = top to bottom
  export let reverse = false; // reverse order of items

  export let size = false; // size = css: flex-basis
  export let style = ''; // css style

  export let overflow = 'auto';



  function isNum(str){
    // only test last digit to include floats
    // 10%, 10px are no numbers
    const c = String(str).slice(-1);
    return String(parseInt(c, 10)) == c;
  }

  $: styleStr = [

    'width:100%;height:100%;',

    (size
      ? `flex-basis:${(
        isNum(size)
          ? (size*100)+'%' // size is float, 0.1 --> 10%
          : size
      )};`
      : ''
    ),
    // TODO set other cell sizes in onMount() or beforeUpdate()

    'overflow:auto;',

  ].join('');



  let show_frame = true; // TODO implement?

  // TODO cleanup
  let activeMoveEvent = null;
  let activeMoveElement = null;
  let activeMoveListener = null;
  let activeResizeElement = null;
  let activeMoveParent = null;
  let activeMoveParentOverflow = '';
  let isMoving = false;
  let moveStartX = 0;
  let moveStartY = 0;
  let activeMoveOrigin = null; // TODO rename to activeMoveHandle
  let parentIsLayoutVertical = null;
  let activeMoveCell = null;
  let activeMoveCell_real = null; // TODO rename
  let activeMoveSizeKey = '';



  function handleMoveStart(event) {

    const tar = event.target;

    moveStartX = event.clientX;
    moveStartY = event.clientY;

    activeMoveOrigin = tar;
    activeMoveCell = tar.parentNode.parentNode;

    const hcl = activeMoveOrigin.classList;
    const hpcl = activeMoveOrigin.parentNode.classList;
    console.log('hcl =', hcl);

    activeMoveCell_real = activeMoveCell;
    activeMoveParent = activeMoveCell.parentNode;

    // what handle was moved?
    const handleRight = hcl.contains('right');
    const handleLeft = hcl.contains('left');
    const handleTop = hpcl.contains('top');
    const handleBottom = hpcl.contains('bottom');

    const activeMoveParentClass = (
      handleLeft || handleRight
    ) ? 'layout-row' : 'layout-column';

    const sizeKeyPrefix = 'offset'; // all the same?
    activeMoveSizeKey = (activeMoveParentClass == 'layout-column')
      ? sizeKeyPrefix+'Height'
      : sizeKeyPrefix+'Width';

    // find parent container
    while (
      activeMoveParent &&
      activeMoveCell_real &&
      !activeMoveParent.classList.contains(activeMoveParentClass)
    ) {
      activeMoveCell_real = activeMoveCell_real.parentElement;
      activeMoveParent = activeMoveParent.parentElement;
    }
    if (!activeMoveParent) {
      console.log('error. activeMoveParent not found');
      return;
    }
    if (!activeMoveCell_real) {
      console.log('error. activeMoveCell_real not found');
      return;
    }
    console.log('found activeMoveParent', activeMoveParent.className);
    console.log('found activeMoveCell_real', activeMoveCell_real.className);

    // stop selecting text
    // use hidden css class to save other components
    document.body.classList.add('--layout-is-moving');

    activeMoveEvent = (event.type[0] == 'm')
      ? 'mousemove' : 'touchmove';

    activeMoveElement = tar.cloneNode(true);

    const newStyle = activeMoveElement.style;

    newStyle.position = 'absolute';
    newStyle.zIndex = 10; // force to front layer

    document.body.appendChild(activeMoveElement);

    activeMoveParentOverflow = activeMoveParent.style.overflow;
    activeMoveParent.style.overflow = 'hidden';
    // TODO verify. is this a good idea?
    // we want to avoid scrollbars on resize

    const handle_size = 1;


    if (activeMoveParentClass == 'layout-column') {
      // parent is layout-column
      // handleTop || handleBottom
      parentIsLayoutVertical = true;

      console.log('add marginTop', (handleTop ? tar.offsetHeight : 0));

      newStyle.marginTop = (
        tar.offsetTop
        - (handleTop ? tar.offsetHeight : 0)
        + handle_size/2
        - event.clientY
      ) + 'px';

      newStyle.left = activeMoveParent.offsetLeft + 'px';

      newStyle.top = event.clientY + 'px';
      // will change in move handler

      newStyle.height = tar.offsetHeight + 'px';
      newStyle.width = activeMoveParent.offsetWidth + 'px';
      activeMoveElement.className = 'layout-column-resizer';

      activeMoveListener = function(event){
        // optimized hot code
        newStyle.top = event.clientY + 'px';
      };

    } else {
      // parent is layout-row
      // handleLeft || handleRight
      parentIsLayoutVertical = false;
      activeMoveElement.className = 'layout-row-resizer';

      console.log('add marginLeft', (handleLeft ? tar.offsetWidth : 0));

      newStyle.marginLeft = (
        tar.offsetLeft
        - (handleLeft ? tar.offsetWidth : 0)
        + handle_size/2
        - event.clientX
      ) + 'px';

      newStyle.top = activeMoveParent.offsetTop + 'px';

      newStyle.left = event.clientX + 'px';
      // will change in move handler

      newStyle.height = activeMoveParent.offsetHeight + 'px';
      newStyle.width = tar.offsetWidth + 'px';

      activeMoveListener = function(event){
        // optimized hot code
        newStyle.left = event.clientX + 'px';
      };
    }
    document.addEventListener(activeMoveEvent, activeMoveListener);
  }



  function debugParent(parent, keyList) {
    return Array.from(parent.children)
    .map((element)=>{
      let res = element;
      for (let k of keyList) {
        res = res[k];
      }
      return parseInt(res, 10)
    })
    .reduce((acc, val, idx, arr) => {
      acc += ' '+val;
      if (idx == arr.length - 1) {
        acc += ' = '+arr.reduce((acc,val)=> (acc+val), 0);
      }
      return acc;
    }, '');
  }



  function handleMoveEnd(event) {

    if (!activeMoveListener) return;

    document.body.classList.remove('--layout-is-moving');

    const moveDiffX = event.clientX - moveStartX;
    const moveDiffY = event.clientY - moveStartY;

    const moveDiff = parentIsLayoutVertical
      ? moveDiffY : moveDiffX;

    document.body.removeChild(activeMoveElement);
    activeMoveElement = null;

    activeMoveParent.style.overflow = activeMoveParentOverflow;

    document.removeEventListener(
      activeMoveEvent, activeMoveListener);

    activeMoveListener = null;

    if (event.type == 'mouseleave') { // TODO touchleave?
      // keep layout
      return;
    }



    const hcl = activeMoveOrigin.classList;
    const hpcl = activeMoveOrigin.parentNode.classList;



    const containerSize = activeMoveParent[activeMoveSizeKey];
    const containerChildren = Array.from(activeMoveParent.children);
    const firstChild = containerChildren[0];
    const lastChild = containerChildren.slice(-1)[0];



    // save old sizes
    // when one cell size is changed
    // then all other cells change too (css flex)

    let node_size_new = containerChildren
      .map((node) => node[activeMoveSizeKey]);

    let size_sum = node_size_new
      .reduce((acc, val) => (acc + val), 0);

    let moveCellIndex = containerChildren
      .indexOf(activeMoveCell_real);

    // what handle was moved?
    const handleRight = hcl.contains('right');
    const handleLeft = hcl.contains('left');
    const handleTop = hpcl.contains('top');
    const handleBottom = hpcl.contains('bottom');

    let node_before = null;
    let node_after = null;

    if (
      (
        activeMoveCell_real == firstChild &&
        (handleLeft || handleTop)
      ) ||
      (
        activeMoveCell_real == lastChild &&
        (handleRight || handleBottom)
      )
    ) {

      console.log('TODO resize from container start/end');
      size_sum += moveDiff;

      // TODO fix resize

    } else {

      // handle is in middle of container

      // get cells before and after handle
      let index_before = 0;
      let index_after = 0;
      if (handleLeft || handleTop) {
        index_before = moveCellIndex - 1;
        index_after = moveCellIndex;
      }
      else {
        index_before = moveCellIndex;
        index_after = moveCellIndex + 1;
      }

      // change cell size
      node_size_new[index_before] += moveDiff;
      node_size_new[index_after] -= moveDiff;

      // set cell size
      for (let [index, node] of containerChildren.entries()) {
        node.style.flexBasis = Math.round(
          node_size_new[index] / size_sum * 100)+'%';
      }

    }

    return;

    console.log(
      'size old:',
      debugParent(activeMoveParent, [activeMoveSizeKey]),
      '=',
      debugParent(activeMoveParent, ['style', 'flexBasis'])
    );

  }

</script>

<style lang="scss">

  $cell_frame: 4px;
  $handleSize: 1px; // visible size
  $handlePadding: 4px; // clickable size
  $handleMargin: -4px;
  $handleColor: gray;
  $svelteOrange: #ff3e00;
  $headColor: $svelteOrange;



  // resize handles

  :global(.layout-column-resizer) {
    background-color: $handleColor;
    flex-basis: $handleSize;
    flex-shrink: 0;
    flex-grow: 0;
    //height: 50px !important; // TODO dont set style in attribute
    //width: 100%;
    cursor: row-resize;
    margin: 0;
    background-clip: content-box; // transparent padding
    padding-top: $handlePadding;
    margin-top: $handleMargin;

    //outline: solid 1px green;
  }

  :global(.layout-row-resizer) {
    background-color: $handleColor;
    flex-basis: $handleSize;
    flex-shrink: 0;
    flex-grow: 0;
    //width: $handleSize; // TODO dont set style in attribute
    //height: 100%;
    cursor: col-resize;
    margin: 0;
    background-clip: content-box; // transparent padding
    padding-left: $handlePadding;
    margin-left: $handleMargin;

    //outline: solid 1px yellow;

  }



  // moving handles
  :global(.layout-column-resizer) {
    height: $handleSize !important;
    //width: 99%; // avoid overflow
  }

  :global(.layout-row-resizer) {
    width: $handleSize !important;
    //height: 99%; // avoid overflow
  }



  .layout-cell > .middle > .center > .head {
    border-bottom: solid 1px gray;
    height: 1.36em; // default height in firefox
    //font-size: 75%;
    color: $headColor;
  }



  :global(body.--layout-is-moving, body.--layout-is-moving *) {
    // dont select text on resize/drag
    user-select: none !important;
  }



  // shortcuts for flex layout
  .layout-column {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    align-content: stretch;
  }
  .layout-column.layout-reverse {
    flex-direction: column-reverse;
  }

  .layout-row {
    display: flex;
    flex-direction: row;
    align-items: stretch;
    align-content: stretch;
  }
  .layout-row.layout-reverse {
    flex-direction: row-reverse;
  }

  .layout-cell {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    align-content: stretch;
  }



  // frame
  .top, .bottom {
    flex-basis: $cell_frame;
    flex-shrink: 0;
    cursor: row-resize;
  }
  .left, .right {
    flex-basis: $cell_frame;
    flex-shrink: 0;
    cursor: col-resize;
  }

  // debug
  /*
  .left { background-color: yellow }
  .top > .left { background-color: lime }
  .top { background-color: green }
  .top > .right { background-color: turquoise }
  .right { background-color: blue }
  .bottom > .right { background-color: purple }
  .bottom { background-color: red }
  .bottom > .left { background-color: orange }
  */

  .top > .left { cursor: nw-resize }
  .top > .right { cursor: ne-resize }
  .bottom > .right { cursor: se-resize }
  .bottom > .left { cursor: sw-resize }

  .center, .middle { flex-grow: 1; }

  .top, .middle, .bottom {
    display: flex;
    align-items: stretch;
    align-content: stretch;
    flex-direction: row;
  }

  .layout-cell > .middle > .center {
    width: 100%;
    height: 100%;
    //overflow: auto; // auto scroll (default)
  }

  .layout-cell > .middle {
    overflow: auto; // keep layout size 100% (why overflow?)
  }

  .layout-cell > * > .frame {
    // border is inside
    box-sizing: border-box;
  }

  .layout-cell > .middle > .left {
    border-top: none;
    border-right: none;
    border-bottom: none;
  }
  .layout-cell > .middle > .right {
    border-top: none;
    border-left: none;
    border-bottom: none;
  }
  .layout-cell > .top > .center {
    border-bottom: none;
    border-left: none;
    border-right: none;
  }
  .layout-cell > .bottom > .center {
    border-top: none;
    border-left: none;
    border-right: none;
  }

  .layout-cell > .bottom > .left {
    border-top: none;
    border-right: none;
  }
  .layout-cell > .bottom > .right {
    border-top: none;
    border-left: none;
  }
  .layout-cell > .top > .left {
    border-bottom: none;
    border-right: none;
  }
  .layout-cell > .top > .right {
    border-bottom: none;
    border-left: none;
  }

</style>
