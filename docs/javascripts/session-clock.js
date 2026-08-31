/* ── Session clock ────────────────────────────────────────────────────────────
   Fills the timing strip at the top of a teaching-section page while that
   session is actually running, so the room can see how far through the slot we
   are. Outside the window the strip stays an empty track, which is also exactly
   what it looks like with JavaScript switched off.

   Times come from the element's data-start / data-end ("HH:MM", local time) and
   are compared against the reader's own clock — no date is involved, so this
   behaves sensibly on the day and is simply inert at any other hour.
   ──────────────────────────────────────────────────────────────────────────── */
(function () {
  "use strict";

  var TICK_MS = 30000;

  function minutesOfDay(text) {
    var parts = /^(\d{1,2}):(\d{2})$/.exec((text || "").trim());
    if (!parts) return null;
    var hours = Number(parts[1]);
    var mins = Number(parts[2]);
    if (hours > 23 || mins > 59) return null;
    return hours * 60 + mins;
  }

  function paint(clock) {
    var start = minutesOfDay(clock.getAttribute("data-start"));
    var end = minutesOfDay(clock.getAttribute("data-end"));
    var fill = clock.querySelector(".session-clock__fill");
    var needle = clock.querySelector(".session-clock__now");
    // Optional live countdown readout — only present on clocks that opt in (e.g. a break).
    var remaining = clock.querySelector(".session-clock__remaining");
    if (start === null || end === null || end <= start || !fill) return;

    var now = new Date();
    var elapsed = (now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60) - start;
    var fraction = elapsed / (end - start);

    if (fraction <= 0) {
      // Before the slot: a plain, empty bar.
      clock.setAttribute("data-state", "upcoming");
      fill.style.width = "0";
      if (needle) needle.style.left = "0";
      if (remaining) remaining.textContent = "starts " + clock.getAttribute("data-start");
      return;
    }

    if (fraction >= 1) {
      // After the slot: leave it full rather than snapping back to empty at the
      // moment the session ends. The needle hides itself via the data-state.
      clock.setAttribute("data-state", "done");
      fill.style.width = "100%";
      if (needle) needle.style.left = "100%";
      if (remaining) remaining.textContent = "done";
      return;
    }

    var percent = (fraction * 100).toFixed(2) + "%";
    clock.setAttribute("data-state", "running");
    fill.style.width = percent;
    if (needle) needle.style.left = percent;
    if (remaining) {
      var nowMinutes = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;
      var minutesLeft = Math.max(1, Math.ceil(end - nowMinutes));
      remaining.textContent = minutesLeft + " min left";
    }
  }

  function paintAll() {
    var clocks = document.querySelectorAll(".session-clock");
    for (var i = 0; i < clocks.length; i++) paint(clocks[i]);
  }

  // Material's instant navigation replaces the page body, so re-paint on every
  // document it emits. Fall back to a plain listener when that observable is
  // not present (instant navigation is not enabled today, but may be later).
  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(paintAll);
  } else if (document.readyState !== "loading") {
    paintAll();
  } else {
    document.addEventListener("DOMContentLoaded", paintAll);
  }

  setInterval(paintAll, TICK_MS);
})();
