
  // Progressive enhancement: previews and source links remain usable without JavaScript.
  document.querySelectorAll('[data-gallery]').forEach(function (gallery) {
    var controls = gallery.querySelector('.gallery-buttons');
    var buttons = Array.from(controls.querySelectorAll('button'));
    var image = gallery.querySelector('img');
    var caption = gallery.querySelector('[data-caption]');
    var fullsizeLinks = gallery.querySelectorAll('[data-fullsize]');
    var latestRequest = 0;
    controls.hidden = false;
    buttons.forEach(function (button) {
      button.addEventListener('click', function () {
        var request = ++latestRequest;
        var next = new Image();
        caption.textContent = 'Loading ' + button.dataset.title + '…';
        next.onload = function () {
          if (request !== latestRequest) return;
          image.src = button.dataset.src;
          image.alt = button.dataset.alt;
          fullsizeLinks.forEach(function (link) { link.href = button.dataset.src; });
          buttons.forEach(function (item) { item.setAttribute('aria-pressed', String(item === button)); });
          caption.textContent = button.dataset.title;
        };
        next.onerror = function () {
          if (request !== latestRequest) return;
          caption.textContent = 'Preview unavailable. Use the case study or source links to view this report.';
        };
        next.src = button.dataset.src;
      });
    });
  });


// Real source examples remain readable if JavaScript is unavailable.
(function () {
  var controls = document.querySelector('.evidence-controls');
  var buttons = Array.from(controls.querySelectorAll('button'));
  var panels = Array.from(document.querySelectorAll('[data-evidence]'));
  function selectExample(name) {
    panels.forEach(function (panel) { panel.hidden = panel.dataset.evidence !== name; });
    buttons.forEach(function (button) {
      button.setAttribute('aria-pressed', String(button.dataset.example === name));
    });
  }
  controls.hidden = false;
  selectExample('sql');
  buttons.forEach(function (button) {
    button.addEventListener('click', function () { selectExample(button.dataset.example); });
  });
})();
