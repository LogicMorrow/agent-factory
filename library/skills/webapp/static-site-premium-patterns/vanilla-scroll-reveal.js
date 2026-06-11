/* vanilla-scroll-reveal.js — mikrointerakcje bez bibliotek.
   Podłącz: <script src="vanilla-scroll-reveal.js" defer></script>
   Wymaga klas z design-tokens-example.css (.reveal, header.nav, dialog.video-modal). */

(function  {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* 1) Scroll-reveal — elementy .reveal wpływają w viewport */
  function initReveal {
    const els = document.querySelectorAll('.reveal');
    if (reduceMotion || !('IntersectionObserver' in window)) {
      els.forEach(el => el.classList.add('is-visible'));
      return;
    }
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('is-visible');
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -10% 0px' });
    els.forEach(el => io.observe(el));
  }

  /* 2) Sticky-nav backdrop-blur po przewinięciu */
  function initNavBlur {
    const nav = document.querySelector('header.nav');
    if (!nav) return;
    let ticking = false;
    function update {
      nav.classList.toggle('scrolled', window.scrollY > 8);
      ticking = false;
    }
    window.addEventListener('scroll',  => {
      if (!ticking) { window.requestAnimationFrame(update); ticking = true; }
    }, { passive: true });
    update;
  }

  /* 3) Modal wideo — lazy iframe YouTube, usuwany przy zamknięciu (stop odtwarzania) */
  function initVideoModal {
    const dialog = document.querySelector('dialog.video-modal');
    if (!dialog) return;
    const frame = dialog.querySelector('.video-frame');

    function open(id) {
      frame.innerHTML =
        '<iframe src="https://www.youtube-nocookie.com/embed/' + encodeURIComponent(id) +
        '?autoplay=1&rel=0" title="Wideo" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>';
      if (typeof dialog.showModal === 'function') dialog.showModal;
      else dialog.setAttribute('open', '');
    }
    function close {
      frame.innerHTML = '';            // stop odtwarzania
      if (typeof dialog.close === 'function') dialog.close;
      else dialog.removeAttribute('open');
    }

    document.querySelectorAll('.video-trigger').forEach((btn) => {
      btn.addEventListener('click',  => open(btn.dataset.yt));
    });
    // zamknięcie: przycisk ×, klik tła, Esc (Esc obsługuje natywny <dialog>)
    dialog.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', close));
    dialog.addEventListener('click', (e) => { if (e.target === dialog) close; });
    dialog.addEventListener('cancel',  => { frame.innerHTML = ''; }); // Esc
  }

  function init { initReveal; initNavBlur; initVideoModal; }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init;
});
