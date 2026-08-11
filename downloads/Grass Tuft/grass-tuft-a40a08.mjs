/*
 * Grass Tuft
 * https://polyfork.dev/asset/grass-tuft-a40a08
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './grass-tuft-a40a08.mjs';
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
 *   colorway    choice  'meadow'       'meadow' | 'deep-shade' | 'sun-bleached' | 'dry-straw'
 *   bladeDark   color   '#3d6b34'      any hex or THREE.Color
 *   bladeMid    color   '#5f9a4b'      any hex or THREE.Color
 *   bladeLight  color   '#77b258'      any hex or THREE.Color
 *   blades      range   8              5 to 10
 *   tallness    range   1              0.65 to 1.08
 *   splay       range   1              0.55 to 1.15
 *
 * Every option is described in full at https://polyfork.dev/cdn/grass-tuft-a40a08-params.json
 *
 * SPECS  368 triangles, 1 material, 0.34 x 0.35 x 0.31 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {

  'meadow':       { bladeDark: 0x3d6b34, bladeMid: 0x5f9a4b, bladeLight: 0x77b258 },

  'deep-shade':   { bladeDark: 0x1c3323, bladeMid: 0x2f4f2e, bladeLight: 0x4c8140 },

  'sun-bleached': { bladeDark: 0x6f8f3c, bladeMid: 0x8fa84a, bladeLight: 0xc8d98a },

  'dry-straw':    { bladeDark: 0x75563b, bladeMid: 0xa5855e, bladeLight: 0xc2a479 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'meadow', label: 'Colorway',
    options: ['meadow', 'deep-shade', 'sun-bleached', 'dry-straw'],
    describe: 'curated three-step green ladder for the whole tuft. meadow = the shipped mid-green mix; deep-shade = the same ladder two rungs darker, for grass under a canopy or in a rock shadow; sun-bleached = two rungs lighter and more olive, for open field; dry-straw = late-summer dead grass in the kit browns. Sets all three blade colours at once; an explicit bladeDark/bladeMid/bladeLight overrides the preset for that step.',
  },
  bladeDark: {
    type: 'color', default: '#3d6b34', label: 'Dark blades',
    describe: 'albedo of the darkest step of the ladder — 2 of the 8 blades at the default count, the contrast punch that stops the clump reading as one flat green mass. Uniform along each blade it paints, root to tip.',
  },
  bladeMid: {
    type: 'color', default: '#5f9a4b', label: 'Mid blades',
    describe: 'albedo of the middle step — 3 of the 8 blades at the default count, the clump\'s dominant green and the tone that matches the kit ground tiles.',
  },
  bladeLight: {
    type: 'color', default: '#77b258', label: 'Light blades',
    describe: 'albedo of the lightest step — 3 of the 8 blades at the default count, the sunlit-crown tone that carries the tuft\'s read from 10 m.',
  },
  blades: {
    type: 'range', default: 8, min: 5, max: 10, label: 'Blades', affects: 'geometry',
    describe: 'how many blades the tuft grows (integer 5-10). Blades are placed round the ring at an even pitch plus a hand-authored per-blade azimuth deviation, so the clump never reads regular. 5 is a sparse young tuft with wide open gaps and ground showing through the middle; 8 is the shipped density; 10 is a full clump whose crown nearly closes. The authored tier mix (tall inner / leaning mid / short filler / swept outer), lengths and tones cycle through the same table in azimuth order, so the pinched base and the tiered silhouette hold at every count.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.65, max: 1.08, label: 'Tallness', affects: 'geometry',
    describe: 'length of every blade, which is this tuft\'s defining dimension (0.35 m tall at 1.0). REBUILT, not scaled: the cross-section pitch along a blade is held at its shipped value (0.044 m on the tallest blade), so the ring count follows the length (5 rings at 0.65, 8 at 1.0, 9 at 1.08) and a longer blade\'s bow stays as smooth as the default\'s. Blade WIDTH and the root ring are untouched, so 0.65 is a short broad-strapped clump about 0.23 m tall with visibly stubbier blades, and 1.08 a 0.38 m tussock with proportionally slimmer, longer ones. The swept blades reach further out as they lengthen, so the crown widens with it. The range is skewed downward because the tuft is already as wide as it is tall.',
  },
  splay: {
    type: 'range', default: 1.0, min: 0.55, max: 1.15, label: 'Splay', affects: 'geometry',
    describe: 'how far the blades lay away from vertical, as a multiplier on every blade\'s tip tilt (the outermost blade reaches 84 degrees at 1.0). 0.55 is a tight upright brush, clearly taller than wide, with the outer blades pulled in to about 46 degrees; 1.0 is the shipped fan, about as wide as it is tall; 1.15 is an open rosette whose swept blades lay past horizontal to about 97 degrees and drop their tips back toward the ground. Blade count, length and width are untouched — this is posture only, so the tuft goes from roughly 0.26 m to 0.38 m across while its height falls. Effective tilt is capped at 105 degrees so no tip can arc back down through the ground plane.',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

const ZONE_KEYS = ['bladeDark', 'bladeMid', 'bladeLight'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS.meadow;
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? COLORWAYS.meadow[k]) & 0xFFFFFF;
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

const DEG = Math.PI / 180;

const BLADES = [
  { dev:   4.0, tilt: 80, len: 0.315, w: 0.036, r: 0.044, tw:  10, c: 'bladeLight' },
  { dev:  -6.0, tilt: 14, len: 0.350, w: 0.040, r: 0.011, tw:  13, c: 'bladeDark'  },
  { dev:  14.0, tilt: 48, len: 0.275, w: 0.034, r: 0.026, tw: -12, c: 'bladeMid'   },
  { dev:   7.0, tilt: 84, len: 0.320, w: 0.034, r: 0.046, tw: -14, c: 'bladeDark'  },
  { dev:  -9.0, tilt: 30, len: 0.195, w: 0.030, r: 0.019, tw:  11, c: 'bladeLight' },
  { dev:  12.0, tilt: 44, len: 0.255, w: 0.034, r: 0.028, tw:  12, c: 'bladeMid'   },
  { dev:  -5.0, tilt: 82, len: 0.310, w: 0.035, r: 0.045, tw: -11, c: 'bladeLight' },
  { dev:  10.0, tilt: 20, len: 0.315, w: 0.038, r: 0.014, tw:  15, c: 'bladeMid'   },
];
const N0 = 8;
const SEG0 = 8;
const TILT_CAP = 105;
const KEEL = 0.40;

const BEND = 1.30;

function widthAt(t) {
  const strap = Math.pow(Math.max(0, 1 - t * t), 0.62);
  const u = Math.min(1, t / 0.15);
  return strap * (0.55 + 0.45 * u * u * (3 - 2 * u));
}

function blade(parts, b, az, len, tiltDeg, seg, hex) {
  const azR = az * DEG;
  const O = new THREE.Vector3(Math.cos(azR), 0, Math.sin(azR));
  const UP = new THREE.Vector3(0, 1, 0);
  const root = O.clone().multiplyScalar(b.r);

  const P = [];
  const D = [];
  const step = len / seg;
  const p = root.clone();
  for (let i = 0; i <= seg; i++) {
    const t = i / seg;
    const a = tiltDeg * DEG * Math.pow(t, BEND);
    const d = O.clone().multiplyScalar(Math.sin(a)).addScaledVector(UP, Math.cos(a));
    P.push(p.clone());
    D.push(d.clone());
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
  const apex = P[seg].toArray();

  const pos = [];

  tri(pos, rings[0][2], rings[0][1], rings[0][0]);

  for (let i = 0; i < seg - 1; i++) {
    for (let e = 0; e < 3; e++) {
      quad(pos,
        rings[i][e], rings[i][(e + 1) % 3],
        rings[i + 1][(e + 1) % 3], rings[i + 1][e]);
    }
  }

  for (let e = 0; e < 3; e++) tri(pos, rings[seg - 1][e], rings[seg - 1][(e + 1) % 3], apex);

  parts.push({ g: posGeo(pos), c: hex });
}

const DEFAULTS = { colorway: 'meadow', blades: N0, tallness: 1, splay: 1 };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);

  const n = Math.round(clamp(num(o.blades, N0), 5, 12));
  const tall = clamp(num(o.tallness, 1), 0.65, 1.15);
  const splay = clamp(num(o.splay, 1), 0.55, 1.25);

  const seg = Math.max(4, Math.round(SEG0 * tall));

  const parts = [];
  const pitch = 360 / n;
  for (let j = 0; j < n; j++) {
    const b = BLADES[j % N0];
    const az = pitch * j + b.dev;
    const tilt = Math.min(b.tilt * splay, TILT_CAP);
    blade(parts, b, az, b.len * tall, tilt, seg, C[b.c]);
  }

  const mesh = finish(parts);
  mesh.name = 'grass-tuft-mesh';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );

  const g = new THREE.Group();
  g.name = 'grass-tuft';
  g.add(mesh);
  return g;
}

export default createAsset;
