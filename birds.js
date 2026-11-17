// Bird shadows: visible only inside the window light on the wall (same place as the window-frame shadow).
(function(){
  const H = 1214 / 720;                       // stage height in cqw units of width
  // light patches on the wall, in % of the stage (measured from the videos)
  const PATCHES = [{x:64.5, y:57.3, w:16.8, h:11}, {x:92.2, y:42, w:7.4, h:26.5}];
  const BIRD = '<svg viewBox="0 0 40 16"><path d="M0 7 C6 0 13 0 20 7 C27 0 34 0 40 7 C35 7 28 9 22 15 Q20 17 18 15 C12 9 5 7 0 7Z"/></svg>';
  const layer = document.getElementById('birds');
  if (!layer) return;
  layer.innerHTML = PATCHES.map(p => `<div class="bclip" style="left:${p.x}%;top:${p.y}%;width:${p.w}%;height:${p.h}%"></div>`).join('');
  const clips = [...layer.children];
  function flock(){
    const n = 1 + Math.floor(Math.random() * 3);
    const y0 = 58.6 + Math.random() * 6.4, dir = Math.random() < .7 ? 1 : -1, dur = 2300 + Math.random() * 1400;
    for (let i = 0; i < n; i++){
      const w = 4.4 + Math.random() * 2.2, flap = (.2 + Math.random() * .14) + 's';
      const dy = (Math.random() - .5) * 6, off = i * (5 + Math.random() * 5), yy = y0 + (Math.random() - .5) * 4;
      const sx = dir > 0 ? -12 - off : 112 + off, ex = dir > 0 ? 112 - off : -12 + off;
      clips.forEach((c, k) => {
        const p = PATCHES[k], ox = p.x, oy = p.y * H;  // clip origin in cqw
        const b = document.createElement('div'); b.className = 'bird'; b.innerHTML = BIRD;
        b.style.width = w + 'cqw'; b.style.height = (w * .45) + 'cqw'; b.firstChild.style.animationDuration = flap;
        c.appendChild(b);
        b.animate([
          {transform:`translate(${sx - ox}cqw, ${yy * H - oy}cqw) scaleX(${dir})`},
          {transform:`translate(${(sx + ex) / 2 - ox}cqw, ${(yy + dy - 2.5) * H - oy}cqw) scaleX(${dir})`},
          {transform:`translate(${ex - ox}cqw, ${(yy + dy) * H - oy}cqw) scaleX(${dir})`}
        ], {duration: dur + i * 120, easing:'linear', delay: i * 140}).onfinish = () => b.remove();
      });
    }
    setTimeout(flock, 6000 + Math.random() * 8000);
  }
  window.flock = flock;
  setTimeout(flock, 2500);
})();
