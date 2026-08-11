/*
 * Round Path Stone
 * https://polyfork.dev/asset/round-path-stone-4130f3
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './round-path-stone-4130f3.mjs';
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
 *   colorway    choice  'river-grey'   'river-grey' | 'granite' | 'basalt' | 'sandstone'
 *   stone       color   '#a3a099'      any hex or THREE.Color
 *   width       range   0.7            0.45 to 0.75
 *   sides       range   7              5 to 8
 *   crown       range   0.35           0 to 1
 *   elongation  range   0.82           0.55 to 1
 *   ruggedness  range   0.6            0 to 1
 *   seed        range   3              1 to 8
 *
 * Every option is described in full at https://polyfork.dev/cdn/round-path-stone-4130f3-params.json
 *
 * SPECS  52 triangles, 1 material, 0.7 x 0.06 x 0.57 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const TAU = Math.PI * 2;

const H = 0.058;

const COLORWAYS = {
  'river-grey': { stone: '#a3a099' },
  'granite':    { stone: '#87847c' },
  'basalt':     { stone: '#57544e' },
  'sandstone':  { stone: '#e0d2b4' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'river-grey', label: 'Colorway',
    options: ['river-grey', 'granite', 'basalt', 'sandstone'],
    describe: 'Curated stone types from the kit palette. river-grey is the shipped mid ' +
      'grey; granite is one value step darker; basalt is near-black shaded rock for ' +
      'forest floor; sandstone is a pale warm cream. A rock is ONE material, so the ' +
      'colorway sets the whole slab.',
  },
  stone: {
    type: 'color', default: '#a3a099', label: 'Stone',
    describe: 'Albedo of the entire slab — top facet, crown chamfer, belly, foot and ' +
      'underside. This asset has exactly one colour zone by design (BUILD 8bc).',
  },
  width: {
    type: 'range', default: 0.70, min: 0.45, max: 0.75, step: 0.01,
    label: 'Width', affects: 'geometry',
    describe: 'Plan size across the long axis, in meters. 0.45 is a chunky cobble, 0.75 ' +
      'a broad flagstone. NOT a uniform scale: thickness stays pinned at the kit path- ' +
      'stone standard of 0.058 m at every value, and the section (belly height, foot ' +
      'inset, chamfer geometry) is rebuilt around it, so a narrow stone reads ' +
      'proportionally thicker and a wide one reads flatter.',
  },
  sides: {
    type: 'range', default: 7, min: 5, max: 8, step: 1,
    label: 'Sides', affects: 'geometry',
    describe: 'Number of planes around the outline (BUILD 8bc allows 5-8). 5 is a blunt, ' +
      'strongly angular shard; 8 is a rounder river pebble. Triangle count follows ' +
      'directly: 8*sides-4, so 36 tris at 5 and 60 at 8.',
  },
  crown: {
    type: 'range', default: 0.35, min: 0, max: 1, step: 0.05,
    label: 'Crown', affects: 'geometry',
    describe: 'How domed the stone is. 0 is a flat-topped flagstone: a broad top plate ' +
      'over a tall near-vertical rim. 1 is a rounded pebble: a small top facet over a ' +
      'steep crown chamfer that starts low on the section. The dome eats into the rim ' +
      'rather than adding to it, so total height never leaves 0.058 m.',
  },
  elongation: {
    type: 'range', default: 0.82, min: 0.55, max: 1.0, step: 0.01,
    label: 'Elongation', affects: 'geometry',
    describe: 'Plan aspect: depth as a fraction of width. 1.0 is an equidimensional ' +
      'pebble, 0.55 a distinctly oval stepping slab that wants to be laid across a path.',
  },
  ruggedness: {
    type: 'range', default: 0.6, min: 0, max: 1, step: 0.05,
    label: 'Ruggedness', affects: 'geometry',
    describe: 'How irregular the outline is. 0 gives an even polygon — a cut flagstone ' +
      'paver. 1 swings the radius +/-15% and jitters the corner spacing for a wonky, ' +
      'hand-hewn natural stone with no two edges alike.',
  },
  seed: {
    type: 'range', default: 3, min: 1, max: 8, step: 1,
    label: 'Seed', affects: 'geometry',
    describe: 'Which stone this is. Each whole value is a different outline and a ' +
      'different off-centre top facet at the same size and section, so a consumer can ' +
      'pave a run out of eight distinct slabs instead of eight copies of one.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) {
  let s = (seed | 0) % 2147483647;
  if (s <= 0) s += 2147483646;
  const r = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 8; i++) r();
  return r;
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

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

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function resolve(p) {
  const out = {};
  for (const k in params) out[k] = params[k].default;
  const cw = (p.colorway !== undefined && COLORWAYS[p.colorway]) ? p.colorway : out.colorway;
  out.colorway = cw;
  Object.assign(out, COLORWAYS[cw]);
  for (const k in p) if (p[k] !== undefined && p[k] !== null) out[k] = p[k];

  out.width      = clamp(+out.width, 0.30, 1.20);
  out.sides      = clamp(Math.round(+out.sides), 5, 8);
  out.crown      = clamp(+out.crown, 0, 1);
  out.elongation = clamp(+out.elongation, 0.45, 1.2);
  out.ruggedness = clamp(+out.ruggedness, 0, 1);
  out.seed       = clamp(Math.round(+out.seed), 1, 64);
  return out;
}

function planOutline(P, rand) {
  const n = P.sides;
  const ph = [rand() * TAU, rand() * TAU, rand() * TAU];
  const jit = [];
  for (let i = 0; i < n; i++) jit.push(rand() - 0.5);

  const pts = [];
  for (let i = 0; i < n; i++) {

    const t = (i / n) * TAU + jit[i] * (TAU / n) * 0.30 * P.ruggedness;
    const w = 0.15 * Math.sin(2 * t + ph[0])
            + 0.10 * Math.sin(3 * t + ph[1])
            + 0.06 * Math.sin(5 * t + ph[2]);
    const r = 1 + P.ruggedness * w;
    pts.push([Math.cos(t) * r, -Math.sin(t) * r]);
  }

  let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
  for (const [x, z] of pts) {
    if (x < x0) x0 = x; if (x > x1) x1 = x;
    if (z < z0) z0 = z; if (z > z1) z1 = z;
  }

  const cx = (x0 + x1) / 2, cz = (z0 + z1) / 2;
  const kx = P.width / (x1 - x0), kz = (P.width * P.elongation) / (z1 - z0);
  return pts.map(([x, z]) => [(x - cx) * kx, (z - cz) * kz]);
}

function slab(P, rand) {
  const plan = planOutline(P, rand);
  const n = plan.length;
  const c = P.crown;
  const R = P.width / 2;

  const ang = rand() * TAU;
  const dx = Math.cos(ang) * 0.05 * R, dz = Math.sin(ang) * 0.05 * R;

  const rings = [
    { y: 0,                        s: 0.86,            ox: 0,          oz: 0 },
    { y: H * 0.28,                 s: 1.00,            ox: 0,          oz: 0 },
    { y: H * (0.60 - 0.20 * c),    s: 0.97,            ox: dx * 0.3,   oz: dz * 0.3 },
    { y: H,                        s: 0.88 - 0.20 * c, ox: dx,         oz: dz },
  ];

  const V = rings.map((r) => plan.map(([x, z]) => [x * r.s + r.ox, r.y, z * r.s + r.oz]));

  const pos = [];

  for (let i = 1; i < n - 1; i++) tri(pos, V[0][0], V[0][i + 1], V[0][i]);

  for (let b = 0; b < 3; b++) {
    const L = V[b], U = V[b + 1];
    for (let k = 0; k < n; k++) {
      const j = (k + 1) % n;
      quad(pos, L[k], L[j], U[j], U[k]);
    }
  }

  for (let i = 1; i < n - 1; i++) tri(pos, V[3][0], V[3][i], V[3][i + 1]);

  return posGeo(pos);
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const rand = prng(P.seed * 7919 + 13);

  const g = new THREE.Group();
  g.name = 'round-path-stone';

  const mesh = finish([{ g: slab(P, rand), c: P.stone }]);
  mesh.name = 'stone';
  g.add(mesh);

  return g;
}

export default createAsset;
