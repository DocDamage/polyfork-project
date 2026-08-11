/*
 * Crystal Cluster
 * https://polyfork.dev/asset/crystal-cluster-624138
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './crystal-cluster-624138.mjs';
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
 *   colorway     choice  'cyan-regolith' 'cyan-regolith' | 'amber-regolith' | 'violet-basalt' | 'ice-gunmetal'
 *   rock         color   '#b2684b'      any hex or THREE.Color
 *   matrix       color   '#c1a078'      any hex or THREE.Color
 *   rubble       color   '#975b44'      any hex or THREE.Color
 *   crystal      color   '#7fe9e0'      any hex or THREE.Color
 *   spread       range   1              0.7 to 1.5
 *   facets       range   6              4 to 9
 *   moundWidth   range   1              0.82 to 1.35
 *   pebbles      range   4              0 to 7
 *
 * Every option is described in full at https://polyfork.dev/cdn/crystal-cluster-624138-params.json
 *
 * SPECS  472 triangles, 2 material, 0.92 x 0.8 x 0.81 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'cyan-regolith':  { rock: 0xb2684b, matrix: 0xc1a078, rubble: 0x975b44, crystal: 0x7fe9e0 },
  'amber-regolith': { rock: 0xac7c64, matrix: 0xc1a078, rubble: 0x856f5d, crystal: 0xf2b45c },
  'violet-basalt':  { rock: 0x5b4337, matrix: 0x856f5d, rubble: 0x3e2f2b, crystal: 0xb08cf0 },
  'ice-gunmetal':   { rock: 0x5f6570, matrix: 0x989ea7, rubble: 0x3d3f47, crystal: 0xd8f4fb },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'cyan-regolith', label: 'Colorway',
    options: ['cyan-regolith', 'amber-regolith', 'violet-basalt', 'ice-gunmetal'],
    describe: 'curated kit-coherent scheme, sets all four zone albedos at once. cyan-regolith = the shipped rust boulder with the kit cyan gem; amber-regolith = warmer dust with an astro-orange gem; violet-basalt = dark basalt with a violet gem; ice-gunmetal = grey gunmetal scree with a near-white ice gem',
  },
  rock: {
    type: 'color', default: '#b2684b', label: 'Rock mound',
    describe: 'albedo of the big rust boulder the crystals grow out of — the dominant mass, about 40% of the triangles',
  },
  matrix: {
    type: 'color', default: '#c1a078', label: 'Host-rock cuffs',
    describe: 'albedo of the pale fractured collars where each shaft breaks the mound crown; keep it a clear value step LIGHTER than the mound or the crystals read as inserted rather than grown',
  },
  rubble: {
    type: 'color', default: '#975b44', label: 'Rubble pebbles',
    describe: 'albedo of the loose scree pebbles lying on the ground around the skirt; darker than the mound so the scree reads as separate stones',
  },
  crystal: {
    type: 'color', default: '#7fe9e0', label: 'Crystal',
    describe: 'albedo of every crystal shaft — the second (gem) material, low roughness with a faint emissive. This is the zone the `night` map lights up, so it stays its own zone in every colorway',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.7, max: 1.5, label: 'Splay', affects: 'geometry',
    describe: 'how far the two flanking shafts fan out from the main spire: multiplies their lean (26 deg / 30 deg at 1.0) and how far their roots sit off centre. 0.7 = a tight near-parallel bundle roughly 18/21 deg, 1.5 = a wide 39/45 deg trident that reads from every 90-deg view. Triangle count is unchanged; only the silhouette moves',
  },
  facets: {
    type: 'range', default: 6, min: 4, max: 9, label: 'Crystal facets', affects: 'geometry',
    describe: 'side-face count of every crystal prism AND of the host-rock cuff wrapped around it (integer 4-9). 4 = a blocky wedge-shaped crystal, 6 = the shipped irregular hexagonal prism, 9 = a finer near-round quartz spar. Each face keeps its own +/-14% radius offset at every count, so the cross-section stays grown rather than machined',
  },
  moundWidth: {
    type: 'range', default: 1.0, min: 0.82, max: 1.35, label: 'Mound width', affects: 'geometry',
    describe: 'footprint of the rock mound and, with it, how far the shaft roots and the loose pebbles sit out from the centre. The mound REBUILDS rather than stretching: the facet chord stays a fixed physical width, so the boulder gains columns as it widens (10 facets at 1.0, 8 at 0.82, 13-14 at 1.35) and the crag size stays constant. Mound height and all three shaft lengths are untouched, so 0.82 is a tall narrow spike of rock and 1.35 a broad low slab',
  },
  pebbles: {
    type: 'range', default: 4, min: 0, max: 7, label: 'Rubble pebbles', affects: 'geometry',
    describe: 'how many loose scree stones lie on the ground around the mound skirt (integer 0-7, ~48 triangles each). 0 = a clean single boulder that drops into a tidy scene, 4 = the shipped scatter, 7 = a fully littered impact site. Bearings are hand-picked so any count stays evenly spread in plan; the asset re-centres on its delivered bounds, so the footprint follows the count',
  },
};

export const rig = {};
export const detach = [];

export const night = {
  crystal: {
    color: '#8ef7ee', intensity: 0.65,
    describe: 'the crystal shafts self-luminesce after dark — cooler, cleaner and a shade brighter than their daytime albedo, a soft internal glow rather than a lamp. Recolour this with the `crystal` knob and the glow follows the gem',
  },
};

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function loft(rings, apex = null, capBottom = true) {
  const pos = [];
  const N = rings[0].length;
  for (let r = 0; r < rings.length - 1; r++) {
    const lo = rings[r], hi = rings[r + 1];
    for (let k = 0; k < N; k++) {
      const j = (k + 1) % N;
      quad(pos, lo[k], hi[k], hi[j], lo[j]);
    }
  }
  const top = rings[rings.length - 1];
  const tip = apex || centroid(top);
  for (let k = 0; k < N; k++) tri(pos, top[k], tip, top[(k + 1) % N]);
  if (capBottom) {
    const bot = rings[0], mid = centroid(bot);
    for (let k = 0; k < N; k++) tri(pos, mid, bot[k], bot[(k + 1) % N]);
  }
  return posGeo(pos);
}
function centroid(ring) {
  const c = [0, 0, 0];
  for (const p of ring) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
  return [c[0] / ring.length, c[1] / ring.length, c[2] / ring.length];
}

const ZONE_KEYS = ['rock', 'matrix', 'rubble', 'crystal'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};

function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['cyan-regolith'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? COLORWAYS['cyan-regolith'][k]) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

const MOUND_RX = 0.365, MOUND_RZ = 0.325, MOUND_H = 0.28;
const MOUND_SIDES = 10;
const GEM_ALBEDO = 0x7fe9e0, GEM_EMISSIVE = 0x2a7f84;

function mound(w) {
  const SIDES = Math.max(7, Math.min(14, Math.round(MOUND_SIDES * w)));
  const rx = MOUND_RX * w, rz = MOUND_RZ * w;

  const prof = [
    [0.00, 1.00], [0.30, 0.97], [0.60, 0.88], [0.84, 0.66], [0.95, 0.35],
  ];
  const rand = prng(4211);

  const col = [];
  for (let k = 0; k < SIDES; k++) col.push(0.86 + rand() * 0.26);
  const rings = prof.map(([ty, rs], ring) => {
    const out = [];
    for (let k = 0; k < SIDES; k++) {
      const a = (k / SIDES) * Math.PI * 2 + 0.19;
      const r = rs * col[k] * (0.96 + rand() * 0.08);
      const dy = ring === 0 ? 0 : (rand() - 0.5) * 0.050;
      out.push([Math.cos(a) * rx * r, ty * MOUND_H + dy, Math.sin(a) * rz * r]);
    }
    return out;
  });

  return loft(rings, [0.030 * w, MOUND_H + 0.015, -0.024 * w], true);
}

function shaft({ len, rad, phase, tiltDeg, azDeg, at, emerge, sides = 6 }) {
  const SIDES = sides;

  const face = [];
  for (let k = 0; k < SIDES; k++) face.push(1 + 0.14 * Math.sin(k * 2.7 + phase));

  const ring = (y, rs, spin = 0, wobble = 0) => {
    const out = [];
    for (let k = 0; k < SIDES; k++) {
      const a = (k / SIDES) * Math.PI * 2 + phase * 0.4 + spin;
      const r = rad * rs * (face[k] + wobble * Math.sin(k * 1.9 + phase * 2.3));
      out.push([Math.cos(a) * r, y, Math.sin(a) * r]);
    }
    return out;
  };

  const gem = loft(
    [ring(-0.075, 1.02), ring(len * 0.66, 0.94), ring(len * 0.85, 0.62)],
    [rad * 0.16, len, -rad * 0.10], true,
  );

  const cuff = loft(
    [ring(emerge - 0.085, 2.00, 0.42, 0.50), ring(emerge + 0.025, 1.35, 0.30, 0.36)],
    null, true,
  );

  const place = (g) => {
    g.rotateX(THREE.MathUtils.degToRad(tiltDeg));
    g.rotateY(THREE.MathUtils.degToRad(azDeg));
    g.translate(at[0], at[1], at[2]);
    return g;
  };
  return { gem: place(gem), cuff: place(cuff) };
}

function lump({ r, h, seed, at, squash = 1, sides = 8, rough = 0.34 }) {
  const SIDES = sides;
  const rand = prng(seed);
  const prof = [[0.00, 0.80], [0.42, 1.00], [0.78, 0.72]];
  const rings = prof.map(([ty, rs], ring) => {
    const out = [];
    for (let k = 0; k < SIDES; k++) {
      const a = (k / SIDES) * Math.PI * 2 + seed * 0.11;
      const rr = r * rs * (1 - rough + rand() * rough * 2);
      const dy = ring === 0 ? 0 : (rand() - 0.5) * h * 0.16;
      out.push([Math.cos(a) * rr, ty * h + dy, Math.sin(a) * rr * squash]);
    }
    return out;
  });
  const g = loft(rings, [r * 0.10, h, r * -0.08], true);
  g.translate(at[0], at[1], at[2]);
  return g;
}

const SHAFTS = [
  { key: 'main',  len: 0.635, rad: 0.090, phase: 0.0, tiltDeg:  6, azDeg: 184, at: [ 0.000, 0.170,  0.015], emerge: 0.115, splay: false },
  { key: 'left',  len: 0.460, rad: 0.062, phase: 1.7, tiltDeg: 26, azDeg: 238, at: [-0.118, 0.140, -0.062], emerge: 0.130, splay: true  },
  { key: 'right', len: 0.400, rad: 0.052, phase: 3.1, tiltDeg: 30, azDeg:  78, at: [ 0.120, 0.130,  0.030], emerge: 0.140, splay: true  },
];

const PEBBLES = [
  { r: 0.078, h: 0.082, seed: 17,  at: [-0.400, 0.000,  0.105], squash: 0.9  },
  { r: 0.058, h: 0.060, seed: 53,  at: [-0.110, 0.000, -0.350], squash: 1.1  },
  { r: 0.068, h: 0.070, seed: 97,  at: [ 0.375, 0.000, -0.135], squash: 1.0  },
  { r: 0.050, h: 0.054, seed: 149, at: [ 0.145, 0.000,  0.350], squash: 0.95 },
  { r: 0.062, h: 0.064, seed: 211, at: [-0.150, 0.000,  0.371], squash: 1.05 },
  { r: 0.052, h: 0.056, seed: 271, at: [-0.358, 0.000, -0.167], squash: 0.92 },
  { r: 0.072, h: 0.074, seed: 331, at: [ 0.208, 0.000, -0.359], squash: 1.0  },
];

const DEFAULTS = { colorway: 'cyan-regolith', spread: 1.0, facets: 6, moundWidth: 1.0, pebbles: 4 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const spread = clamp(num(o.spread, 1), 0.7, 1.5);
  const sides  = Math.round(clamp(num(o.facets, 6), 4, 9));
  const w      = clamp(num(o.moundWidth, 1), 0.82, 1.35);
  const nPeb   = Math.round(clamp(num(o.pebbles, 4), 0, 7));

  const g = new THREE.Group();
  g.name = 'crystal-cluster';

  const rockParts = [];
  const gemParts = [];
  const addRock = (geo, c) => rockParts.push({ g: geo, c });
  const addGem = (geo, c) => gemParts.push({ g: geo, c });

  addRock(mound(w), C.rock);

  for (const s of SHAFTS) {
    const k = s.splay ? spread : 1;
    const { gem, cuff } = shaft({
      len: s.len, rad: s.rad, phase: s.phase, emerge: s.emerge, sides,
      tiltDeg: s.tiltDeg * k, azDeg: s.azDeg,
      at: [s.at[0] * k * w, s.at[1], s.at[2] * k * w],
    });
    addGem(gem, C.crystal);
    addRock(cuff, C.matrix);
  }

  for (let i = 0; i < nPeb; i++) {
    const p = PEBBLES[i];
    addRock(lump({ r: p.r, h: p.h, seed: p.seed, squash: p.squash,
                   at: [p.at[0] * w, p.at[1], p.at[2] * w] }), C.rubble);
  }

  function prep(geo, hex) {
    geo = geo.toNonIndexed();
    geo.deleteAttribute('uv');
    geo.deleteAttribute('normal');
    const col3 = new THREE.Color(hex);
    const n = geo.attributes.position.count;
    const col = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { col[i*3] = col3.r; col[i*3+1] = col3.g; col[i*3+2] = col3.b; }
    geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
    return geo;
  }

  const rockGeo = mergeGeometries(rockParts.map(p => prep(p.g, p.c)));
  const gemGeo  = mergeGeometries(gemParts.map(p => prep(p.g, p.c)));

  rockGeo.computeBoundingBox(); gemGeo.computeBoundingBox();
  const bb = rockGeo.boundingBox.clone().union(gemGeo.boundingBox);
  const dx = -(bb.min.x + bb.max.x) / 2, dz = -(bb.min.z + bb.max.z) / 2, dy = -bb.min.y;
  rockGeo.translate(dx, dy, dz); gemGeo.translate(dx, dy, dz);

  rockGeo.computeVertexNormals();
  gemGeo.computeVertexNormals();

  const rockMesh = new THREE.Mesh(rockGeo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.92, metalness: 0,
  }));
  rockMesh.name = 'rock';

  const glow = C.crystal === GEM_ALBEDO
    ? new THREE.Color(GEM_EMISSIVE)
    : new THREE.Color(C.crystal).multiplyScalar(0.30);
  const gemMesh = new THREE.Mesh(gemGeo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.26, metalness: 0,
    emissive: glow, emissiveIntensity: 0.35,
  }));
  gemMesh.name = 'crystals';

  g.add(rockMesh, gemMesh);
  return g;
}

export default createAsset;
