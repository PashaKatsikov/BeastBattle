const String kWireName = 'BbWire';

String fieldHoldScript() => r'''
(function(){
  if (window.__bbHold) return;
  window.__bbHold = 1;
  function field(node){
    if (!node) return false;
    var tag = (node.tagName || '').toUpperCase();
    return tag === 'INPUT' || tag === 'TEXTAREA' || node.isContentEditable === true;
  }
  function nudge(){
    var node = document.activeElement;
    if (!field(node) || !node.scrollIntoView) return;
    var view = window.visualViewport;
    if (!view){
      node.scrollIntoView({block:'nearest', inline:'nearest'});
      return;
    }
    var box = node.getBoundingClientRect();
    var floor = view.offsetTop + view.height - 28;
    if (box.bottom > floor || box.top < view.offsetTop + 8){
      node.scrollIntoView({block:'nearest', inline:'nearest'});
    }
  }
  document.addEventListener('focusin', function(ev){
    if (field(ev.target)) window.setTimeout(nudge, 280);
  }, true);
  if (window.visualViewport){
    var last = window.visualViewport.height;
    window.visualViewport.addEventListener('resize', function(){
      var next = window.visualViewport.height;
      if (next < last - 40) window.setTimeout(nudge, 160);
      last = next;
    });
  }
})();
''';

String rimScript() => r'''
(function(){
  if (window.__bbRim) return;
  window.__bbRim = 1;
  var styleId = 'bb-rim-sheet';
  var sheet = ':root{'+
    '--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;'+
    '--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;'+
    '--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;'+
    '--safe-top:0px!important;--safe-bottom:0px!important;'+
    '--safe-left:0px!important;--safe-right:0px!important;'+
    '}'+
    '.gameview-mobile-header,.app-header,.js-safe-top{padding-top:0!important;margin-top:0!important;}';
  function keyboardUp(){
    var view = window.visualViewport;
    if (!view) return false;
    return view.height < window.innerHeight * 0.78;
  }
  function paint(){
    if (keyboardUp()) return;
    var head = document.head || document.documentElement;
    if (!head) return;
    var meta = document.querySelector('meta[name="viewport"]');
    if (meta){
      var raw = meta.getAttribute('content') || '';
      if (!/viewport-fit\s*=\s*contain/i.test(raw)){
        var trimmed = raw.replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
        meta.setAttribute('content', trimmed + (trimmed ? ', ' : '') + 'viewport-fit=contain');
      }
    }
    var node = document.getElementById(styleId);
    if (!node){
      node = document.createElement('style');
      node.id = styleId;
      head.appendChild(node);
    }
    if (node.textContent !== sheet) node.textContent = sheet;
  }
  paint();
  ['pushState','replaceState'].forEach(function(name){
    var orig = history[name];
    history[name] = function(){
      var result = orig.apply(this, arguments);
      window.setTimeout(paint, 120);
      window.setTimeout(paint, 520);
      return result;
    };
  });
  window.addEventListener('popstate', function(){ window.setTimeout(paint, 120); });
  window.setInterval(paint, 3100);
})();
''';

String wireScript() => r'''
(function(){
  if (window.__bbWire) return;
  window.__bbWire = 1;
  function send(text){ try { BbWire.postMessage(text); } catch (err) {} }
  var purse = /(пополн|депозит|касс|оплат|внести|вывод|платеж|checkout|cashier|deposit|top.?up|add funds|replenish|payment|pay now|withdraw)/i;
  var join = /(регистрац|зарегистр|create.?account|sign.?up|regist)/i;
  var enter = /(войти|вход|авториз|log.?on|log.?in|sign.?in)/i;
  var last = '';
  function report(){
    var path = location.pathname + location.search;
    if (path !== last){ last = path; send('hop:' + path); }
  }
  report();
  ['pushState','replaceState'].forEach(function(name){
    var orig = history[name];
    history[name] = function(){
      var result = orig.apply(this, arguments);
      window.setTimeout(report, 90);
      return result;
    };
  });
  window.addEventListener('popstate', function(){ window.setTimeout(report, 90); });
  document.addEventListener('click', function(ev){
    try {
      var node = ev.target;
      for (var step = 0; step < 5 && node; step++){
        var label = ((node.innerText || node.value || (node.getAttribute && node.getAttribute('aria-label')) || '') + '').trim();
        if (label){
          if (purse.test(label)){ send('purse:' + label.slice(0, 48)); return; }
          if (join.test(label)){ send('join_tap:' + label.slice(0, 48)); return; }
          if (enter.test(label)){ send('enter_tap:' + label.slice(0, 48)); return; }
        }
        node = node.parentElement;
      }
    } catch (err) {}
  }, true);
  document.addEventListener('submit', function(ev){
    try {
      var form = ev.target;
      var passwords = form.querySelectorAll ? form.querySelectorAll('input[type="password"]') : [];
      var blob = ((form.innerText || '') + ' ' + (form.getAttribute('action') || '') + ' ' + (form.className || ''));
      var confirm = form.querySelector && (form.querySelector('input[name*="confirm" i]') || form.querySelector('input[name*="repeat" i]'));
      if (passwords && passwords.length >= 2){ send('auth_post:join'); return; }
      if (passwords && passwords.length === 1){
        send('auth_post:' + ((confirm || join.test(blob)) ? 'join' : 'enter'));
        return;
      }
      if (join.test(blob)){ send('auth_post:join'); return; }
      if (enter.test(blob)){ send('auth_post:enter'); return; }
      send('form_post');
    } catch (err) { send('form_post'); }
  }, true);
})();
''';
