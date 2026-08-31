<!--
  Session clock for the lunch break (12:45-14:00).
  Included by the lunch page:  --8<-- "includes/clock-lunch.md"
  The .session-clock__remaining span makes this a live countdown to the resume time
  (docs/javascripts/session-clock.js fills it; docs/stylesheets/session-clock.css styles it).
  Times come from agenda/agenda.md - change them THERE first, then here.
-->
<div class="session-clock" data-start="12:45" data-end="14:00" role="img" aria-label="Lunch break: 12:45 to 14:00, back at 14:00">
  <span class="session-clock__label">Lunch</span>
  <span class="session-clock__time">12:45</span>
  <span class="session-clock__track"><span class="session-clock__fill"></span><span class="session-clock__now"></span></span>
  <span class="session-clock__time">14:00</span>
  <span class="session-clock__remaining" aria-hidden="true">back at 14:00</span>
</div>
