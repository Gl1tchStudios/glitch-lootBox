/* glitch-lootBox NUI - CS2 style case opening.
   The server has already decided the reward; this file only animates it.
   One requestAnimationFrame loop runs while the reel spins and nothing runs while closed. */
'use strict';

const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'glitch-lootBox';
const $ = (id) => document.getElementById(id);

const PLACEHOLDER = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">' +
    '<rect x="10" y="14" width="44" height="36" rx="4" fill="none" stroke="#8a94a3" stroke-width="3"/>' +
    '<path d="M10 25h44" stroke="#8a94a3" stroke-width="3"/>' +
    '<text x="32" y="45" font-family="Arial" font-size="15" font-weight="700" fill="#8a94a3" text-anchor="middle">?</text>' +
    '</svg>'
);

const cfg = {
    ui: {
        showChances: true,
        spinTime: 6.5,
        allowSkip: true,
        volume: 0.5,
        inventory: { iconPath: 'nui://ox_inventory/web/images/', iconExtension: '.png', fallbackIcon: false },
    },
    rarities: {
        common: { order: 1, label: 'Common', color: '#b0c3d9' },
    },
};

const S = {
    open: false,
    view: null,
    box: null,
    spin: null,
    spinning: false,
    revealed: false,
    granted: null,
    busy: false,
    raf: 0,
    endX: 0,
    winEl: null,
    timers: [],
};

// ---- helpers --------------------------------------------------------

function post(name, data) {
    return fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).then((r) => r.json()).catch(() => null);
}

const asArray = (v) => (Array.isArray(v) ? v : []);
const wait = (ms) => new Promise((res) => setTimeout(res, ms));

function later(fn, ms) {
    S.timers.push(setTimeout(fn, ms));
}

function clearTimers() {
    S.timers.forEach(clearTimeout);
    S.timers.length = 0;
}

function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
}

function rgb(hex) {
    const h = String(hex || '').replace('#', '');
    const full = h.length === 3 ? h.split('').map((c) => c + c).join('') : h;
    const n = parseInt(full, 16);
    if (Number.isNaN(n) || full.length !== 6) return '176, 195, 217';
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
}

function paint(node, color) {
    node.style.setProperty('--rc', color);
    node.style.setProperty('--rc-rgb', rgb(color));
}

function rarity(key) {
    return cfg.rarities[key] || cfg.rarities.common || { order: 1, label: String(key), color: '#b0c3d9' };
}

function pct(n) {
    n = Number(n) || 0;
    if (n >= 10) return `${n.toFixed(0)}%`;
    if (n >= 1) return `${n.toFixed(1)}%`;
    return `${n.toFixed(2)}%`;
}

function mergeCfg(next) {
    if (!next) return;
    if (next.ui) {
        const inv = Object.assign({}, cfg.ui.inventory, next.ui.inventory || {});
        Object.assign(cfg.ui, next.ui);
        cfg.ui.inventory = inv;
    }
    if (next.rarities && typeof next.rarities === 'object') cfg.rarities = next.rarities;
}

function fit() {
    const s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
    $('stage').style.setProperty('--scale', String(s));
}

// ---- images ---------------------------------------------------------
// A missing icon falls back once (configured fallback, then the built-in one) and is
// remembered, so a broken image can never loop requests.

const imgState = new Map(); // url -> true (loads) | false (missing)

function itemUrl(item) {
    const inv = cfg.ui.inventory;
    return `${inv.iconPath}${item}${inv.iconExtension}`;
}

function useFallback(img) {
    const fb = cfg.ui.inventory.fallbackIcon;
    if (fb && img.dataset.fb !== '1') {
        img.dataset.fb = '1';
        img.onerror = () => { img.onerror = null; img.src = PLACEHOLDER; };
        img.src = fb;
    } else {
        img.onerror = null;
        img.src = PLACEHOLDER;
    }
}

function setImg(img, item) {
    const url = itemUrl(item);
    img.decoding = 'async';
    img.draggable = false;
    img.alt = '';
    delete img.dataset.fb;
    if (imgState.get(url) === false) return useFallback(img);
    img.onerror = () => { imgState.set(url, false); useFallback(img); };
    img.src = url;
}

