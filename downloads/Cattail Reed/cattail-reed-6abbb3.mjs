/*
 * Cattail Reed
 * https://polyfork.dev/asset/cattail-reed-6abbb3
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cattail-reed-6abbb3.mjs';
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
 *   colorway    choice  'summer-green' 'summer-green' | 'spring-shoot' | 'autumn-sedge' | 'dry-marsh'
 *   stalk       color   '#4c8140'      any hex or THREE.Color
 *   bladeDark   color   '#3d6b34'      any hex or THREE.Color
 *   bladeLight  color   '#93c46a'      any hex or THREE.Color
 *   head        color   '#75563b'      any hex or THREE.Color
 *   fluff       color   '#e0d2b4'      any hex or THREE.Color
 *   stage       choice  'mature'       'young' | 'mature' | 'seeding'
 *   height      range   1.2            0.85 to 1.25
 *   headLength  range   0.315          0.2 to 0.42
 *   blades      range   3              1 to 6
 *   spread      range   1              0.5 to 1.6
 *
 * Every option is described in full at https://polyfork.dev/cdn/cattail-reed-6abbb3-params.json
 *
 * SPECS  388 triangles, 1 material, 0.39 x 1.2 x 0.29 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DEG = Math.PI / 180;

export const COLORWAYS = {

  'summer-green': { stalk: 0x4C8140, bladeDark: 0x3D6B34, bladeLight: 0x93C46A, head: 0x75563B, fluff: 0xE0D2B4 },

  'spring-shoot': { stalk: 0x5F9A4B, bladeDark: 0x4C8140, bladeLight: 0xB3D47F, head: 0x8C6A47, fluff: 0xE0D2B4 },

  'autumn-sedge': { stalk: 0x8FA84A, bladeDark: 0x6F8F3C, bladeLight: 0xC8D98A, head: 0x5D4430, fluff: 0xE0D2B4 },

  'dry-marsh':    { stalk: 0xA5855E, bladeDark: 0x8C6A47, bladeLight: 0xC2A479, head: 0x4A3527, fluff: 0xF4ECE0 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'summer-green', label: 'Colorway',
    options: ['summer-green', 'spring-shoot', 'autumn-sedge', 'dry-marsh'],
    describe: 'curated kit-coherent scheme pairing the two blade greens with the stalk and the seed head. summer-green = the approved reed, mid green stalk between a dark and a light blade under a warm brown head; spring-shoot = every green lifted one rung and a paler unripe head, a young plant; autumn-sedge = the greens gone yellow-olive over a dark ripe head, late season; dry-marsh = the whole plant dead and bleached to straw and tan over a near-black head, the only brown-dominated scheme',
  },
  stalk: {
    type: 'color', default: '#4c8140', label: 'Stalk',
    describe: 'albedo of the single stalk running the full height of the plant, the vertical green line the seed head sits on; a thin zone by area but the one that reads at every camera height',
  },
  bladeDark: {
    type: 'color', default: '#3d6b34', label: 'Dark blades',
    describe: 'albedo of the darker blades (blade 0, 2, 4 ... around the ring) — the largest green share of the plant and the value anchor of the fan',
  },
  bladeLight: {
    type: 'color', default: '#93c46a', label: 'Light blades',
    describe: 'albedo of the lighter blades (blade 1, 3, 5 ...), interleaved by azimuth so the fan never reads as one flat sheet of green; keep it a clear value step off the dark blades or the three straps fuse into one leaf mass at distance',
  },
  head: {
    type: 'color', default: '#75563b', label: 'Seed head',
    describe: 'albedo of the brown sausage seed head, the single feature that says cattail; the only warm mass on the plant and the thing the eye lands on first',
  },
  fluff: {
    type: 'color', default: '#e0d2b4', label: 'Seed fluff',
    describe: 'albedo of the burst seed down on the upper half of the head. Only built at stage seeding; at stage mature and young the head is solid brown and this zone is absent from the mesh',
  },
  stage: {
    type: 'choice', default: 'mature', affects: 'geometry',
    options: ['young', 'mature', 'seeding'],
    label: 'Stage',
    describe: 'where in its season this reed stands, as real geometry on the same stalk and the same blade fan. young = a slim unripe spike, the head 25% shorter and 28% narrower, the plant reading almost all stalk; mature (default) = the approved fat 3.75:1 brown sausage; seeding = the head burst open, its upper half flared out to 1.55x the ripe diameter in ragged seeded facets and painted with the fluff zone, the widest and busiest silhouette. Triangle count moves at every step',
  },
  height: {
    type: 'range', default: 1.2, min: 0.85, max: 1.25, label: 'Height', affects: 'geometry',
    describe: 'overall height of the reed in metres, its defining dimension. REBUILT, not scaled: the stalk\'s ring pitch is held at 0.22 m and the blades\' segment pitch at 0.12 m, so a taller plant gains real cross-section rings (triangle count moves) while the stalk\'s and blades\' SECTIONS stay exactly put — a 0.85 m reed is a stubby bank plant of proportionally fatter straps, a 1.25 m one a lanky stand-out. The head rides the stalk and grows with it at a damped rate, so a short reed never carries a comically large sausage',
  },
  headLength: {
    type: 'range', default: 0.315, min: 0.2, max: 0.42, label: 'Head length', affects: 'geometry',
    describe: 'length of the seed head in metres at the default plant height, measured along the stalk (its diameter does not change, so this is the head\'s slenderness). REBUILT: the rounded shoulders are fixed and the straight middle gains rings at a 0.05 m pitch, so a long head is as smooth as a short one. 0.2 = a stubby 2.4:1 acorn barely wider than it is long; 0.315 = the approved 3.75:1 sausage; 0.42 = a long 5:1 spike reaching a third of the way down the stalk',
  },
  blades: {
    type: 'range', default: 3, min: 1, max: 6, label: 'Blades', affects: 'geometry',
    describe: 'how many leaf blades rise from the base (integer 1-6). Blades are placed at an even azimuth pitch plus a hand-authored per-blade deviation, and lengths, widths and the dark/light tone alternation cycle through the same authored table, so the fan stays irregular and two-toned at every count. 1 = a bare single-bladed shoot, 3 = the approved reed, 6 = a dense clump whose fan nearly closes the silhouette',
  },
  spread: {
    type: 'range', default: 1, min: 0.5, max: 1.6, label: 'Spread', affects: 'geometry',
    describe: 'how far the blades splay from the stalk, as a multiplier on each blade\'s tip tilt (the blades stay dead vertical at the root at every value, so the plant keeps its flat bottom). 0.5 = a tight upright bundle barely wider than the head, footprint ~0.24 m; 1.0 = the approved fan, ~0.45 m across; 1.6 = a wide arching splay ~0.68 m across, a reed leaning out over open water',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['stalk', 'bladeDark', 'bladeLight', 'head', 'fluff'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['summer-green'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? COLORWAYS['summer-green'][k]) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prng(seed = 1) {
  let s = seed % 2147483647; if (s <= 0) s += 2147483646;
  const f = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 6; i++) f();
  return f;
}

const STALK_SEG = 6;
function stalkAxis(H, bow) {
  const t = (y) => clamp(y / H, 0, 1);
  return (y) => bow * Math.pow(t(y), 2.2);
}
function stalkRadius(H) {
  return (y) => 0.011 - 0.0035 * clamp(y / H, 0, 1);
}

function ring(cx, y, r, segs, phase = 0, jit = null) {
  const out = [];
  for (let i = 0; i < segs; i++) {
    const a = phase + (i / segs) * Math.PI * 2;
    const rr = jit ? r * jit(i) : r;
    out.push([cx + Math.cos(a) * rr, y, Math.sin(a) * rr]);
  }
  return out;
}

function tubeWalls(rings, colOf, buckets) {
  for (let i = 0; i < rings.length - 1; i++) {
    const out = buckets(colOf(i));
    const a = rings[i], b = rings[i + 1], n = a.length;
    for (let e = 0; e < n; e++) quad(out, a[e], b[e], b[(e + 1) % n], a[(e + 1) % n]);
  }
}

function capDown(out, r) {
  const c = [r.reduce((s, p) => s + p[0], 0) / r.length, r[0][1], r.reduce((s, p) => s + p[2], 0) / r.length];
  for (let i = 0; i < r.length; i++) tri(out, c, r[i], r[(i + 1) % r.length]);
}
function capUp(out, r) {
  const c = [r.reduce((s, p) => s + p[0], 0) / r.length, r[0][1], r.reduce((s, p) => s + p[2], 0) / r.length];
  for (let i = 0; i < r.length; i++) tri(out, c, r[(i + 1) % r.length], r[i]);
}

const HEAD_ROWS = {

  solid:   [[0, 0.16], [0.045, 0.55], [0.115, 0.92], [0.26, 1.0], [0.74, 1.0], [0.885, 0.92], [0.955, 0.55], [1, 0.16]],

  seeding: [[0, 0.16], [0.045, 0.55], [0.115, 0.92], [0.26, 1.0], [0.46, 1.02], [0.58, 1.36],
            [0.70, 1.62], [0.80, 1.70], [0.89, 1.58], [0.96, 1.22], [1, 0.58]],
};
const HEAD_SEG = 8;
const ROW_PITCH = 0.05;

function densify(rows, L) {
  const out = [rows[0]];
  for (let i = 1; i < rows.length; i++) {
    const [s0, r0] = rows[i - 1], [s1, r1] = rows[i];
    const k = Math.floor(((s1 - s0) * L) / ROW_PITCH);
    for (let j = 1; j <= k; j++) {
      const f = j / (k + 1);
      out.push([s0 + (s1 - s0) * f, r0 + (r1 - r0) * f]);
    }
    out.push(rows[i]);
  }
  return out;
}

const BLADES = [
  { dev:   0.0, tilt: 32, len: 0.84, w: 0.048, r: 0.014, tw:  10, tone: 0 },
  { dev:   0.0, tilt: 36, len: 0.70, w: 0.044, r: 0.016, tw: -13, tone: 1 },
  { dev:  -7.0, tilt: 29, len: 0.62, w: 0.041, r: 0.013, tw:  12, tone: 0 },
  { dev:  12.0, tilt: 39, len: 0.77, w: 0.046, r: 0.015, tw: -11, tone: 1 },
  { dev:  -9.0, tilt: 26, len: 0.58, w: 0.039, r: 0.012, tw:  14, tone: 0 },
  { dev:   8.0, tilt: 34, len: 0.66, w: 0.043, r: 0.017, tw:  -9, tone: 1 },
];

const BLADE_PHASE = 35;
const BLADE_PITCH = 0.095;
const KEEL = 0.40;
const BEND = 1.25;

function widthAt(t) {
  const strap = Math.pow(Math.max(0, 1 - t * t), 0.55);
  const u = Math.min(1, t / 0.15);
  return strap * (0.55 + 0.45 * u * u * (3 - 2 * u));
}

function blade(out, b, az, len, tiltDeg, seg, hex) {
  const azR = az * DEG;
  const O = new THREE.Vector3(Math.cos(azR), 0, Math.sin(azR));
  const UP = new THREE.Vector3(0, 1, 0);
  const p = O.clone().multiplyScalar(b.r);

  const P = [], D = [];
  const step = len / seg;
  for (let i = 0; i <= seg; i++) {
    const t = i / seg;
    const a = tiltDeg * DEG * Math.pow(t, BEND);
    const d = O.clone().multiplyScalar(Math.sin(a)).addScaledVector(UP, Math.cos(a));
    P.push(p.clone()); D.push(d.clone());
    if (i < seg) p.addScaledVector(d, step);
  }

  const rings = [];
  for (let i = 0; i < seg; i++) {
    const t = i / seg;
    const w = b.w * widthAt(t);
    const k = w * KEEL;
    const d = D[i];
    const W = new THREE.Vector3(-Math.sin(azR), 0, Math.cos(azR));
    W.applyAxisAngle(d, b.tw * DEG * t).normalize();
    const K = new THREE.Vector3().crossVectors(d, W).normalize();
    const c0 = P[i];
    rings.push([
      c0.clone().addScaledVector(W, w / 2).toArray(),
      c0.clone().addScaledVector(K, k).toArray(),
      c0.clone().addScaledVector(W, -w / 2).toArray(),
    ]);
  }

  const pos = [];
  tri(pos, rings[0][2], rings[0][1], rings[0][0]);
  for (let i = 0; i < seg - 1; i++) {
    for (let e = 0; e < 3; e++) {
      quad(pos, rings[i][e], rings[i][(e + 1) % 3], rings[i + 1][(e + 1) % 3], rings[i + 1][e]);
    }
  }
  const apex = P[seg].toArray();
  for (let e = 0; e < 3; e++) tri(pos, rings[seg - 1][e], rings[seg - 1][(e + 1) % 3], apex);
  out.push({ g: posGeo(pos), c: hex });
}

const DEFAULTS = { colorway: 'summer-green', stage: 'mature', height: 1.2, headLength: 0.315, blades: 3, spread: 1 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const stage = ['young', 'mature', 'seeding'].includes(String(o.stage)) ? String(o.stage) : 'mature';

  const H = clamp(num(o.height, 1.2), 0.85, 1.25);
  const n = Math.round(clamp(num(o.blades, 3), 1, 6));
  const spread = clamp(num(o.spread, 1), 0.5, 1.6);
  const sc = H / 1.2;

  let headL = clamp(num(o.headLength, 0.315), 0.2, 0.42) * Math.pow(sc, 0.6);
  let headR = 0.042 * Math.pow(sc, 0.4);
  if (stage === 'young') { headL *= 0.75; headR *= 0.72; }

  const bow = 0.020 * sc;
  const axis = stalkAxis(H, bow);
  const rad = stalkRadius(H);
  const tipLen = 0.06 * sc;
  const headTop = H - tipLen;
  const headBot = headTop - headL;

  const T = new Map();
  const bucket = (hex) => { let a = T.get(hex); if (!a) T.set(hex, a = []); return a; };

  {
    const bands = Math.max(4, Math.round(H / 0.22));
    const rings = [];
    for (let i = 0; i <= bands; i++) {
      const y = (i / bands) * H;
      rings.push(ring(axis(y), y, rad(y), STALK_SEG));
    }
    const out = bucket(C.stalk);
    tubeWalls(rings, () => C.stalk, bucket);
    capDown(out, rings[0]);
    capUp(out, rings[bands]);
  }

  {
    const rows = densify(HEAD_ROWS[stage === 'seeding' ? 'seeding' : 'solid'], headL);
    const rnd = prng(1607);
    const rings = [], isFluff = [];
    for (let i = 0; i < rows.length; i++) {
      const [s, rf] = rows[i];
      const y = headBot + s * headL;

      const ragged = stage === 'seeding' && s >= 0.45;
      const jit = ragged ? Array.from({ length: HEAD_SEG }, () => 0.78 + 0.48 * rnd()) : null;
      const ph = Math.PI / HEAD_SEG + (ragged ? (rnd() - 0.5) * 0.55 : 0);
      rings.push(ring(axis(y), y, headR * rf, HEAD_SEG, ph, jit && ((e) => jit[e])));
      isFluff.push(stage === 'seeding' && s >= 0.5);
    }

    tubeWalls(rings, (i) => (isFluff[i + 1] ? C.fluff : C.head), bucket);

    const capEnd = (r, y, rf, up) => {
      if (headR * rf <= rad(y) - 0.0005) return;
      const out = bucket(up && stage === 'seeding' ? C.fluff : C.head);
      if (up) capUp(out, r); else capDown(out, r);
    };
    capEnd(rings[0], headBot, rows[0][1], false);
    capEnd(rings[rings.length - 1], headTop, rows[rows.length - 1][1], true);
  }

  const parts = [];
  const pitch = 360 / n;
  for (let j = 0; j < n; j++) {
    const b = BLADES[j % BLADES.length];
    const az = BLADE_PHASE + pitch * j + b.dev;
    const len = b.len * H;

    const seg = clamp(Math.round(len / BLADE_PITCH), 4, 10);
    blade(parts, b, az, len, clamp(b.tilt * spread, 6, 60), seg, b.tone ? C.bladeLight : C.bladeDark);
  }
  for (const [hex, pos] of T) if (pos.length) parts.push({ g: posGeo(pos), c: hex });

  const mesh = finish(parts);
  mesh.name = 'cattail-reed-mesh';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const g = new THREE.Group();
  g.name = 'cattail-reed';
  g.add(mesh);
  return g;
}

export default createAsset;
