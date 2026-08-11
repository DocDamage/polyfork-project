/*
 * Beach Grass Tuft
 * https://polyfork.dev/asset/beach-grass-tuft-0e699f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './beach-grass-tuft-0e699f.mjs';
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
 *   colorway    choice  'marram-green' 'marram-green' | 'sun-dried' | 'dune-pale' | 'salt-marsh'
 *   bladeDark   color   '#3B6B2C'      any hex or THREE.Color
 *   bladeMid    color   '#4F8F44'      any hex or THREE.Color
 *   bladeLight  color   '#8FBF5A'      any hex or THREE.Color
 *   bladeDry    color   '#DCCBA6'      any hex or THREE.Color
 *   sand        color   '#C9975C'      any hex or THREE.Color
 *   tallness    range   1              0.7 to 1.3
 *   windLean    range   20             0 to 40
 *   blades      range   22             14 to 26
 *   mound       toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/beach-grass-tuft-0e699f-params.json
 *
 * SPECS  494 triangles, 1 material, 0.45 x 0.5 x 0.42 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'marram-green': { bladeDark: '#3B6B2C', bladeMid: '#4F8F44', bladeLight: '#8FBF5A', bladeDry: '#DCCBA6', sand: '#C9975C' },
  'sun-dried':    { bladeDark: '#B99B68', bladeMid: '#C4A46A', bladeLight: '#DCCBA6', bladeDry: '#8FBF5A', sand: '#D9BE86' },
  'dune-pale':    { bladeDark: '#4F8F44', bladeMid: '#8FBF5A', bladeLight: '#DCCBA6', bladeDry: '#E8D6A8', sand: '#E8D6A8' },
  'salt-marsh':   { bladeDark: '#3B6B2C', bladeMid: '#4F8F44', bladeLight: '#5E9B3C', bladeDry: '#7C8683', sand: '#9C6B3C' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'marram-green', label: 'Colorway',
    options: ['marram-green', 'sun-dried', 'dune-pale', 'salt-marsh'],
    describe: 'Curated Pirate Cove grass schemes. marram-green is living green marram ' +
      'over an orange sand pad (the approved build); sun-dried flips the ratio to bleached ' +
      'straw blades with a couple of green survivors on pale sand; dune-pale is the palest ' +
      'sun-scorched scheme, near-white tips on light sand; salt-marsh is deep shaded green ' +
      'with grey dead blades on wet dark-brown soil. Sets all five colours unless a colour ' +
      'is passed explicitly.',
  },
  bladeDark: {
    type: 'color', default: '#3B6B2C', label: 'Dark blade',
    describe: 'Albedo of the darkest blades — about a quarter of the spray, mostly in the ' +
      'shaded inner and outer tiers. The bottom rung of the value ladder; keep it clearly ' +
      'darker than Mid blade or the tuft flattens into one green mass.',
  },
  bladeMid: {
    type: 'color', default: '#4F8F44', label: 'Mid blade',
    describe: 'Albedo of the workhorse blades — the largest single share of the spray. ' +
      'Should sit halfway in value between Dark blade and Light blade.',
  },
  bladeLight: {
    type: 'color', default: '#8FBF5A', label: 'Light blade',
    describe: 'Albedo of the sunlit blades, carried mostly by the TALL near-vertical tier ' +
      'that owns the top of the silhouette. The lightest green; raising it further makes ' +
      'the crown pop harder against a dark backdrop.',
  },
  bladeDry: {
    type: 'color', default: '#DCCBA6', label: 'Dried blade',
    describe: 'Albedo of the two bleached straw blades scattered through the spray — the ' +
      'lightest thing on the asset and the only warm note in the foliage. A small minority ' +
      'accent: set green and the tuft loses its dried-grass read entirely; darken it much ' +
      'and the blades read as brown twigs rather than dead grass.',
  },
  sand: {
    type: 'color', default: '#C9975C', label: 'Sand mound',
    describe: 'Albedo of the low faceted pad the blades grow out of. Warm and clearly ' +
      'lighter than the blades so the base reads as ground, not as foliage.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.70, max: 1.30, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Vertical stretch of the whole spray about the ground plane; the sand pad ' +
      'keeps its size. 0.70 is a squat wind-cropped 0.35 m clump wider than it is tall; ' +
      '1.30 is a 0.65 m stand of tall reedy blades. The fan\'s footprint is unchanged, so ' +
      'the silhouette runs from low-and-splayed to tall-and-spiky.',
  },
  windLean: {
    type: 'range', default: 20, min: 0, max: 40, step: 1, label: 'Wind lean',
    affects: 'geometry',
    describe: 'Degrees the spray is combed toward +X, as a shear that is zero at the roots ' +
      'and full at the tips, plus a matching tilt asymmetry (downwind blades splay further, ' +
      'upwind blades stand straighter). 0 is a still, evenly radial tuft; 40 is a hard ' +
      'gale-blown comb whose crown hangs well past its own root neck. Reads strongly in ' +
      'the front elevation.',
  },
  blades: {
    type: 'range', default: 22, min: 14, max: 26, step: 1, label: 'Blade count',
    affects: 'geometry',
    describe: 'How many blades in the spray. Azimuths follow a golden-angle sequence so ' +
      'any count stays evenly spread and never mirrors. 14 is a sparse young clump with ' +
      'daylight through it; 26 is a dense mature tuft with an almost solid lower body.',
  },
  mound: {
    type: 'toggle', default: true, label: 'Sand mound', affects: 'geometry',
    describe: 'The low faceted sand pad at the base. ON for scattering on grass, rock or ' +
      'bare terrain, where the pad gives the blades a rooted footing. OFF ships the blades ' +
      'alone with capped roots resting flat on y=0, for planting directly into a sand ' +
      'terrain blob where a second sand tone would read as a patch.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

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

function finish(list) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!merged) throw new Error('beach-grass-tuft: mergeGeometries returned null');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const DEG = Math.PI / 180;

const SEG = 4;
const KEEL = 0.40;

const BEND = 1.45;

function widthAt(t) {
  const strap = Math.pow(Math.max(0, 1 - t * t * t), 0.45);
  const u = Math.min(1, t / 0.12);
  return strap * (0.60 + 0.40 * u * u * (3 - 2 * u));
}

const TIERS = {
  tall:  { tilt: 19, len: 0.480, w: 0.030, r: 0.016 },
  mid:   { tilt: 49, len: 0.395, w: 0.028, r: 0.030 },
  outer: { tilt: 84, len: 0.430, w: 0.026, r: 0.058 },
  stub:  { tilt: 34, len: 0.235, w: 0.024, r: 0.022 },
};

const TIER_ORDER = [
  'outer', 'tall', 'mid', 'outer', 'tall', 'mid', 'stub', 'outer', 'tall', 'mid', 'outer',
  'mid', 'stub', 'tall', 'outer', 'mid', 'tall', 'outer', 'mid', 'stub', 'outer', 'tall',
  'mid', 'outer', 'mid', 'stub',
];

const TONE_ORDER = [
  0, 2, 1, 3, 2, 1, 2, 0, 0, 1, 0, 2, 1, 2, 1, 0, 1, 0, 1, 3, 2, 2,
  1, 0, 2, 1,
];

const GOLDEN = 137.50776405003785;

function blade(b, cap) {
  const az = b.az * DEG;
  const O = new THREE.Vector3(Math.cos(az), 0, Math.sin(az));
  const UP = new THREE.Vector3(0, 1, 0);
  const root = O.clone().multiplyScalar(b.r).setY(b.y0);

  const P = [], D = [];
  const step = b.len / SEG;
  const p = root.clone();
  for (let i = 0; i <= SEG; i++) {
    const t = i / SEG;
    const a = b.tilt * DEG * Math.pow(t, BEND);
    const d = O.clone().multiplyScalar(Math.sin(a)).addScaledVector(UP, Math.cos(a));
    P.push(p.clone());
    D.push(d.clone());
    if (i < SEG) p.addScaledVector(d, step);
  }

  const rings = [];
  for (let i = 0; i < SEG; i++) {
    const t = i / SEG;
    const w = b.w * widthAt(t);
    const k = w * KEEL;
    const d = D[i];

    const W = new THREE.Vector3(-Math.sin(az), 0, Math.cos(az));
    W.applyAxisAngle(d, b.tw * DEG * t).normalize();
    const K = new THREE.Vector3().crossVectors(d, W).normalize();
    const c0 = P[i];
    rings.push([
      c0.clone().addScaledVector(W, w / 2).toArray(),
      c0.clone().addScaledVector(K, k).toArray(),
      c0.clone().addScaledVector(W, -w / 2).toArray(),
    ]);
  }
  const apex = P[SEG].toArray();

  const pos = [];
  if (cap) tri(pos, rings[0][2], rings[0][1], rings[0][0]);
  for (let i = 0; i < SEG - 1; i++) {
    for (let e = 0; e < 3; e++) {
      quad(pos,
        rings[i][e], rings[i][(e + 1) % 3],
        rings[i + 1][(e + 1) % 3], rings[i + 1][e]);
    }
  }
  for (let e = 0; e < 3; e++) tri(pos, rings[SEG - 1][e], rings[SEG - 1][(e + 1) % 3], apex);
  return pos;
}

const MOUND_SIDES = 9;
const MOUND_R = 0.130;
const MOUND_H = 0.032;

function sandMound() {
  const rand = prng(4321);
  const R = [];
  for (let i = 0; i < MOUND_SIDES; i++) R.push(MOUND_R * (0.84 + rand() * 0.34));
  const A = [];
  for (let i = 0; i < MOUND_SIDES; i++) {

    A.push(((i + 0.30 * (rand() - 0.5)) / MOUND_SIDES) * Math.PI * 2);
  }
  const top = A.map((a, i) => [Math.cos(a) * R[i] * 0.72, MOUND_H, Math.sin(a) * R[i] * 0.72]);
  const ground = A.map((a, i) => [Math.cos(a) * R[i], 0, Math.sin(a) * R[i]]);

  const pos = [];
  for (let i = 1; i < MOUND_SIDES - 1; i++) tri(pos, top[0], top[i + 1], top[i]);
  for (let i = 0; i < MOUND_SIDES; i++) {
    const j = (i + 1) % MOUND_SIDES;
    quad(pos, ground[i], top[i], top[j], ground[j]);
  }
  for (let i = 1; i < MOUND_SIDES - 1; i++) tri(pos, ground[0], ground[i], ground[i + 1]);
  return pos;
}

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);

  const way = COLORWAYS[P.colorway] || COLORWAYS['marram-green'];
  const pick = (k) => userParams[k] ?? (userParams.colorway ? way[k] : params[k].default);
  const C = {
    bladeDark: pick('bladeDark'), bladeMid: pick('bladeMid'), bladeLight: pick('bladeLight'),
    bladeDry: pick('bladeDry'), sand: pick('sand'),
  };
  const TONES = [C.bladeDark, C.bladeMid, C.bladeLight, C.bladeDry];

  const N = Math.max(14, Math.min(26, Math.round(P.blades)));
  const useMound = !!P.mound;
  const leanDeg = Math.max(0, Math.min(40, P.windLean));

  const asym = Math.min(0.55, 0.022 * leanDeg);
  const rootY = useMound ? 0.010 : 0;

  const rand = prng(90210);
  const raw = [];
  for (let i = 0; i < N; i++) {
    const t = TIERS[TIER_ORDER[i]];
    const az = (i * GOLDEN + 23) % 360;
    const lenJ = 0.88 + rand() * 0.24;
    const tiltJ = 0.90 + rand() * 0.20;
    raw.push({
      pos: blade({
        az,
        tilt: t.tilt * tiltJ * (1 + asym * Math.cos(az * DEG)),
        len: t.len * lenJ,
        w: t.w * (0.90 + rand() * 0.20),
        r: t.r * (0.85 + rand() * 0.30),
        tw: (rand() - 0.5) * 32,
        y0: rootY,
      }, !useMound),
      tone: TONE_ORDER[i],
    });
  }

  let maxY = 0;
  for (const b of raw) for (let i = 1; i < b.pos.length; i += 3) if (b.pos[i] > maxY) maxY = b.pos[i];
  const H = 0.500 * P.tallness;
  const ky = H / maxY;
  const S = H * Math.tan(leanDeg * DEG);
  for (const b of raw) {
    for (let i = 0; i < b.pos.length; i += 3) {
      const y = b.pos[i + 1] * ky;
      b.pos[i + 1] = y;
      b.pos[i] += S * Math.pow(Math.max(0, y) / H, 1.6);
    }
  }

  const parts = [];
  for (const b of raw) parts.push({ g: posGeo(b.pos), c: TONES[b.tone] });
  if (useMound) parts.push({ g: posGeo(sandMound()), c: C.sand });

  const mesh = finish(parts);
  mesh.name = 'beach-grass-tuft-mesh';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );

  const g = new THREE.Group();
  g.name = 'beach-grass-tuft';
  g.add(mesh);
  return g;
}

export default createAsset;