function preload(items) {
    const urls = [...new Set(items.map(itemUrl))].filter((u) => !imgState.has(u));
    return Promise.all(urls.map((url) => new Promise((done) => {
        const im = new Image();
        im.onload = () => {
            imgState.set(url, true);
            (im.decode ? im.decode().catch(() => {}) : Promise.resolve()).then(done);
        };
        im.onerror = () => { imgState.set(url, false); done(); };
        im.src = url;
    })));
}

// ---- sound ----------------------------------------------------------
// Reel ticks are synthesised with Web Audio (no files, no NUI round trips per tick).

const sfx = (() => {
    let ctx = null;
    let out = null;
    let noise = null;

    function init() {
        try {
            if (!ctx) {
                const AC = window.AudioContext || window.webkitAudioContext;
                if (!AC) return;
                ctx = new AC();
                out = ctx.createGain();
                out.connect(ctx.destination);
                const len = Math.floor(ctx.sampleRate * 0.025);
                noise = ctx.createBuffer(1, len, ctx.sampleRate);
                const d = noise.getChannelData(0);
                for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 4);
            }
            out.gain.value = Math.max(0, Math.min(1, Number(cfg.ui.volume) || 0));
            if (ctx.state === 'suspended') ctx.resume();
        } catch (e) {
            ctx = null;
        }
    }

    const live = () => ctx && out && out.gain.value > 0;

    function click(level, pitch) {
        const t = ctx.currentTime;
        const src = ctx.createBufferSource();
        const bp = ctx.createBiquadFilter();
        const g = ctx.createGain();
        src.buffer = noise;
        bp.type = 'bandpass';
        bp.frequency.value = pitch + Math.random() * 400;
        bp.Q.value = 0.9;
        g.gain.value = level;
        src.connect(bp);
        bp.connect(g);
        g.connect(out);
        src.start(t);

        const o = ctx.createOscillator();
        const og = ctx.createGain();
        o.type = 'triangle';
        o.frequency.setValueAtTime(pitch * 0.55, t);
        o.frequency.exponentialRampToValueAtTime(pitch * 0.25, t + 0.025);
        og.gain.setValueAtTime(0.2 * level, t);
        og.gain.exponentialRampToValueAtTime(0.0001, t + 0.04);
        o.connect(og);
        og.connect(out);
        o.start(t);
        o.stop(t + 0.05);
    }

    function tick() {
        if (live()) click(0.9, 2700);
    }

    function thud() {
        if (!live()) return;
        const t = ctx.currentTime;
        const o = ctx.createOscillator();
        const g = ctx.createGain();
        o.type = 'sine';
        o.frequency.setValueAtTime(150, t);
        o.frequency.exponentialRampToValueAtTime(45, t + 0.22);
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(0.8, t + 0.01);
        g.gain.exponentialRampToValueAtTime(0.0001, t + 0.3);
        o.connect(g);
        g.connect(out);
        o.start(t);
        o.stop(t + 0.32);
        click(0.7, 1800);
    }

    function land() {
        if (live()) click(1, 1500);
    }

    return { init, tick, thud, land };
})();

// ---- views ----------------------------------------------------------

function setView(name) {
    ['preview', 'reel', 'reveal'].forEach((v) => $(`view-${v}`).classList.toggle('active', v === name));
    S.view = name;
}

function setAccent(color) {
    const c = color || '#f2b632';
    const app = $('app');
    app.style.setProperty('--accent', c);
    app.style.setProperty('--accent-rgb', rgb(c));
}

function openApp() {
    if (S.open) return;
    S.open = true;
    fit();
    $('app').classList.remove('hidden');
}

function hideApp() {
    S.open = false;
    stopSpin();
    clearTimers();
    setView(null);
    $('app').classList.add('hidden');
    $('strip').textContent = '';
    $('grid').textContent = '';
    $('rv-sparks').textContent = '';
    S.spin = null;
    S.box = null;
    S.granted = null;
    S.winEl = null;
    S.busy = false;
}

