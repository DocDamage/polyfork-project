/*
 * Cannonball
 * https://polyfork.dev/asset/cannonball-f87cdc
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cannonball-f87cdc.mjs';
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
 *   colorway  choice  'cast-iron'    'cast-iron' | 'forge-black' | 'sea-rusted' | 'weathered-grey'
 *   iron      color   '#3E4348'      any hex or THREE.Color
 *   scour     color   '#5A6462'      any hex or THREE.Color
 *   rust      color   '#6B4526'      any hex or THREE.Color
 *   facets    range   4              3 to 5
 *   pitting   range   1              0.35 to 1.7
 *   restFlat  range   0.05           0 to 0.13
 *
 * Every option is described in full at https://polyfork.dev/cdn/cannonball-f87cdc-params.json
 *
 * SPECS  338 triangles, 1 material, 0.15 x 0.16 x 0.16 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'cast-iron':      { iron: '#3E4348', scour: '#5A6462', rust: '#6B4526' },
  'forge-black':    { iron: '#2A2320', scour: '#3E4348', rust: '#4A2E1B' },
  'sea-rusted':     { iron: '#5A6462', scour: '#7C8683', rust: '#9C6B3C' },
  'weathered-grey': { iron: '#6E757A', scour: '#9AA3A0', rust: '#A79680' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'cast-iron', label: 'Colorway',
    options: ['cast-iron', 'forge-black', 'sea-rusted', 'weathered-grey'],
    describe: 'Curated Pirate Cove iron schemes, setting all three zones at once. ' +
      'cast-iron is dark blue-grey foundry iron with cool scoured pits and warm brown ' +
      'rust (the default); forge-black is the darkest, a near-black sooty ball fresh ' +
      'from the furnace; sea-rusted is a pale grey-green shot left in the surf with ' +
      'bright red-oxide blooms; weathered-grey is a light dusty grey ball whose rust ' +
      'has faded to tan, for sun-bleached fort dressing. Explicit iron/scour/rust ' +
      'values override the preset.',
  },
  iron: {
    type: 'color', default: '#3E4348', label: 'Iron',
    describe: 'Albedo of the cast hull — every facet that is not a pit or a rust bloom, ' +
      'about 80% of the surface and the colour the ball is read by. Keep it the DARKEST ' +
      'of the three zones: this is the darkest object the kit ships. Lighter values turn ' +
      'it into a stone ball rather than iron.',
  },
  scour: {
    type: 'color', default: '#5A6462', label: 'Scoured pit',
    describe: 'Albedo of the facets ringing the six deepest impact dents (four dents at ' +
      'facet grade 3, seven at grade 5, so the patches never swamp a coarse shell) — bare metal ' +
      'laid open where the casting was knocked. Must stay LIGHTER than Iron: the pits ' +
      'are sunken, so a lighter tone there proves the colour is albedo and not painted ' +
      'shadow. Push it toward Iron to hide the pitting, toward white for a battered ' +
      'much-fired shot.',
  },
  rust: {
    type: 'color', default: '#6B4526', label: 'Rust bloom',
    describe: 'Albedo of the four small oxide patches, each a cluster of whole facets, ' +
      'spread around the ball so no 90-degree view is plain. The only warm colour on the ' +
      'asset and the tie into the kit\'s wood and sand. Set it near Iron for a freshly ' +
      'cast ball, toward orange-red for a shot left out in the salt air.',
  },
  facets: {
    type: 'range', default: 4, min: 3, max: 5, step: 1, label: 'Facets',
    affects: 'geometry',
    describe: 'Geodesic frequency of the shell — how finely the icosahedron is ' +
      'subdivided. 3 gives about 190 big triangles (~0.028 m each), a crudely hand-cut ' +
      'ball with an obviously polygonal outline; 4 is the default 338-facet cast shot; 5 ' +
      'gives about 530 smaller facets and a rounder, more finished ball. Changes the number ' +
      'of corners on the silhouette, never the diameter.',
  },
  pitting: {
    type: 'range', default: 1.0, min: 0.35, max: 1.7, step: 0.05, label: 'Pitting',
    affects: 'geometry',
    describe: 'Depth of the twelve impact dents. 0.35 is a nearly smooth ball with 2 mm ' +
      'scuffs you only catch at a grazing angle; 1.0 is the default 4-7 mm craters that ' +
      'each notch the outline by about one facet; 1.7 is a battered veteran shot with ' +
      '8-12 mm bowls that visibly flatten chords of the silhouette. Dent count and ' +
      'placement are unchanged, so the scour zones stay put.',
  },
  restFlat: {
    type: 'range', default: 0.05, min: 0.0, max: 0.13, step: 0.005, label: 'Resting flat',
    affects: 'geometry',
    describe: 'Size of the flat pad cut off the underside so the ball sits still, as a ' +
      'fraction of the radius. 0.0 leaves a full sphere that touches the ground on one ' +
      'facet corner (use it for a shot in flight or in a rack); 0.05 is the default 25 mm ' +
      'pad, about 31% of the width, so the ball reads heavy; 0.13 cuts a broad 40 mm pad ' +
      'and takes 10 mm off the height, giving a shot half-sunk into the sand.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const norm = (a) => { const l = Math.hypot(a[0], a[1], a[2]) || 1; return [a[0] / l, a[1] / l, a[2] / l]; };

const hash01 = (i) => { const h = Math.sin(i * 12.9898 + 78.233) * 43758.5453; return h - Math.floor(h); };

const RADIUS = 0.08;
const N_DENTS = 12;
const N_BLOOM = 4;

const HERO = norm([0.55, 0.18, 1]);

function geodesic(freq) {
  const t = (1 + Math.sqrt(5)) / 2;
  const base = [
    [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0],
    [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
    [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
  ].map(norm);
  const faces = [
    [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
    [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
    [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
    [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
  ];

  const V = [], F = [], key = new Map();
  const push = (p) => {
    const u = norm(p);
    const k = `${Math.round(u[0] * 1e5)},${Math.round(u[1] * 1e5)},${Math.round(u[2] * 1e5)}`;
    if (key.has(k)) return key.get(k);
    const i = V.push(u) - 1;
    key.set(k, i);
    return i;
  };

  for (const [ia, ib, ic] of faces) {
    const A = base[ia], B = base[ib], C = base[ic];

    const grid = [];
    for (let i = 0; i <= freq; i++) {
      grid.push([]);
      for (let j = 0; j <= freq - i; j++) {
        const w = (freq - i - j) / freq, u = i / freq, v = j / freq;
        grid[i].push(push([A[0] * w + B[0] * u + C[0] * v,
                           A[1] * w + B[1] * u + C[1] * v,
                           A[2] * w + B[2] * u + C[2] * v]));
      }
    }
    for (let i = 0; i < freq; i++) {
      for (let j = 0; j < freq - i; j++) {
        F.push([grid[i][j], grid[i + 1][j], grid[i][j + 1]]);
        if (j < freq - i - 1) F.push([grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]]);
      }
    }
  }

  for (const f of F) {
    const [a, b, c] = f.map(i => V[i]);
    const n = [(b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]),
               (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]),
               (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])];
    if (dot(n, a) < 0) { const s = f[1]; f[1] = f[2]; f[2] = s; }
  }
  return { V, F };
}

function spread(V, count, seedMul, startSep, heroBias, banned) {
  const score = (i) => hash01(i * seedMul + 7) + heroBias * Math.max(0, dot(V[i], HERO));
  const order = V.map((_, i) => i).filter(i => !banned.has(i)).sort((a, b) => score(b) - score(a));
  const sepDeg = (a, b) => Math.acos(Math.max(-1, Math.min(1, dot(V[a], V[b])))) * 180 / Math.PI;
  const picked = [];
  for (let sep = startSep; sep >= 0 && picked.length < count; sep -= 6) {
    for (const i of order) {
      if (picked.length >= count) break;
      if (picked.includes(i)) continue;
      if (picked.every(p => sepDeg(i, p) >= sep)) picked.push(i);
    }
  }
  return picked;
}

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const pick = (k) => (p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default));
  const num = (k) => (p[k] !== undefined ? Number(p[k]) : params[k].default);
  return {
    C: { iron: pick('iron'), scour: pick('scour'), rust: pick('rust') },
    freq: Math.max(3, Math.min(5, Math.round(num('facets')))),
    pitting: num('pitting'),
    flat: Math.max(0, Math.min(0.13, num('restFlat'))),
  };
}

function buildBall(R) {
  const { V, F } = geodesic(R.freq);

  const adj = V.map(() => new Set());
  for (const [a, b, c] of F) {
    adj[a].add(b); adj[a].add(c); adj[b].add(a); adj[b].add(c); adj[c].add(a); adj[c].add(b);
  }

  const centres = spread(V, N_DENTS, 31, 46, 0.55, new Set());
  const drop = new Float64Array(V.length);
  const dentDepth = centres.map((c, k) =>
    R.pitting * RADIUS * (k === 0 ? 0.150 : 0.075 + 0.055 * hash01(k * 17 + 3)));
  centres.forEach((c, k) => {
    drop[c] = Math.max(drop[c], dentDepth[k]);
    for (const nb of adj[c]) drop[nb] = Math.max(drop[nb], dentDepth[k] * 0.30);
  });

  const pos = V.map((u, i) => {
    const r = RADIUS * (1 + 0.012 * (hash01(i * 7 + 1) * 2 - 1)) - drop[i];
    return [u[0] * r, u[1] * r, u[2] * r];
  });

  const incident = V.map(() => []);
  F.forEach((f, ti) => { for (const v of f) incident[v].push(ti); });

  const byDepth = centres.map((c, k) => k).sort((a, b) => dentDepth[b] - dentDepth[a]);
  const nScour = R.freq <= 3 ? 4 : R.freq === 4 ? 6 : 7;
  const rimShare = R.freq <= 3 ? 3 : 99;
  const scourT = new Set();
  byDepth.slice(0, nScour).forEach((k, idx) => {
    const ts = incident[centres[k]].slice().sort((a, b) => hash01(a * 3 + idx) - hash01(b * 3 + idx));
    for (const ti of ts.slice(0, rimShare)) scourT.add(ti);
  });

  const banned = new Set();
  for (const c of centres) { banned.add(c); for (const nb of adj[c]) banned.add(nb); }
  V.forEach((u, i) => { if (dot(u, HERO) > 0.93) banned.add(i); });

  const bloomT = new Set();
  spread(V, N_BLOOM, 53, 72, 0.30, banned).forEach((v, k) => {
    const ts = incident[v].slice().sort((a, b) => hash01(a * 5 + k) - hash01(b * 5 + k));
    for (const ti of ts.slice(0, 2 + (k % 2))) bloomT.add(ti);
  });

  const buckets = { iron: [], scour: [], rust: [] };
  const zoneOf = (f, ti) => {
    if (scourT.has(ti)) return buckets.scour;
    if (bloomT.has(ti)) return buckets.rust;
    return buckets.iron;
  };

  const cutY = R.flat > 0.004 ? -RADIUS * (1 - R.flat) : -Infinity;
  const ring = [];
  for (let ti = 0; ti < F.length; ti++) {
    const f = F[ti];
    const p = f.map(i => pos[i]);
    const out = zoneOf(f, ti);
    const above = p.map(v => v[1] >= cutY);
    const nAbove = above.filter(Boolean).length;
    if (nAbove === 0) continue;
    if (nAbove === 3) { tri(out, p[0], p[1], p[2]); continue; }
    const poly = [];
    for (let i = 0; i < 3; i++) {
      const a = p[i], b = p[(i + 1) % 3];
      if (above[i]) poly.push(a);
      if (above[i] !== above[(i + 1) % 3]) {
        const t = (cutY - a[1]) / (b[1] - a[1]);
        const ip = [a[0] + (b[0] - a[0]) * t, cutY, a[2] + (b[2] - a[2]) * t];
        poly.push(ip); ring.push(ip);
      }
    }
    for (let i = 1; i < poly.length - 1; i++) tri(out, poly[0], poly[i], poly[i + 1]);
  }

  if (ring.length >= 3) {
    const pts = [];
    for (const p of ring) {
      if (!pts.some(q => Math.hypot(q[0] - p[0], q[2] - p[2]) < 1e-6)) pts.push(p);
    }
    pts.sort((a, b) => Math.atan2(a[2], a[0]) - Math.atan2(b[2], b[0]));
    const c = [pts.reduce((s, p) => s + p[0], 0) / pts.length, cutY,
               pts.reduce((s, p) => s + p[2], 0) / pts.length];

    for (let i = 0; i < pts.length; i++) tri(buckets.iron, c, pts[i], pts[(i + 1) % pts.length]);
  }

  return Object.entries(buckets)
    .filter(([, p]) => p.length)
    .map(([zone, p]) => ({ g: posGeo(p), c: R.C[zone] }));
}

function prep(geo, hex) {
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

export function createAsset(userParams = {}) {
  const R = resolve(userParams);
  const g = new THREE.Group();
  g.name = 'cannonball';

  const merged = mergeGeometries(buildBall(R).map(p => prep(p.g, p.c)));
  if (!merged) throw new Error('cannonball: mergeGeometries returned null');

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'cannonball-body';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};

export default createAsset;
