/*
 * Crater Terrain Blob
 * https://polyfork.dev/asset/crater-terrain-blob-bd6af6
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './crater-terrain-blob-bd6af6.mjs';
 *   scene.add(createAsset());
 *
 * PARAMETRIC  createAsset(opts) reshapes and recolors the patch. Read the
 * machine-readable schema from the module itself:
 *
 *   import { createAsset, params, presets, rig, detach, night } from './...mjs';
 *   scene.add(createAsset({ colorway: 'ashen-basalt', spread: 1.2,
 *                           relief: 1.3, craterWidth: 0.85, centralPeak: true }));
 *
 * createAsset() with no arguments is exactly the model in the store renders.
 * Every knob's 'describe' says what it changes and what its extremes look like.
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
 * SPECS  400 triangles at the defaults (320-521 across the knob range),
 *        1 material, 7.21 x 0.79 x 6.5 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'rust-regolith':   { regolith: 0xb2684b, subsoil: 0x975b44, dust: 0xac7c64, dustPool: 0xc1a078 },
  'ashen-basalt':    { regolith: 0x5f6570, subsoil: 0x3d3f47, dust: 0x737785, dustPool: 0x989ea7 },
  'dark-mare':       { regolith: 0x5b4337, subsoil: 0x3e2f2b, dust: 0x73594d, dustPool: 0x856f5d },
  'weathered-ochre': { regolith: 0x856f5d, subsoil: 0x73594d, dust: 0xac7c64, dustPool: 0xc1a078 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'rust-regolith', label: 'Colorway',
    options: ['rust-regolith', 'ashen-basalt', 'dark-mare', 'weathered-ochre'],
    describe: 'curated ground scheme, all four tones off the kit menu: rust-regolith is the warm martian rust of the default, ashen-basalt a cool grey volcanic plain, dark-mare a dark brown basaltic sea, weathered-ochre a dull ochre dust flat. Sets all four zone albedos at once; an explicit colour knob overrides it',
  },
  regolith: {
    type: 'color', default: '#b2684b', label: 'Regolith',
    describe: 'albedo of the dominant ground mass — flat outer skirt, ejecta apron, rim crest and the underside. About 65% of the triangles',
  },
  subsoil: {
    type: 'color', default: '#975b44', label: 'Crater wall',
    describe: 'albedo of the steep inner crater wall (freshly excavated subsoil) and of the central peak when it is switched on. Darkest zone; keep it below the regolith in value or the bowl stops reading as excavated',
  },
  dust: {
    type: 'color', default: '#ac7c64', label: 'Bowl floor',
    describe: 'albedo of the flat dusty bowl floor band ringing the centre of the crater',
  },
  dustPool: {
    type: 'color', default: '#c1a078', label: 'Dust pool',
    describe: 'albedo of the pale settled dust at the very centre of the bowl — the lightest tone on the asset, which is what stops the depression reading as a shadow',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.78, max: 1.25, label: 'Spread', icon: '↔️', affects: 'geometry',
    describe: 'overall size of the ground patch: 0.78 is a ~5.6 m pothole crater, 1.0 the 7.2 m default, 1.25 a ~9.0 m impact field. REBUILT, not scaled — the sector count follows at a fixed ~1.1 m facet pitch (16 sectors at 0.78, 20 at 1.0, 25 at 1.25, so triangles run 320-500 and the footprint quantizes in ~0.36 m steps), and every height above the 0.05 m skirt scales with it so the slope angles stay constant. The skirt itself stays at the kit standard 0.05 m at every value',
  },
  relief: {
    type: 'range', default: 1.0, min: 0.62, max: 1.45, label: 'Relief', icon: '⛰️', affects: 'geometry',
    describe: 'vertical relief of the crater — rim crest height above the brim and bowl depth together, plus the sector-to-sector undulation of the crest. 0.62 is a worn shallow scar about 0.51 m tall, 1.0 the 0.79 m default, 1.45 a proud volcano-like mound about 1.12 m tall. Footprint and the 0.05 m skirt are unchanged, so this knob only steepens or flattens the slopes',
  },
  craterWidth: {
    type: 'range', default: 1.0, min: 0.75, max: 1.25, label: 'Crater width', icon: '⭕', affects: 'geometry',
    describe: 'how much of the patch the bowl eats: the crater mouth goes from ~2.6 m (a tight pit in a broad ejecta field) through the 3.5 m default to ~4.4 m (a wide open bowl with a narrow rim). The apron rings blend between the fixed outer skirt and the mouth so the profile stays monotonic at every value',
  },
  centralPeak: {
    type: 'toggle', default: false, label: 'Central peak', icon: '🔺', affects: 'geometry',
    describe: 'optional rebound peak in the middle of the bowl — a 7-sided faceted uplift mound in the darker crater-wall colour, ~1.1 m across and 78% of the bowl depth tall, bedded 20 mm into the floor so it never floats and always stopping short of the rim crest. Off (the default) leaves the floor a flat dust pool. Adds 21 triangles',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

const r4 = (x) => Math.round(x * 1e4) / 1e4;

const ZONE_KEYS = ['regolith', 'subsoil', 'dust', 'dustPool'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['rust-regolith'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.regolith) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}

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
function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const SEG0 = 20;
const BASE_R0 = 3.50;
const SKIRT_Y = 0.05;
const RINGS = [

  { r: 1.000, y: 0.000, rj: 0.000, yj: 0.000 },
  { r: 0.972, y: 0.050, rj: 0.010, yj: 0.000 },
  { r: 0.845, y: 0.058, rj: 0.020, yj: 0.014 },
  { r: 0.762, y: 0.265, rj: 0.012, yj: 0.095 },
  { r: 0.665, y: 0.495, rj: 0.012, yj: 0.105 },
  { r: 0.565, y: 0.700, rj: 0.012, yj: 0.080 },
  { r: 0.500, y: 0.680, rj: 0.012, yj: 0.080 },
  { r: 0.440, y: 0.360, rj: 0.012, yj: 0.055 },
  { r: 0.395, y: 0.170, rj: 0.012, yj: 0.022 },
  { r: 0.215, y: 0.140, rj: 0.010, yj: 0.000 },
];

const BAND_ZONE = ['skirt', 'skirt', 'apron', 'apron', 'apron', 'crest', 'wall', 'wall', 'floor'];
const ZONE_OF = { skirt: 'regolith', apron: 'regolith', crest: 'regolith', wall: 'subsoil', floor: 'dust' };

function ringR(k, cwid) {
  const w = clamp((k - 3) / 3, 0, 1);
  return r4(RINGS[k].r * (1 + (cwid - 1) * w));
}

function ringY(k, vs) {
  return k < 2 ? RINGS[k].y : r4(SKIRT_Y + (RINGS[k].y - SKIRT_Y) * vs);
}

function buildGrid(SEG, baseR, vs, cwid) {
  const rand = prng(20260722);

  const outer = [], inner = [], crest = [];
  for (let i = 0; i < SEG; i++) {
    const a = (i / SEG) * Math.PI * 2;
    outer.push(1 + 0.050 * Math.sin(2.0 * a + 0.7) + 0.034 * Math.sin(3.0 * a + 2.4)
                 + 0.022 * Math.sin(5.0 * a + 4.1) + (rand() - 0.5) * 0.022);
    inner.push(1 + 0.055 * Math.sin(3.0 * a + 1.9) + 0.035 * Math.sin(4.0 * a + 3.3)
                 + (rand() - 0.5) * 0.026);

    crest.push((0.058 * Math.sin(3.0 * a + 0.4) + 0.040 * Math.sin(5.0 * a + 2.8)
                 + (rand() - 0.5) * 0.030) * vs);
  }

  const grid = [];
  for (let k = 0; k < RINGS.length; k++) {
    const R = RINGS[k];
    const rk = ringR(k, cwid), yk = ringY(k, vs), yjk = R.yj * vs;
    const t = k / (RINGS.length - 1);              // 0 = outline, 1 = bowl floor
    const ring = [];
    for (let i = 0; i < SEG; i++) {
      const a = (i / SEG) * Math.PI * 2;
      const lobe = outer[i] * (1 - t) + inner[i] * t;
      const rr = baseR * rk * lobe * (1 + (rand() - 0.5) * R.rj);

      const crestW = Math.max(0, 1 - Math.abs(k - 5.5) / 3.5);
      const yy = yk + crest[i] * crestW + (rand() - 0.5) * yjk;
      ring.push([Math.cos(a) * rr, Math.max(0, yy), Math.sin(a) * rr * 0.955]);
    }
    grid.push(ring);
  }
  return grid;
}

const DEFAULTS = { colorway: 'rust-regolith', spread: 1.0, relief: 1.0, craterWidth: 1.0, centralPeak: false };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const spread = clamp(num(o.spread, 1), 0.78, 1.25);
  const relief = clamp(num(o.relief, 1), 0.62, 1.45);
  const cwid = clamp(num(o.craterWidth, 1), 0.75, 1.25);
  const peakOn = o.centralPeak === true || o.centralPeak === 'true' || o.centralPeak === 1;

  const SEG = Math.round(SEG0 * spread);
  const baseR = r4(BASE_R0 * spread);
  const vs = spread * relief;

  const g = new THREE.Group();
  g.name = 'crater-terrain-blob';

  const grid = buildGrid(SEG, baseR, vs, cwid);
  const buckets = new Map();
  const push = (hex) => { if (!buckets.has(hex)) buckets.set(hex, []); return buckets.get(hex); };

  const emit = (a, b, c, hex) => tri(push(hex), a, b, c);

  for (let k = 0; k < RINGS.length - 1; k++) {
    const hex = C[ZONE_OF[BAND_ZONE[k]]];
    for (let i = 0; i < SEG; i++) {
      const j = (i + 1) % SEG;
      const v00 = grid[k][i], v01 = grid[k][j], v10 = grid[k + 1][i], v11 = grid[k + 1][j];

      if ((i + k) % 2 === 0) {
        emit(v00, v10, v11, hex); emit(v00, v11, v01, hex);
      } else {
        emit(v00, v10, v01, hex); emit(v01, v10, v11, hex);
      }
    }
  }

  const floorY = ringY(RINGS.length - 1, vs);
  const centre = [0, floorY, 0];
  const last = grid[grid.length - 1];
  for (let i = 0; i < SEG; i++) {

    emit(last[i], centre, last[(i + 1) % SEG], C.dustPool);
  }

  if (peakOn) {
    const prand = prng(7314);
    const depth = ringY(5, vs) - floorY;
    const h = r4(0.78 * depth);
    const pr = 0.72 * baseR * ringR(RINGS.length - 1, cwid);
    const PSEG = 7;
    const base = [], mid = [];
    for (let i = 0; i < PSEG; i++) {
      const a = (i / PSEG) * Math.PI * 2 + 0.35;
      const j1 = 1 + (prand() - 0.5) * 0.22;
      const j2 = 1 + (prand() - 0.5) * 0.20;
      const r1 = pr * j1, r2 = pr * 0.52 * j2;

      base.push([Math.cos(a) * r1, floorY - 0.02, Math.sin(a) * r1 * 0.955]);
      mid.push([Math.cos(a) * r2, floorY + h * 0.62, Math.sin(a) * r2 * 0.955]);
    }
    const apex = [0, floorY + h, 0];
    for (let i = 0; i < PSEG; i++) {
      const j = (i + 1) % PSEG;
      emit(base[i], mid[i], mid[j], C.subsoil);
      emit(base[i], mid[j], base[j], C.subsoil);
      emit(mid[i], apex, mid[j], C.subsoil);
    }
  }

  const under = [0, 0, 0];
  const rim = grid[0];
  for (let i = 0; i < SEG; i++) {
    const j = (i + 1) % SEG;
    emit(under, [rim[i][0], 0, rim[i][2]], [rim[j][0], 0, rim[j][2]], C.regolith);
  }

  const parts = [];
  for (const [hex, pos] of buckets) parts.push({ g: posGeo(pos), c: hex });
  const mesh = finish(parts);
  mesh.name = 'regolith';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  g.add(mesh);
  return g;
}

export default createAsset;