function close() {
    if (!S.open) return;
    post('close');
    hideApp();
}

function makeCard(entry, withName) {
    const r = rarity(entry.rarity);
    const card = el('div', 'card');
    paint(card, r.color);
    if (r.mystery) {
        card.classList.add('mystery');
        card.appendChild(el('div', 'star', String.fromCharCode(9733)));
        return card;
    }
    const img = el('img');
    setImg(img, entry.item);
    card.appendChild(img);
    if (withName) card.appendChild(el('div', 'card-name', entry.label));
    return card;
}

function renderExtras(host, list, found) {
    host.textContent = '';
    if (!list.length) {
        host.classList.add('hidden');
        return;
    }
    host.classList.remove('hidden');
    host.appendChild(el('div', 'label', found ? 'Also found' : 'Guaranteed extras'));
    const chips = el('div', 'chips');
    list.forEach((b) => {
        const chip = el('div', 'chip');
        const img = el('img');
        setImg(img, b.item);
        const text = el('div');
        text.appendChild(el('b', null, b.label));
        text.appendChild(el('span', null, `x${b.amount}`));
        chip.appendChild(img);
        chip.appendChild(text);
        chips.appendChild(chip);
    });
    host.appendChild(chips);
}

// ---- 1. preview -----------------------------------------------------

function makeTile(entry, mysteryChance) {
    const r = rarity(entry.rarity);
    const tile = el('div', 'tile');
    paint(tile, r.color);
    tile.appendChild(makeCard(entry, false));

    const info = el('div', 'tile-info');
    const mystery = mysteryChance !== undefined;
    info.appendChild(el('div', mystery ? 'tile-name gold' : 'tile-name', mystery ? 'Rare Special Item' : entry.label));
    info.appendChild(el('div', 'tile-amount', mystery ? 'Exceedingly rare' : `x${entry.amount}`));
    const meta = el('div', 'tile-meta');
    meta.appendChild(el('span', 'tile-grade', r.label));
    if (cfg.ui.showChances) meta.appendChild(el('span', 'tile-chance', pct(mystery ? mysteryChance : entry.chance)));
    info.appendChild(meta);
    tile.appendChild(info);
    return tile;
}

function renderPreview(data) {
    clearTimers();
    stopSpin();
    S.box = data.box;
    S.busy = false;
    setAccent(data.box.accent);
    $('pv-name').textContent = data.box.name;

    const artImg = $('pv-art-img');
    const svg = document.querySelector('#pv-art .case-svg');
    if (data.box.image) {
        artImg.src = data.box.image;
        artImg.classList.remove('hidden');
        svg.classList.add('hidden');
    } else {
        artImg.classList.add('hidden');
        svg.classList.remove('hidden');
    }

    // Mystery grades collapse into one gold "Rare Special Item" tile, like CS2.
    const frag = document.createDocumentFragment();
    const mystery = new Map();
    asArray(data.box.items).forEach((it) => {
        if (rarity(it.rarity).mystery) {
            const m = mystery.get(it.rarity) || { entry: it, chance: 0 };
            m.chance += Number(it.chance) || 0;
            mystery.set(it.rarity, m);
        } else {
            frag.appendChild(makeTile(it));
        }
    });
    mystery.forEach((m) => frag.appendChild(makeTile(m.entry, m.chance)));
    const grid = $('grid');
    grid.textContent = '';
    grid.scrollTop = 0;
    grid.appendChild(frag);

    renderExtras($('pv-extras'), asArray(data.box.bonus), false);
    $('pv-owned').textContent = `${data.owned || 0}x`;
    $('btn-unlock').disabled = false;
    setView('preview');
}

function unlock() {
    if (S.view !== 'preview' || S.busy) return;
    S.busy = true;
    $('btn-unlock').disabled = true;
    post('unlock');
    later(() => {
        if (S.view === 'preview') {
            S.busy = false;
            $('btn-unlock').disabled = false;
        }
    }, 2500);
}

// ---- 2. reel --------------------------------------------------------

// Fast start, long crawl over the last few cards.
const ease = (t) => 1 - Math.pow(1 - t, 4);

