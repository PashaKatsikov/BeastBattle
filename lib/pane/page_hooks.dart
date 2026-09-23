String fieldHoldScript() => r'''
(function(){
  if (window.__bbSeat) { return; }
  window.__bbSeat = 1;

  var occupancy = 0;
  var frame = 0;
  var gen = 0;
  var held = { field: null, host: null, bottom: 0, shift: -1 };
  var CEIL = 0.91;
  var GAP = 6;
  var GLIDE = 'transform 0.2s cubic-bezier(0.22, 0.61, 0.36, 1)';

  function margin(){
    var raw = Math.round(window.innerHeight * 0.018);
    if (raw < 8) { return 8; }
    return raw > 21 ? 21 : raw;
  }
  function collapsed(){
    var vv = window.visualViewport;
    if (!vv || !(vv.height > 0)) { return false; }
    return (window.innerHeight - vv.height) > 1;
  }
  function editable(){
    var node = document.activeElement;
    if (!node || !node.tagName) { return null; }
    if (node.isContentEditable === true) { return node; }
    var tag = ('' + node.tagName).toUpperCase();
    if (tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'INPUT') { return node; }
    return null;
  }
  function pinned(node){
    for (var cur = node ? node.parentElement : null; cur && cur !== document.body; cur = cur.parentElement){
      if (window.getComputedStyle(cur).position === 'fixed') { return cur; }
    }
    return null;
  }
  function keyboardTop(){
    if (occupancy > 0){
      var used = occupancy > CEIL ? CEIL : occupancy;
      return window.innerHeight * (1 - used);
    }
    if (collapsed()){
      var vv = window.visualViewport;
      return vv.offsetTop + vv.height;
    }
    return window.innerHeight;
  }
  function origins(el){
    if (typeof el.__bbTx0 !== 'string') { el.__bbTx0 = el.style.transform || ''; }
    if (typeof el.__bbTr0 !== 'string') { el.__bbTr0 = el.style.transition || ''; }
  }
  function letGo(instant){
    var host = held.host;
    held = { field: null, host: null, bottom: 0, shift: -1 };
    if (!host) { return; }
    var tx0 = (typeof host.__bbTx0 === 'string') ? host.__bbTx0 : '';
    var tr0 = (typeof host.__bbTr0 === 'string') ? host.__bbTr0 : '';
    host.style.transform = tx0;
    if (instant){
      host.style.transition = tr0;
      return;
    }
    var mark = ++gen;
    window.setTimeout(function(){
      if (mark === gen && held.host !== host) { host.style.transition = tr0; }
    }, 260);
  }
  function grab(field, host){
    var sameHost = (host === held.host);
    // How much this host is already lifted right now (0 for a fresh host).
    var applied = (sameHost && held.shift > 0) ? held.shift : 0;
    // Release a different previously-held host, gliding it back down.
    if (!sameHost) { letGo(false); }
    origins(host);
    gen++;
    // Natural (unlifted) bottom = current rect plus whatever lift is applied.
    var natural = field.getBoundingClientRect().bottom + applied;
    held = { field: field, host: host, bottom: natural, shift: sameHost ? applied : -1 };
    host.style.transition = host.__bbTr0 ? (host.__bbTr0 + ', ' + GLIDE) : GLIDE;
  }
  function place(dy){
    if (dy === held.shift) { return; }
    held.shift = dy;
    var tx0 = (typeof held.host.__bbTx0 === 'string') ? held.host.__bbTx0 : '';
    var move = 'translate3d(0px,' + (-dy) + 'px,0px)';
    held.host.style.transform = tx0 ? (tx0 + ' ' + move) : move;
  }
  function reconcile(){
    var el = editable();
    if (!el || occupancy <= 0) { letGo(false); return; }
    var host = pinned(el);
    if (!host){
      if (held.host) { letGo(true); }
      var overlap = el.getBoundingClientRect().bottom + margin() - keyboardTop();
      if (overlap > GAP) { window.scrollBy(0, overlap); }
      return;
    }
    if (held.field !== el || held.host !== host){
      grab(el, host);
    }
    var need = held.bottom + margin() - keyboardTop();
    place(need > GAP ? need : 0);
  }
  function schedule(){
    if (frame) { return; }
    frame = window.requestAnimationFrame(function(){
      frame = 0;
      reconcile();
    });
  }

  window.__bbShare = function(value){
    occupancy = value > 0 ? value : 0;
    if (occupancy <= 0){
      if (frame) { window.cancelAnimationFrame(frame); frame = 0; }
      letGo(false);
      return;
    }
    schedule();
  };

  document.addEventListener('focusin', schedule, true);
  if (window.visualViewport){
    window.visualViewport.addEventListener('resize', schedule);
    window.visualViewport.addEventListener('scroll', schedule);
  }
})();
''';

String rimScript() => r'''
(function(){
  if (window.__bbRim) { return; }
  window.__bbRim = 1;

  var TAG = 'bb-rim-sheet';
  var RULES = [
    'html,body{-webkit-text-size-adjust:100%!important;text-size-adjust:100%!important;}',
    ':root{',
    '--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;',
    '--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;',
    '--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;',
    '--safe-top:0px!important;--safe-bottom:0px!important;',
    '--safe-left:0px!important;--safe-right:0px!important;',
    '}',
    '.gameview-mobile-header,.app-header,.js-safe-top{padding-top:0!important;margin-top:0!important;}'
  ].join('');

  function typing(){
    var vv = window.visualViewport;
    return vv ? (vv.height < window.innerHeight * 0.78) : false;
  }
  function patchMeta(){
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) { return; }
    var content = meta.getAttribute('content') || '';
    if (/viewport-fit\s*=\s*contain/i.test(content)) { return; }
    var trimmed = content.replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
    meta.setAttribute('content', trimmed ? (trimmed + ', viewport-fit=contain') : 'viewport-fit=contain');
  }
  function pinSheet(){
    var host = document.head || document.documentElement;
    if (!host) { return; }
    var node = document.getElementById(TAG);
    if (!node){
      node = document.createElement('style');
      node.id = TAG;
      host.appendChild(node);
    }
    if (node.textContent !== RULES) { node.textContent = RULES; }
  }
  function apply(){
    if (typing()) { return; }
    patchMeta();
    pinSheet();
  }
  function applyLater(){
    window.setTimeout(apply, 120);
    window.setTimeout(apply, 520);
  }

  apply();

  var story = window.history;
  ['pushState', 'replaceState'].forEach(function(name){
    var original = story[name];
    if (typeof original !== 'function') { return; }
    story[name] = function(){
      var out = original.apply(this, arguments);
      applyLater();
      return out;
    };
  });
  window.addEventListener('popstate', function(){ window.setTimeout(apply, 120); });
  window.setInterval(apply, 3100);
})();
''';
