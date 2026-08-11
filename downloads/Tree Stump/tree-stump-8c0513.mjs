/*
 * Tree Stump
 * https://polyfork.dev/asset/tree-stump-8c0513
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './tree-stump-8c0513.mjs';
 *   scene.add(createAsset());
 *
 * The bare "three" specifiers below resolve through any bundler, or through
 * an importmap in your page:
 *
 *   { "imports": { "three": "https://unpkg.com/three@0.180.0/build/three.module.js",
 *                  "three/addons/": "https://unpkg.com/three@0.180.0/examples/jsm/" } }
 *
 * Browsers refuse to load ES modules from file:// URLs, so a page of your own
 * that imports this file has to be served over http:  python3 -m http.server
 *
 * The index.html in this asset's .zip download sidesteps that and opens with
 * a double-click. The store page above has the same snippet for Unity, Godot,
 * Blender and GLB.
 *
 * OPTIONS  createAsset({ ... })
 *
 *   colorway     choice  'oak'          'oak' | 'walnut' | 'pale-birch' | 'mossy'
 *   bark         color   '#8c6a4a'      any hex or THREE.Color
 *   sapwood      color   '#b89b72'      any hex or THREE.Color
 *   heartwood    color   '#e8dcc0'      any hex or THREE.Color
 *   underside    color   '#6f4e37'      any hex or THREE.Color
 *   handle       color   '#9a3b32'      any hex or THREE.Color
 *   steel        color   '#4a5462'      any hex or THREE.Color
 *   edge         color   '#a3aebb'      any hex or THREE.Color
 *   tallness     range   1              0.7 to 1.1
 *   facets       range   14             10 to 20
 *   roots        range   4              3 to 6
 *   barkRelief   range   1              0.4 to 1.7
 *   axe          toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/tree-stump-8c0513-params.json
 *
 * SPECS  524 triangles, 1 material, 1.25 x 1.32 x 1.14 m (real-world scale).
 *        detach: axe
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'oak':        { bark: 0x8c6a4a, underside: 0x6f4e37, sapwood: 0xb89b72, heartwood: 0xe8dcc0, handle: 0x9a3b32, steel: 0x4a5462, edge: 0xa3aebb },
  'walnut':     { bark: 0x6f4e37, underside: 0x4a6a4f, sapwood: 0x8c6a4a, heartwood: 0xb89b72, handle: 0x9a3b32, steel: 0x4a5462, edge: 0xa3aebb },
  'pale-birch': { bark: 0xb89b72, underside: 0x6f4e37, sapwood: 0xe8dcc0, heartwood: 0x8c6a4a, handle: 0x9a3b32, steel: 0x4a5462, edge: 0xa3aebb },
  'mossy':      { bark: 0x7d8a5a, underside: 0x4a6a4f, sapwood: 0xb89b72, heartwood: 0xe8dcc0, handle: 0x9a3b32, steel: 0x4a5462, edge: 0xa3aebb },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'oak', label: 'Colorway',
              options: ['oak', 'walnut', 'pale-birch', 'mossy'],
              describe: 'curated wood scheme; sets all six zone albedos at once. oak = mid-brown bark with a cream heartwood bullseye (the delivered look), walnut = dark damp hardwood throughout, pale-birch = bleached tan bark with a cream cut face and a mid-brown heart, mossy = a sage moss-clad trunk with a bare wood cut face. The painted red haft is the constant accent in all four' },
  bark:      { type: 'color', default: '#8c6a4a', label: 'Bark',
               describe: 'albedo of the whole trunk exterior — shaft facets, root flare and the crown bark rim. One albedo over the entire bark surface; the facets do the shading, not the vertex colours' },
  sapwood:   { type: 'color', default: '#b89b72', label: 'Sawn face',
               describe: 'albedo of the broad flat sapwood field of the sawn crown, between the bark rim and the heartwood disc' },
  heartwood: { type: 'color', default: '#e8dcc0', label: 'Heartwood',
               describe: 'albedo of the pale bullseye disc at the centre of the cut face — the focal note and normally the lightest colour in the asset' },
  underside: { type: 'color', default: '#6f4e37', label: 'Underside',
               describe: 'albedo of the flat ground cap under the stump; only ever seen if the prop is lifted or tipped' },
  handle:    { type: 'color', default: '#9a3b32', label: 'Axe handle',
               describe: 'albedo of the axe haft — the kit painted accent and the one warm hit of colour in the prop' },
  steel:     { type: 'color', default: '#4a5462', label: 'Axe head',
               describe: 'albedo of the axe head body — poll, waisted neck, bevel bands and cheek ridge. Stylized dark slate steel read through faceting and value rather than a metalness map; keep it mid-dark or the modelled facets collapse into one silhouette' },
  edge:      { type: 'color', default: '#a3aebb', label: 'Honed edge',
               describe: 'albedo of the honed bevel facet running the cutting edge, from the toe round the bit arc to the beard tip. Bright polished steel against the dark head — this is the band that makes the arced edge read at thumbnail size, so keep a wide value gap to the head' },
  tallness:  { type: 'range', default: 1.0, min: 0.7, max: 1.1, label: 'Tallness', icon: '↕️', affects: 'geometry',
               describe: 'height of the chopping block, REBUILT not scaled: the foot rows and the crown flare keep their real dimensions and the straight shaft between them gains or loses whole bark ring rows at a ~0.085 m pitch (triangle count moves with it: 468 / 524 / 552). 0.7 = a 0.46 m block, twice as wide as tall; 1.0 = the delivered 0.66 m stump; 1.1 = a 0.73 m stump with an extra ring row. Crown diameter and the axe are unchanged; the root toes keep their share of the height, so they die out proportionally further up a taller block' },
  facets:    { type: 'range', default: 14, min: 10, max: 20, label: 'Bark facets', icon: '⭕', affects: 'geometry',
               describe: 'number of vertical facet columns around the trunk (integer). 10 = a chunky faceted block whose ridges read as big flat planes, 14 = delivered, 20 = a finer scalloped bark with narrower ridges. The raised-ridge / sunken-groove pattern is resampled from the authored run so it never falls into a regular alternation' },
  roots:     { type: 'range', default: 4, min: 3, max: 6, label: 'Root toes', icon: '🌱', affects: 'geometry',
               describe: 'number of buttress root toes splaying out at the base (integer), evenly spaced around the trunk with per-toe jitter in angle, strength, reach and height. Each toe is a solid wedge on the flared wall, so the count changes the triangle count too (498 / 524 / 550 / 576). 3 = a wide tripod foot with big gaps between the haunches, 4 = delivered, 6 = a dense star of smaller toes. Changes the ground footprint outline, not the crown' },
  barkRelief:{ type: 'range', default: 1.0, min: 0.4, max: 1.7, label: 'Bark relief', icon: '🪵', affects: 'geometry',
               describe: 'depth of the vertical ridge-and-groove bark relief, as a multiplier on the delivered +8% / -13% radius alternation. 0.4 = an almost turned drum with faint scalloping, 1.0 = delivered, 1.7 = deeply gnarled bark whose ridges throw a sawtooth silhouette. Affects the trunk outline only' },
  axe:       { type: 'toggle', default: true, label: 'Axe', icon: '🪓', affects: 'geometry',
               describe: 'the axe buried in the cut face (head + haft). Off = a bare chopping block with a clean, unscarred crown, for scenes that want the stump as plain scenery. The crown is solid wood behind the axe either way, so nothing opens up' },
};

export const rig = {};
export const detach = ['axe'];
export const night = {};

const ZONE_KEYS = ['bark', 'underside', 'sapwood', 'heartwood', 'handle', 'steel', 'edge'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['oak'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.bark) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function mergeParts(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return merged;
}

const TOP_Y = 0.66;

const FOOT = [[0.000, 0.420], [0.055, 0.416], [0.140, 0.410]];
const SHAFT_LO = [0.265, 0.410];
const CROWN = [[0.240, 0.420], [0.100, 0.436], [0.000, 0.452]];
const ROW_PITCH = 0.085;

function ringTable(top) {
  const yFlare = top - CROWN[0][0];
  const rows = FOOT.slice();

  const lo = (yFlare - SHAFT_LO[0] > 0.05) ? SHAFT_LO : FOOT[FOOT.length - 1];
  if (lo === SHAFT_LO) rows.push(SHAFT_LO.slice());
  const span = yFlare - lo[0];
  const n = Math.max(0, Math.round(span / ROW_PITCH) - 1);
  for (let i = 1; i <= n; i++) {
    const t = i / (n + 1);
    rows.push([lo[0] + span * t, lerp(lo[1], CROWN[0][1], t)]);
  }
  for (const [drop, r] of CROWN) rows.push([top - drop, r]);
  return rows.map(([y, r]) => ({ y, r }));
}

const RIDGE14 = [true, false, true, true, false, true, false, true, true, false, true, false, true, false];

const TOE_JITTER = [
  0.10,
  1.85 - Math.PI / 2,
  3.35 - Math.PI,
  4.95 - Math.PI * 1.5,
  0.16, 0.25,
];

const TOE_R = [0.628, 0.548, 0.606, 0.536, 0.588, 0.566];
const TOE_S = [0.42, 0.50, 0.40, 0.47, 0.44, 0.46];
const TOE_H = [0.38, 0.28, 0.34, 0.30, 0.36, 0.32];
const TOE_W = [0.40, 0.36, 0.38, 0.34, 0.37, 0.35];

const WALL_SWELL = 1.20;
const ROOT_LIFT = 0.006;

function toeTable(n, hScale) {
  return Array.from({ length: n }, (_, i) => ({
    a: (i / n) * Math.PI * 2 + TOE_JITTER[i],
    s: TOE_S[i],
    h: TOE_H[i] * hScale,
    w: TOE_W[i],
    reach: TOE_R[i],
    wide: 0.10 + TOE_W[i] * 0.34,
    thick: 0.045 + TOE_S[i] * 0.06,
  }));
}

function rootLocal(r0, rWall, r1, h, ht, wb, wt) {
  const at = (t) => {
    const w = wt + (wb - wt) * (1 - t) ** 0.8;
    const yt = ht + (h - ht) * (1 - t) ** 1.6;
    return { w, yt };
  };
  const stations = [
    { r: r0, ...at(0) },
    { r: rWall, ...at(0) },
    { r: lerp(rWall, r1, 0.45), ...at(0.45) },
    { r: r1, ...at(1) },
  ];
  const rings = stations.map(({ r, w, yt }) => {

    const wTop = w * 0.78;
    return [[r, ROOT_LIFT, -w], [r, ROOT_LIFT, w], [r, yt, wTop], [r, yt, -wTop]];
  });
  const pos = [];
  for (let i = 0; i < rings.length - 1; i++) {
    const A = rings[i], B = rings[i + 1];
    for (let s = 0; s < 4; s++) {
      const t2 = (s + 1) % 4;
      quad(pos, A[s], B[s], B[t2], A[t2]);
    }
  }
  const L = rings[rings.length - 1];
  quad(pos, L[0], L[3], L[2], L[1]);
  return pos;
}

function buildRoots(parts, S, C, toes) {
  const pos = [];
  for (const T of toes) {

    const rWall = S.minWallR(T.h * 0.4);
    const reach = S.flareR(T.thick, T.a) - 0.015;
    const local = rootLocal(rWall - 0.03, rWall, reach, T.h, T.thick, T.wide, T.wide * 0.40);
    const g = posGeo(local).rotateY(-T.a);
    const p = g.attributes.position.array;
    for (let i = 0; i < p.length; i++) pos.push(p[i]);
  }
  parts.push({ g: posGeo(pos), c: C.bark });
}

function angDiff(a, b) {
  let d = Math.abs(a - b) % (Math.PI * 2);
  return d > Math.PI ? Math.PI * 2 - d : d;
}

function stumpShape(cols, top, nRoots, relief) {
  const rnd = prng(880513);
  const gnarl = Array.from({ length: cols }, () => 0.95 + rnd() * 0.11);
  const skew = Array.from({ length: cols }, () => (rnd() - 0.5) * 0.14);
  const rimWob = Array.from({ length: cols }, () => (rnd() - 0.5) * 0.012);

  const amp = Array.from({ length: cols }, () => 0.85 + rnd() * 0.30);
  const bow = Array.from({ length: cols }, () => (rnd() - 0.5) * 0.035);
  const ridge = Array.from({ length: cols }, (_, ci) => RIDGE14[Math.floor(ci * 14 / cols)]);
  const rings = ringTable(top);

  const jit = rings.map(() => Array.from({ length: cols }, () => 1 + (rnd() - 0.5) * 0.05));
  const toes = toeTable(nRoots, top / TOP_Y);

  const upA = 0.08 * relief, downA = 0.13 * relief;

  const S = { cols, top, rings, rimWob, toes };

  const toeAt = (y, ang) => {
    let t = 0;
    for (const T of toes) {
      const fall = Math.max(0, 1 - y / T.h) ** 1.2;
      if (fall <= 0) continue;
      const d = angDiff(ang, T.a) / T.w;
      const rise = Math.min(1, 0.82 + (y / 0.055) * 0.18);
      t += T.s * WALL_SWELL * rise * Math.exp(-d * d) * fall;
    }
    return t;
  };
  const colAngle = (ci, y) => (ci / cols) * Math.PI * 2 + skew[ci] + y * 0.05;
  S.ringVert = (ri, ci) => {
    const R = rings[ri];
    const a = colAngle(ci, R.y);
    const relf = ridge[ci] ? 1 + upA * amp[ci] : 1 - downA * amp[ci];
    const bowf = 1 + bow[ci] * Math.sin(Math.PI * Math.min(1, R.y / top));
    const r = R.r * gnarl[ci] * relf * bowf * jit[ri][ci] * (1 + toeAt(R.y, a));
    return [Math.cos(a) * r, R.y, Math.sin(a) * r];
  };

  S.flareR = (y, ang) => {
    let lo = rings[0], hi = rings[rings.length - 1];
    for (let i = 0; i < rings.length - 1; i++) {
      if (y >= rings[i].y && y <= rings[i + 1].y) { lo = rings[i]; hi = rings[i + 1]; break; }
    }
    const t = hi.y > lo.y ? (y - lo.y) / (hi.y - lo.y) : 0;
    return lerp(lo.r, hi.r, t) * (1 + toeAt(y, ang));
  };

  S.minWallR = (y) => {
    let m = Infinity;
    for (let ri = 0; ri < rings.length; ri++) {
      if (rings[ri].y < y - 0.12 || rings[ri].y > y + 0.12) continue;
      for (let ci = 0; ci < cols; ci++) {
        const v = S.ringVert(ri, ci);
        m = Math.min(m, Math.hypot(v[0], v[2]));
      }
    }
    return Number.isFinite(m) ? m : rings[0].r * 0.8;
  };

  S.crownVert = (ci) => {
    const v = S.ringVert(rings.length - 1, ci);
    return [v[0], top + rimWob[ci], v[2]];
  };
  return S;
}

function buildStump(parts, S, C) {
  const bark = [], under = [];
  const { cols, rings } = S;

  for (let ri = 0; ri < rings.length - 1; ri++) {
    const top = ri === rings.length - 2;
    for (let ci = 0; ci < cols; ci++) {
      const cj = (ci + 1) % cols;
      quad(bark,
        S.ringVert(ri, ci),
        top ? S.crownVert(ci) : S.ringVert(ri + 1, ci),
        top ? S.crownVert(cj) : S.ringVert(ri + 1, cj),
        S.ringVert(ri, cj));
    }
  }

  for (let ci = 0; ci < cols; ci++) {
    tri(under, [0, 0, 0], S.ringVert(0, ci), S.ringVert(0, (ci + 1) % cols));
  }

  const Y_CUT = S.top - 0.014;
  const ringAt = f => Array.from({ length: cols }, (_, ci) => {
    const v = S.crownVert(ci);
    return [v[0] * f, Y_CUT, v[2] * f];
  });
  const rim = ringAt(0.86), hrt = ringAt(0.42);
  const cut = [], heart = [];

  for (let ci = 0; ci < cols; ci++) {
    const cj = (ci + 1) % cols;
    quad(bark, S.crownVert(ci), rim[ci], rim[cj], S.crownVert(cj));
    quad(cut, rim[ci], hrt[ci], hrt[cj], rim[cj]);
    tri(heart, [0, Y_CUT, 0], hrt[cj], hrt[ci]);
  }

  parts.push({ g: posGeo(bark), c: C.bark });
  parts.push({ g: posGeo(under), c: C.underside });
  parts.push({ g: posGeo(cut), c: C.sapwood });
  parts.push({ g: posGeo(heart), c: C.heartwood });
}

const HEAD_PROFILE = [
  { x: 0.103, y: 0.058, e: 0.013, t: 0.032 },
  { x: -0.019, y: 0.035, e: 0.012, t: 0.030 },
  { x: -0.117, y: 0.114, e: 0.009, t: 0.021 },
  { x: -0.216, y: 0.138, e: 0.008, t: 0.013, hone: true },
  { x: -0.269, y: 0.009, e: 0.009, t: 0.013, hone: true },
  { x: -0.250, y: -0.097, e: 0.009, t: 0.013, hone: true },
  { x: -0.183, y: -0.183, e: 0.008, t: 0.013, hone: true },
  { x: -0.097, y: -0.137, e: 0.009, t: 0.021 },
  { x: 0.004, y: -0.039, e: 0.012, t: 0.030 },
  { x: 0.103, y: -0.058, e: 0.013, t: 0.032 },
];
const HEAD_INSET = 0.34;
const HEAD_RIDGE = 0.044;

const SHAFT_SEC = [
  { x: 0.020, r: 0.028, bend: 0.004 },
  { x: 0.180, r: 0.033, bend: -0.010 },
  { x: 0.360, r: 0.033, bend: -0.022 },
  { x: 0.530, r: 0.034, bend: -0.016 },
  { x: 0.680, r: 0.042, bend: 0.004 },
];

const HEX = Array.from({ length: 6 }, (_, s) => (s / 6) * Math.PI * 2);

function loftX(sections) {
  const rings = sections.map(s => s.pts.map(p => [s.x, p[0], p[1]]));
  const pos = [];
  for (let i = 0; i < rings.length - 1; i++) {
    const n = rings[i].length;
    for (let s = 0; s < n; s++) {
      const t = (s + 1) % n;
      quad(pos, rings[i][s], rings[i][t], rings[i + 1][t], rings[i + 1][s]);
    }
  }
  const first = rings[0], last = rings[rings.length - 1], lastS = sections[sections.length - 1];

  const cA = [sections[0].x, sections[0].cy || 0, sections[0].cz || 0];
  const cB = [lastS.x, lastS.cy || 0, lastS.cz || 0];
  for (let s = 0; s < first.length; s++) {
    const t = (s + 1) % first.length;
    tri(pos, cA, first[t], first[s]);
    tri(pos, cB, last[s], last[t]);
  }
  return pos;
}

function headLocal() {
  const p = HEAD_PROFILE.slice();
  let area2 = 0;
  for (let i = 0; i < p.length; i++) {
    const j = (i + 1) % p.length;
    area2 += p[i].x * p[j].y - p[j].x * p[i].y;
  }
  if (area2 < 0) p.reverse();

  const cx = p.reduce((s, q) => s + q.x, 0) / p.length;
  const cy = p.reduce((s, q) => s + q.y, 0) / p.length;
  const k = 1 - HEAD_INSET;
  const oF = p.map(q => [q.x, q.y, q.e]);
  const oB = p.map(q => [q.x, q.y, -q.e]);
  const iF = p.map(q => [cx + (q.x - cx) * k, cy + (q.y - cy) * k, q.t]);
  const iB = p.map(q => [cx + (q.x - cx) * k, cy + (q.y - cy) * k, -q.t]);
  const cF = [cx, cy, HEAD_RIDGE];
  const cB = [cx, cy, -HEAD_RIDGE];

  const pos = [], hone = [], n = p.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;

    const h = p[i].hone && p[j].hone ? hone : pos;
    quad(h, oB[i], oB[j], oF[j], oF[i]);
    quad(h, oF[i], oF[j], iF[j], iF[i]);
    quad(h, iB[i], iB[j], oB[j], oB[i]);

    tri(pos, cF, iF[i], iF[j]);
    tri(pos, cB, iB[j], iB[i]);
  }
  return { body: pos, hone };
}

function shaftLocal() {
  return loftX(SHAFT_SEC.map(s => ({
    x: s.x, cy: s.bend,

    pts: HEX.map(a => [Math.cos(a) * s.r + s.bend, Math.sin(a) * s.r]),
  })));
}

const BEARD_OFF = new THREE.Vector3(-0.055, -0.062, 0.050);
const SWING = new THREE.Vector3(0.76, 0.62, -0.14).normalize();

function axeMatrix(top) {
  const ex = SWING.clone();

  const n = new THREE.Vector3(0, 1, 0).cross(ex).normalize();
  const ey = new THREE.Vector3().crossVectors(ex, n).normalize();
  const ez = new THREE.Vector3().crossVectors(ex, ey);

  let low = HEAD_PROFILE[0], lowY = Infinity;
  for (const q of HEAD_PROFILE) {
    const y = ex.y * q.x + ey.y * q.y;
    if (y < lowY) { lowY = y; low = q; }
  }
  const beard = new THREE.Vector3(BEARD_OFF.x, top + BEARD_OFF.y, BEARD_OFF.z);
  const origin = beard
    .addScaledVector(ex, -low.x)
    .addScaledVector(ey, -low.y);
  return new THREE.Matrix4().makeBasis(ex, ey, ez).setPosition(origin);
}

function buildAxe(parts, top, C) {
  const M = axeMatrix(top);
  const head = headLocal();
  parts.push({ g: posGeo(head.body).applyMatrix4(M), c: C.steel });
  parts.push({ g: posGeo(head.hone).applyMatrix4(M), c: C.edge });
  parts.push({ g: posGeo(shaftLocal()).applyMatrix4(M), c: C.handle });
}

const DEFAULTS = { colorway: 'oak', tallness: 1, facets: 14, roots: 4, barkRelief: 1, axe: true };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const tall = clamp(num(o.tallness, 1), 0.7, 1.1);
  const cols = Math.round(clamp(num(o.facets, 14), 10, 20));
  const nRoots = Math.round(clamp(num(o.roots, 4), 3, 6));
  const relief = clamp(num(o.barkRelief, 1), 0.4, 1.7);
  const axeOn = !(o.axe === false || o.axe === 'false' || o.axe === 0);
  const top = TOP_Y * tall;

  const g = new THREE.Group();
  g.name = 'tree-stump';

  const material = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const S = stumpShape(cols, top, nRoots, relief);
  const stumpParts = []; buildStump(stumpParts, S, C); buildRoots(stumpParts, S, C, S.toes);
  const stumpGeo = mergeParts(stumpParts);
  const axeParts = []; if (axeOn) buildAxe(axeParts, top, C);
  const axeGeo = axeOn ? mergeParts(axeParts) : null;

  const bb = new THREE.Box3();
  for (const geo of [stumpGeo, axeGeo]) { if (!geo) continue; geo.computeBoundingBox(); bb.union(geo.boundingBox); }
  const dx = -(bb.min.x + bb.max.x) / 2, dy = -bb.min.y, dz = -(bb.min.z + bb.max.z) / 2;
  stumpGeo.translate(dx, dy, dz);
  if (axeGeo) axeGeo.translate(dx, dy, dz);

  const stump = new THREE.Mesh(stumpGeo, material);
  stump.name = 'stump-mesh';
  g.add(stump);

  const axe = new THREE.Group();
  axe.name = 'axe';
  if (axeGeo) {
    const axeMesh = new THREE.Mesh(axeGeo, material);
    axeMesh.name = 'axe-mesh';
    axe.add(axeMesh);
  }
  g.add(axe);

  return g;
}

export default createAsset;