function stopSpin() {
    if (S.raf) cancelAnimationFrame(S.raf);
    S.raf = 0;
    S.spinning = false;
}

async function startSpin(data) {
    clearTimers();
    stopSpin();
    S.spin = data;
    S.box = data.box;
    S.revealed = false;
    S.granted = null;
    S.busy = false;
    setAccent(data.box.accent);
    $('rl-name').textContent = data.box.name;
    $('rl-hint').classList.toggle('hidden', !cfg.ui.allowSkip);

    const reel = asArray(data.reel);
    if (!data.reward) return;
    if (!reel.length) return showReveal();
    const win = Math.max(0, Math.min(reel.length - 1, (Number(data.winner) || reel.length) - 1));

    const strip = $('strip');
    strip.classList.remove('settled', 'moving');
    strip.style.transform = 'translate3d(0px, 0, 0)';
    strip.textContent = '';
    const frag = document.createDocumentFragment();
    reel.forEach((entry) => frag.appendChild(makeCard(entry, true)));
    strip.appendChild(frag);
    setView('reel');

    sfx.init();
    await Promise.race([preload(reel.map((e) => e.item).concat(data.reward.item)), wait(1200)]);
    if (S.spin !== data || S.revealed) return; // closed, replaced or skipped while images loaded

    try {
        spinReel(reel, win);
    } catch (err) {
        // Never strand the player on a broken reel: the reveal still claims the reward.
        stopSpin();
        showReveal();
    }
}

function spinReel(reel, win) {
    const strip = $('strip');
    const first = strip.firstElementChild;
    const cardW = first.offsetWidth;
    const pitch = cardW + (parseFloat(getComputedStyle(strip).columnGap) || 0);
    const center = $('reel').clientWidth / 2;

    // Keep the right half of the reel filled when it stops (wide screens, short reels).
    const needAfter = Math.ceil(center / pitch) + 1;
    for (let have = reel.length - win - 1, j = 0; have < needAfter; have++, j++) {
        strip.appendChild(makeCard(reel[j % Math.max(1, win)], true));
    }

    S.winEl = strip.children[win];
    // Land at a random point inside the winning card like CS2, not dead centre.
    const land = cardW * (0.1 + Math.random() * 0.8);
    S.endX = -(win * pitch + land - center);
    run(0, S.endX, center, pitch, Math.max(1, Number(cfg.ui.spinTime) || 6.5) * 1000);
}

function run(x0, x1, center, pitch, duration) {
    const strip = $('strip');
    strip.classList.add('moving');
    S.spinning = true;
    sfx.thud();

    let lastIdx = Math.floor((center - x0) / pitch);
    const t0 = performance.now();
    const frame = (now) => {
        const t = Math.min(1, (now - t0) / duration);
        const x = x0 + (x1 - x0) * ease(t);
        strip.style.transform = `translate3d(${x.toFixed(2)}px, 0, 0)`;
        const idx = Math.floor((center - x) / pitch);
        if (idx !== lastIdx) {
            lastIdx = idx;
            sfx.tick();
        }
        if (t < 1) {
            S.raf = requestAnimationFrame(frame);
        } else {
            S.raf = 0;
            settle(false);
        }
    };
    S.raf = requestAnimationFrame(frame);
}

function settle(skipped) {
    if (!S.spinning) return;
    S.spinning = false;
    const strip = $('strip');
    strip.classList.remove('moving');
    strip.classList.add('settled');
    if (S.winEl) S.winEl.classList.add('win');
    sfx.land();
    later(showReveal, skipped ? 250 : 900);
}

function skip() {
    if (!cfg.ui.allowSkip || S.revealed) return;
    if (!S.spinning) return showReveal(); // still loading images, or already settled
    if (S.raf) cancelAnimationFrame(S.raf);
    S.raf = 0;
    $('strip').style.transform = `translate3d(${S.endX.toFixed(2)}px, 0, 0)`;
    settle(true);
}

// ---- 3. reveal ------------------------------------------------------

