// LEVEL UP lofi radio: an original lofi loop generated live in the browser (Web Audio).
// Rhodes-like chords, soft bass, swung drums, a sparse melody and vinyl crackle.
// Starts on the first tap (browsers block sound before that), remembers on/off.
(function(){
  const KEY = 'lu_music';
  let on = true; try { on = localStorage.getItem(KEY) !== 'off'; } catch(e){}
  let ctx = null, master, wow, noiseBuf, timer = null, step = 0, nextT = 0, started = false;
  const BPM = 74, S16 = 60 / BPM / 4, SWING = .2;
  const CH = [[53,57,60,64,67],[52,55,59,62,66],[50,53,57,60,64],[48,52,55,59,62]];
  const BASS = [41,40,38,36];
  const PENTA = [72,74,76,79,81,84];
  const KICK = [0,7,10], SNARE = [4,12];
  const hz = m => 440 * Math.pow(2, (m - 69) / 12);

  function init(){
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 2600; lp.Q.value = .4;
    const comp = ctx.createDynamicsCompressor(); comp.threshold.value = -18; comp.ratio.value = 3;
    master = ctx.createGain(); master.gain.value = 0;
    master.connect(lp); lp.connect(comp); comp.connect(ctx.destination);
    wow = ctx.createOscillator(); wow.frequency.value = .45; const wg = ctx.createGain(); wg.gain.value = 9; wow.connect(wg); wow.start(); wow.out = wg;
    noiseBuf = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    const d = noiseBuf.getChannelData(0); for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    // vinyl bed
    const vb = ctx.createBufferSource(); vb.buffer = noiseBuf; vb.loop = true;
    const vf = ctx.createBiquadFilter(); vf.type = 'bandpass'; vf.frequency.value = 1400; vf.Q.value = .6;
    const vg = ctx.createGain(); vg.gain.value = .018; vb.connect(vf); vf.connect(vg); vg.connect(master); vb.start();
    // echo for the melody
    ctx.dly = ctx.createDelay(); ctx.dly.delayTime.value = S16 * 3; const fb = ctx.createGain(); fb.gain.value = .32;
    ctx.dly.connect(fb); fb.connect(ctx.dly); ctx.dly.connect(master);
  }
  function env(g, t, a, peak, dec){ g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(peak, t + a); g.gain.exponentialRampToValueAtTime(.0001, t + a + dec); }
  function key(m, t, dur, vel){
    const g = ctx.createGain(); env(g, t, .012, .055 * vel, dur);
    [[1, 'sine', 1], [2, 'triangle', .18]].forEach(([mul, type, lvl]) => {
      const o = ctx.createOscillator(); o.type = type; o.frequency.value = hz(m) * mul; wow.out.connect(o.detune);
      const og = ctx.createGain(); og.gain.value = lvl; o.connect(og); og.connect(g); o.start(t); o.stop(t + dur + .1);
    });
    g.connect(master);
  }
  function bass(m, t){
    const o = ctx.createOscillator(); o.type = 'sine'; o.frequency.value = hz(m);
    const g = ctx.createGain(); env(g, t, .02, .22, .9); o.connect(g); g.connect(master); o.start(t); o.stop(t + 1.1);
  }
  function kick(t){
    const o = ctx.createOscillator(); o.frequency.setValueAtTime(115, t); o.frequency.exponentialRampToValueAtTime(42, t + .14);
    const g = ctx.createGain(); env(g, t, .004, .55, .32); o.connect(g); g.connect(master); o.start(t); o.stop(t + .4);
  }
  function noise(t, type, f, peak, dec){
    const s = ctx.createBufferSource(); s.buffer = noiseBuf; s.playbackRate.value = .8 + Math.random() * .4;
    const fl = ctx.createBiquadFilter(); fl.type = type; fl.frequency.value = f; fl.Q.value = .7;
    const g = ctx.createGain(); env(g, t, .002, peak, dec); s.connect(fl); fl.connect(g); g.connect(master);
    s.start(t, Math.random()); s.stop(t + dec + .05);
  }
  function lead(m, t){
    const o = ctx.createOscillator(); o.type = 'sine'; o.frequency.value = hz(m); wow.out.connect(o.detune);
    const g = ctx.createGain(); env(g, t, .03, .045, 1.1); o.connect(g); g.connect(master); g.connect(ctx.dly); o.start(t); o.stop(t + 1.3);
  }
  function crackle(t){ if (Math.random() < .35) noise(t + Math.random() * S16, 'highpass', 2500, .05 * Math.random(), .006); }

  function schedule(){
    while (nextT < ctx.currentTime + .15){
      const s = step % 16, bar = Math.floor(step / 16) % 4, t = nextT + (s % 2 ? S16 * SWING : 0);
      if (s === 0){ CH[bar].forEach((m, i) => key(m, t + i * .012, S16 * 15, .8 + Math.random() * .3)); bass(BASS[bar], t); }
      if (s === 10) bass(BASS[bar], t);
      if (s === 8 && Math.random() < .5) CH[bar].slice(1, 4).forEach((m, i) => key(m + 12, t + i * .01, S16 * 6, .35));
      if (KICK.includes(s)) kick(t);
      if (SNARE.includes(s)){ noise(t, 'bandpass', 1700, .2, .17); }
      if (s % 2 === 0 && Math.random() < .85) noise(t, 'highpass', 7200, .035 + Math.random() * .03, .045);
      if (s % 2 === 0 && Math.random() < .14) lead(PENTA[Math.floor(Math.random() * PENTA.length)], t);
      crackle(t);
      nextT += S16; step++;
    }
  }
  function fade(to){ if (!ctx) return; master.gain.cancelScheduledValues(ctx.currentTime); master.gain.setTargetAtTime(to, ctx.currentTime, .6); }
  function start(){
    if (!ctx) init();
    if (ctx.state === 'suspended') ctx.resume();
    if (!timer){ nextT = ctx.currentTime + .1; timer = setInterval(schedule, 30); }
    fade(.9); started = true; ui();
  }
  function stop(){ fade(0); ui(); }
  function ui(){ document.querySelectorAll('[data-lofi]').forEach(b => { b.classList.toggle('off', !on); b.title = on ? 'Выключить музыку' : 'Включить lofi'; }); }
  window.LOFI = {
    toggle(){ if (on && !started){ start(); return; } on = !on; try { localStorage.setItem(KEY, on ? 'on' : 'off'); } catch(e){} on ? start() : stop(); },
    get on(){ return on; }
  };
  const kick0 = e => { if (e.target.closest && e.target.closest('[data-lofi]')) return; if (on && !started) start(); };
  ['pointerdown','touchstart','keydown'].forEach(ev => window.addEventListener(ev, kick0, {passive:true}));
  document.addEventListener('visibilitychange', () => { if (!ctx) return; document.hidden ? ctx.suspend() : (on && ctx.resume()); });
  document.addEventListener('click', e => { const b = e.target.closest('[data-lofi]'); if (b){ e.stopPropagation(); LOFI.toggle(); } }, true);
  document.addEventListener('DOMContentLoaded', ui);
})();
