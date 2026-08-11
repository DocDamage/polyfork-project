/*
 * Small Rock
 * https://polyfork.dev/asset/small-rock-d43710
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './small-rock-d43710.mjs';
 *   scene.add(createAsset());
 *
 * CUSTOMIZE  every knob is optional; createAsset() with no arguments is the
 * rock you see in the store renders.
 *
 *   createAsset({
 *     colorway: 'dark-slate',  // granite-grey | dark-slate | pale-limestone
 *                              // warm-sandstone | lichen-green
 *     stone:    '#a7a395',     // the single stone albedo (overrides colorway)
 *     facets:   'standard',    // coarse (20 tris) | standard (80) | fine (180)
 *     craggy:   1,             // 0 smooth pebble .. 1.8 violently wonky
 *     shape:    'a',           // a | b | c | d — four different boulders
 *     crown:    0,             // 0 domed .. 1 sheared flat on top
 *     baseTuck: 1,             // 0.3 bedded wide .. 1.7 perched, undercut
 *   });
 *
 *   import { params, presets, night } from './small-rock-d43710.mjs';
 *
 * `params` is the machine-readable schema (types, ranges, descriptions),
 * `presets` the colorway table, `night` what glows after dark — nothing on a
 * rock does, so it is deliberately an empty map.
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
 * SPECS  80 triangles (20-180 across the facet knob), 1 material,
 *        0.52 x 0.36 x 0.46 m (real-world scale) at every knob value.
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const STONE_GREY = 0xa7a395;

// One material means one colour, so a colorway here picks a STONE TYPE.
export const COLORWAYS = {
  'granite-grey':   { stone: STONE_GREY },
  'dark-slate':     { stone: 0x676b6c },
  'pale-limestone': { stone: 0xc9c1ac },
  'warm-sandstone': { stone: 0xa58e6d },
  'lichen-green':   { stone: 0x929677 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'granite-grey', label: 'Colorway',
    options: ['granite-grey', 'dark-slate', 'pale-limestone', 'warm-sandstone', 'lichen-green'],
    describe: 'which STONE this is — the rock has one material, so a colorway picks a rock type, not a paint scheme: granite-grey warm mid grey (default), dark-slate near-black blue-grey for wet or volcanic ground, pale-limestone bleached chalky grey for dry ground, warm-sandstone tan desert stone, lichen-green grey-green for damp woodland. Pick by the terrain the rock is scattered on',
  },
  stone: {
    type: 'color', default: '#a7a395', label: 'Stone',
    describe: 'albedo of every facet on the boulder. This asset deliberately has exactly ONE colour zone — a rock is one material, and all the facet-to-facet tone difference in the renders is the scene lights on baked flat normals, never painted tone. Changing this recolours the whole rock',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facet density', icon: '💠', affects: 'geometry',
    options: ['coarse', 'standard', 'fine'],
    describe: 'how many planes the boulder is cut from: coarse = 20 big triangles, a blunt hand-hewn chunk with 5-6 planes per view (best at small scatter sizes); standard = 80 triangles, the approved rock; fine = 180 triangles, a finer-grained weathered stone that still reads faceted. Triangle count follows exactly (20 / 80 / 180 against an 800 budget)',
  },
  craggy: {
    type: 'range', default: 1, min: 0, max: 1.8, label: 'Cragginess', icon: '🪨', affects: 'geometry',
    describe: 'amplitude of the lobe field that pushes the facets in and out, scaling both the lobe waves and the clamp window they ride in: 0 = a smooth waterworn pebble with an almost regular rounded outline, 1 = the approved boulder with a couple of corner bulges, 1.8 = a violently wonky hewn rock with deep pinches between big proud lobes. The bounding box is held at 0.52 x 0.36 x 0.46 m at every value, so this changes the outline, not the size',
  },
  shape: {
    type: 'choice', default: 'a', label: 'Boulder shape', icon: '🎲', affects: 'geometry',
    options: ['a', 'b', 'c', 'd'],
    describe: 'which of four hand-tuned lobe fields carves the rock — four genuinely different boulders (a = the approved one, bulging toward +Z; b = a long flank bulge on -X with a pinched back; c = a broad-shouldered squarish block; d = a lopsided wedge riding high on one corner) at the identical footprint, height and origin, so a scatter can mix them without any of them looking like the same mesh at another yaw',
  },
  crown: {
    type: 'range', default: 0, min: 0, max: 1, label: 'Flat crown', icon: '⬜', affects: 'geometry',
    describe: 'shears the top of the boulder off on a level plane, the way a weathered stone breaks along a bed: 0 = the approved domed crown, 0.5 = a broad flat table facet across the top fifth, 1 = a block sheared at 60% of its height that a villager could sit on or use as a stepping stone. The rock is re-normalised to the same bounding box afterwards, so a sheared crown gets wider rather than shorter',
  },
  baseTuck: {
    type: 'range', default: 1, min: 0.3, max: 1.7, label: 'Base tuck', icon: '🔻', affects: 'geometry',
    describe: 'how far the flat underside is drawn in under the belly, measured as the base radius against the widest ring: 0.3 = 89%, an almost full-width base that reads half-buried and bedded into the ground; 1 = the approved 52% tuck, belly clearly overhanging its footprint; 1.7 = 35%, a strongly undercut boulder perched on a small pad as if it had just been rolled out. The base stays a single level plane on y=0 at every value, so the rock still sits stably at any yaw',
  },
};

export const rig = {};      // a boulder has no moving parts
export const detach = [];   // nothing on it is removable
export const night = {};    // stone emits nothing after dark

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};

const SIZE_X = 0.52, SIZE_Y = 0.36, SIZE_Z = 0.46;

// [amp, freq, phase] per lobe wave, a broad single-direction lobe, and a jitter seed.
const SHAPES = {
  a: { seed: 20713, w: [[0.195, 2.9, 0.9], [0.145, 2.3, 2.6], [0.160, 3.1, 4.4], [0.115, 2.0, 1.7]],
       dir: [0.115, -0.55, 0.30, 0.78] },
  b: { seed: 51041, w: [[0.185, 2.6, 3.4], [0.150, 2.9, 0.7], [0.150, 2.4, 2.1], [0.125, 1.8, 5.0]],
       dir: [0.130, -0.86, 0.22, -0.46] },
  c: { seed: 33827, w: [[0.170, 3.4, 1.9], [0.130, 2.0, 4.9], [0.175, 2.7, 0.4], [0.100, 2.6, 3.2]],
       dir: [0.100, 0.62, 0.34, 0.71] },
  d: { seed: 71219, w: [[0.205, 2.2, 5.5], [0.160, 3.0, 1.3], [0.140, 2.5, 3.9], [0.130, 2.2, 0.6]],
       dir: [0.140, 0.48, 0.52, -0.71] },
};
const DETAIL = { coarse: 0, standard: 1, fine: 2 };
const DEFAULTS = { colorway: 'granite-grey', facets: 'standard', craggy: 1, shape: 'a', crown: 0, baseTuck: 1 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const cw = COLORWAYS[String(o.colorway)] || COLORWAYS['granite-grey'];
  const stoneHex = hexOf(opts.stone) ?? cw.stone ?? STONE_GREY;
  const detail = DETAIL[String(o.facets)] ?? DETAIL.standard;
  const S = SHAPES[String(o.shape)] || SHAPES.a;
  const cr = clamp(num(o.craggy, 1), 0, 1.8);
  const crown = clamp(num(o.crown, 0), 0, 1);
  const bt = clamp(num(o.baseTuck, 1), 0.3, 1.7);

  const g = new THREE.Group();
  g.name = 'small-rock';

  let geo = new THREE.IcosahedronGeometry(1, detail);
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const pos = geo.attributes.position;

  // 1. LOBES — displacement shared per unique vertex, keyed on the original direction.
  const rand = prng(S.seed);
  const cache = new Map();
  const rLo = cr === 1 ? 0.90 : 1 - 0.10 * cr;
  const rHi = cr === 1 ? 1.20 : 1 + 0.20 * cr;
  const disp = (x, y, z) => {
    const key = `${x.toFixed(4)},${y.toFixed(4)},${z.toFixed(4)}`;
    let r = cache.get(key);
    if (r === undefined) {
      const w = S.w, d = S.dir;
      const lobe =
        w[0][0] * Math.sin(w[0][1] * x + w[0][2]) +
        w[1][0] * Math.sin(w[1][1] * y + w[1][2]) +
        w[2][0] * Math.sin(w[2][1] * z + w[2][2]) +
        w[3][0] * Math.sin(w[3][1] * (x + z) + w[3][2]) +
        d[0] * (0.5 + 0.5 * (x * d[1] + y * d[2] + z * d[3]));
      const jit = (rand() - 0.5) * 0.07;
      r = cr === 1 ? Math.min(rHi, Math.max(rLo, 1 + lobe + jit))
                   : Math.min(rHi, Math.max(rLo, 1 + (lobe + jit) * cr));
      cache.set(key, r);
    }
    return r;
  };
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    const r = disp(x, y, z);
    const rxz = Math.hypot(x, z) || 1e-6;
    const k = Math.pow(rxz, 0.90) / rxz;
    pos.setXYZ(i, x * k * r, Math.sign(y) * Math.pow(Math.abs(y), 0.90) * r, z * k * r);
  }

  // 2. SQUASH to the oblate kit proportion.
  geo.scale(0.255, 0.183, 0.226);

  let minY = Infinity, maxY = -Infinity;
  for (let i = 0; i < pos.count; i++) { const y = pos.getY(i); if (y < minY) minY = y; if (y > maxY) maxY = y; }

  // 2b. OPTIONAL FLAT CROWN — sheared level along a bed (default 0: skipped).
  if (crown > 0) {
    const top = maxY * (1 - 0.40 * crown);
    for (let i = 0; i < pos.count; i++) if (pos.getY(i) > top) pos.setY(i, top);
    maxY = top;
  }

  // 3. FLAT TUCKED BASE — the cut plane rises up the belly below the default, and the
  //    whole foot is drawn in above it, so the footprint reads from every camera.
  const cut = minY * (bt >= 1 ? 0.60 : 0.60 - 0.43 * (1 - bt));
  const tuckAmt = bt === 1 ? 0.34 : 0.34 * (0.5 + 0.5 * bt);
  const pad = bt <= 1 ? 1 : 1 - 0.50 * (bt - 1);
  if (pad !== 1) {
    for (let i = 0; i < pos.count; i++) {
      const y = pos.getY(i);
      if (y < 0) {
        const s = Math.min(1, y / cut);
        const f = 1 - (1 - pad) * s;
        pos.setXYZ(i, pos.getX(i) * f, y, pos.getZ(i) * f);
      }
    }
  }
  for (let i = 0; i < pos.count; i++) {
    const y = pos.getY(i);
    if (y < cut) {
      const t = (cut - y) / (cut - minY);
      const tuck = 1 - tuckAmt * t;
      pos.setXYZ(i, pos.getX(i) * tuck, cut, pos.getZ(i) * tuck);
    }
  }

  // 4. Sit on y=0, centered on x/z, and normalise to the same bounding box at every knob.
  geo.computeBoundingBox();
  let bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  geo.computeBoundingBox();
  bb = geo.boundingBox;
  geo.scale(SIZE_X / (bb.max.x - bb.min.x), SIZE_Y / (bb.max.y - bb.min.y), SIZE_Z / (bb.max.z - bb.min.z));
  geo.computeBoundingBox();
  geo.translate(-(geo.boundingBox.min.x + geo.boundingBox.max.x) / 2, -geo.boundingBox.min.y,
    -(geo.boundingBox.min.z + geo.boundingBox.max.z) / 2);

  // 5. ONE ALBEDO on every facet; the scene lights make the facet-to-facet variation.
  const p = geo.attributes.position;
  const col = new Float32Array(p.count * 3);
  const c = new THREE.Color(stoneHex);
  for (let i = 0; i < p.count; i++) {
    col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));

  geo.computeVertexNormals();
  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'rock-body';
  g.add(mesh);
  return g;
}

export default createAsset;