function sparks(on) {
    const host = $('rv-sparks');
    host.textContent = '';
    if (!on) return;
    const n = 18;
    for (let i = 0; i < n; i++) {
        const s = el('i', 'spark');
        const a = (i / n) * Math.PI * 2 + Math.random() * 0.3;
        const d = 170 + Math.random() * 150;
        s.style.setProperty('--dx', `${(Math.cos(a) * d).toFixed(1)}px`);
        s.style.setProperty('--dy', `${(Math.sin(a) * d).toFixed(1)}px`);
        s.style.animationDelay = `${(Math.random() * 2).toFixed(2)}s`;
        host.appendChild(s);
    }
}

function showReveal() {
    if (!S.spin || S.revealed) return;
    S.revealed = true;
    const { reward } = S.spin;
    const r = rarity(reward.rarity);

    paint($('view-reveal'), r.color);
    setImg($('rv-img'), reward.item);
    $('rv-name').textContent = reward.label;
    $('rv-grade').textContent = r.label;
    $('rv-amount').textContent = `x${reward.amount}`;
    renderExtras($('rv-extras'), asArray(S.spin.bonus), true);
    sparks((r.order || 0) >= 5);

    const status = $('rv-status');
    status.className = 'bar-info';
    status.textContent = 'Adding to your inventory...';
    $('btn-again').classList.add('hidden');
    setView('reveal');

    post('reveal', { rarity: reward.rarity });
    if (S.granted) applyGranted(S.granted);
}

function applyGranted(info) {
    S.granted = info;
    if (!S.revealed || !info) return;

    const status = $('rv-status');
    if (info.lost) {
        status.className = 'bar-info bad';
        status.textContent = 'Inventory full - contact staff';
    } else if (info.dropped) {
        status.className = 'bar-info warn';
        status.textContent = 'Inventory full - dropped at your feet';
    } else {
        status.className = 'bar-info good';
        status.textContent = 'Added to your inventory';
    }

    const again = $('btn-again');
    if (info.remaining > 0 && S.box && info.box === S.box.id) {
        again.textContent = `Open Another (${info.remaining})`;
        again.disabled = false;
        again.classList.remove('hidden');
    }
}

function again() {
    if (S.view !== 'reveal' || S.busy || !S.granted || !(S.granted.remaining > 0) || !S.box) return;
    S.busy = true;
    $('btn-again').disabled = true;
    post('again', { box: S.box.id });
    later(() => {
        if (S.view === 'reveal') {
            S.busy = false;
            $('btn-again').disabled = false;
        }
    }, 2500);
}

// ---- input ----------------------------------------------------------

$('btn-unlock').addEventListener('click', unlock);
$('btn-again').addEventListener('click', again);
document.querySelectorAll('[data-act="close"]').forEach((b) => b.addEventListener('click', close));
document.addEventListener('contextmenu', (e) => e.preventDefault());
// A focused button would also fire on SPACE / ENTER on top of the key handler below.
document.addEventListener('focusin', (e) => { if (e.target.tagName === 'BUTTON') e.target.blur(); });

document.addEventListener('keydown', (e) => {
    if (!S.open || e.repeat) return;
    const back = e.key === 'Escape' || e.key === 'Backspace';
    const go = e.key === ' ' || e.key === 'Enter';
    if (!back && !go) return;
    e.preventDefault();

    if (S.view === 'preview') {
        if (back) close();
        else unlock();
    } else if (S.view === 'reel') {
        skip(); // a rolled crate cannot be cancelled, only skipped to the reveal
    } else if (S.view === 'reveal') {
        if (go && !$('btn-again').classList.contains('hidden') && !$('btn-again').disabled) again();
        else close();
    }
});

window.addEventListener('resize', fit);

// ---- messages from the client ---------------------------------------

window.addEventListener('message', (e) => {
    const m = e.data || {};
    switch (m.action) {
        case 'preview':
            mergeCfg(m.cfg);
            openApp();
            renderPreview(m.data);
            post('shown');
            break;
        case 'spin':
            mergeCfg(m.cfg);
            openApp();
            startSpin(m.data);
            post('shown');
            break;
        case 'granted':
            applyGranted(m.data);
            break;
        case 'hide':
            if (S.open) hideApp();
            break;
    }
});

fit();
