/*
 * Regolith Mound
 * https://polyfork.dev/asset/regolith-mound-ac2843
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './regolith-mound-ac2843.mjs';
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
 *   colorway   choice  'regolith-rust' 'regolith-rust' | 'pale-dust' | 'dark-basalt' | 'grey-tailings'
 *   soil       color   '#b2684b'      any hex or THREE.Color
 *   heapiness  range   1              0.62 to 1.45
 *   facets     choice  'standard'     'chunky' | 'standard' | 'fine'
 *   shoulder   range   0.7            0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/regolith-mound-ac2843-params.json
 *
 * SPECS  288 triangles, 1 material, 1.4 x 0.8 x 1.24 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'regolith-rust': { soil: '#b2684b' },
  'pale-dust':     { soil: '#c1a078' },
  'dark-basalt':   { soil: '#5b4337' },
  'grey-tailings': { soil: '#5f6570' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'regolith-rust', label: 'Colorway',
    options: ['regolith-rust', 'pale-dust', 'dark-basalt', 'grey-tailings'],
    describe: 'curated kit-coherent colour for the whole heap — it is one material, so a colorway is one hex. regolith-rust = the default warm rust that matches the kit terrain exactly, so the pile reads as native planet dust dug out of the ground it stands on; pale-dust = a bleached, sun-baked heap of fine light regolith for background dust fields and for piles that must not compete with foreground equipment; dark-basalt = a dark cold volcanic spoil heap that stands out strongly against rust ground, good beside a drill rig; grey-tailings = a desaturated grey-blue mine-tailings pile for non-Mars-toned scenes',
  },
  soil: {
    type: 'color', default: '#b2684b', label: 'Regolith',
    describe: 'albedo of the ENTIRE heap. This is a single-material object — loose dust tipped in a pile — so it carries exactly one flat colour over every facet, and all of the light and shade you see is the scene lights working on the flat-shaded geometry, never painted in. Keep it in the kit terrain family or the pile stops reading as material dug out of the ground it sits on. Darken it for freshly turned damp spoil, lighten it toward the pale end for a dry wind-blown drift',
  },
  heapiness: {
    type: 'range', default: 1.0, min: 0.62, max: 1.45, label: 'Heapiness',
    affects: 'geometry',
    describe: 'how tall the pile stands on a fixed 1.40 x 1.24 m footprint, i.e. how freshly it was tipped. 0.62 is a low 0.50 m spread drift that has slumped out and hugs the ground; 1.0 is the default 0.80 m settled heap; 1.45 is a steep 1.16 m cone of freshly dumped spoil that stands taller than it is half wide. Changes the front silhouette dramatically and the footprint not at all, so the mound stays inside its 4 m kit cell at every value',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facets',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'how many angular columns the heap is cut into. Each column carries its own lean, so this is also how many vertical creases run down the flanks and how coarse the outline is. chunky = 16 columns (~0.26 m facets) for a crude shattered heap with very long straight silhouette edges; standard = 24 (~0.17 m, the Synty-tier read matching the refs); fine = 32 for a finer-grained drift — going finer than this measurably walks the outline back toward a smooth cone and throws away the low-poly identity. The shoulder lobe is aimed by BEARING, so it survives every count',
  },
  shoulder: {
    type: 'range', default: 0.7, min: 0.0, max: 1.0, label: 'Shoulder lobe',
    affects: 'geometry',
    describe: 'size of the secondary hump merged into the +X flank — on a cardinal axis, so it bites the right-hand edge of the FRONT elevation and still falls on the right of the hero three-quarter. 0.0 is a clean single heap with a lobed but even outline; 0.7 is the default, a broad shoulder pushing the base out about 25% over a 90 degree arc and lifting the surface about 7% of the height, so the silhouette reads as a big hump with a smaller one growing out of it; 1.0 is a pronounced double heap that looks like two loads tipped against each other. The hump has its own toe on the ground and only narrows going up, so it never undercuts the foot at any value',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function dropSlivers(pos, minArea = 2e-5) {
  const out = [];
  for (let i = 0; i < pos.length; i += 9) {
    const ax = pos[i + 3] - pos[i], ay = pos[i + 4] - pos[i + 1], az = pos[i + 5] - pos[i + 2];
    const bx = pos[i + 6] - pos[i], by = pos[i + 7] - pos[i + 1], bz = pos[i + 8] - pos[i + 2];
    const cx = ay * bz - az * by, cy = az * bx - ax * bz, cz = ax * by - ay * bx;
    if (0.5 * Math.hypot(cx, cy, cz) >= minArea) for (let j = 0; j < 9; j++) out.push(pos[i + j]);
  }
  return out;
}

const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];

function triOriented(out, a, b, c, want) {
  if (dot(cross(sub(b, a), sub(c, a)), want) >= 0) tri(out, a, b, c); else tri(out, a, c, b);
}
function quadOriented(out, a, b, c, d, want) {
  if (dot(cross(sub(b, a), sub(c, a)), want) >= 0) quad(out, a, b, c, d); else quad(out, d, c, b, a);
}

const hash01 = (i) => { const h = Math.sin(i * 12.9898 + 78.233) * 43758.5453; return h - Math.floor(h); };

const DEG = Math.PI / 180;

const angDist = (a, b) => { let d = Math.abs(((a - b) % 360 + 540) % 360 - 180); return d; };

const RT = [0.000, 0.070, 0.320, 0.560, 0.800, 0.950];
const RR = [1.000, 0.930, 0.780, 0.620, 0.425, 0.220];
const KTOP = RT.length - 1;
const APEX_T = 1.000;

const LEAN_AMP = 0.30, LEAN_PIVOT = 0.15, LEAN_CAP = 0.72;

const CREST_LIP = 0.022;

const W0 = 1.40, D0 = 1.24, H0 = 0.80;

const COLUMNS_BY_FACETS = { chunky: 16, standard: 24, fine: 32 };

const LOBE_BEARING = 0;
const LOBE_ARC = 48;

const LOBE_R = [0.36, 0.34, 0.30, 0.22, 0.09, 0.00];
const LOBE_Y = [0.00, 0.05, 0.10, 0.08, 0.03, 0.00];

const LEAN_X = -0.060, LEAN_Z = 0.030;

const INSIDE = [0, 0.34, 0];

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const pick = (k) => (p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default));
  const num = (k) => (p[k] !== undefined ? p[k] : params[k].default);
  return {
    C: { soil: pick('soil') },
    heap: Math.max(0.4, num('heapiness')),
    lobe: Math.max(0, Math.min(1, num('shoulder'))),
    N: COLUMNS_BY_FACETS[p.facets] || COLUMNS_BY_FACETS[params.facets.default],
  };
}

function planLobe(thRad) {
  return 1
    + 0.090 * Math.sin(2 * thRad + 0.70)
    + 0.062 * Math.sin(3 * thRad + 2.35)
    + 0.040 * Math.sin(5 * thRad + 5.10);
}

function buildBody(R) {
  const N = R.N;

  const th = [];
  for (let c = 0; c < N; c++) {
    const step = 360 / N;
    th.push(c * step + step * 0.30 * (hash01(c * 7 + 2) - 0.5));
  }

  const V = [];
  for (let k = 0; k <= KTOP; k++) {
    const row = [];
    for (let c = 0; c < N; c++) {
      const t = th[c], tr = t * DEG;
      const lobe = R.lobe * Math.exp(-Math.pow(angDist(t, LOBE_BEARING) / LOBE_ARC, 2));

      const grit = 1 + 0.034 * (hash01(c * 13 + k * 5 + 3) - 0.5) * 2;
      const lip = k === KTOP ? CREST_LIP : 0;

      const lean = 1 + LEAN_AMP * (hash01(c * 31 + 5) - 0.5) * 2
        * (Math.min(RT[k], LEAN_CAP) - LEAN_PIVOT);
      const rad = (RR[k] + lip) * lean * planLobe(tr) * grit * (1 + lobe * LOBE_R[k]);

      const crest = k === KTOP ? 0.018 * (hash01(c * 23 + 11) - 0.5) * 2 : 0;
      const y = RT[k] + crest + lobe * LOBE_Y[k];
      const leanT = Math.pow(RT[k], 1.6);
      row.push([Math.cos(tr) * rad + LEAN_X * leanT, y, Math.sin(tr) * rad + LEAN_Z * leanT]);
    }
    V.push(row);
  }

  const apex = (() => {
    let x = 0, z = 0;
    for (let c = 0; c < N; c++) { x += V[KTOP][c][0]; z += V[KTOP][c][2]; }
    return [x / N - 0.030, APEX_T, z / N + 0.020];
  })();

  const buckets = { soil: [] };

  for (let k = 0; k < KTOP; k++) {
    for (let c = 0; c < N; c++) {
      const d = (c + 1) % N;
      const a = V[k][c], b = V[k + 1][c], e = V[k + 1][d], f = V[k][d];
      const mx = (a[0] + b[0] + e[0] + f[0]) / 4, my = (a[1] + b[1] + e[1] + f[1]) / 4;
      const mz = (a[2] + b[2] + e[2] + f[2]) / 4;
      quadOriented(buckets.soil, a, b, e, f, sub([mx, my, mz], INSIDE));
    }
  }

  for (let c = 0; c < N; c++) {
    const d = (c + 1) % N;
    const a = V[KTOP][c], b = V[KTOP][d];
    const m = [(apex[0] + a[0] + b[0]) / 3, (apex[1] + a[1] + b[1]) / 3, (apex[2] + a[2] + b[2]) / 3];
    triOriented(buckets.soil, apex, a, b, sub(m, INSIDE));
  }

  {
    let x = 0, z = 0;
    for (let c = 0; c < N; c++) { x += V[0][c][0]; z += V[0][c][2]; }
    const g = [x / N, 0, z / N];
    for (let c = 0; c < N; c++) {
      triOriented(buckets.soil, g, V[0][c], V[0][(c + 1) % N], [0, -1, 0]);
    }
  }

  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (const key of Object.keys(buckets)) {
    const a = buckets[key];
    for (let i = 0; i < a.length; i += 3) {
      for (let j = 0; j < 3; j++) { lo[j] = Math.min(lo[j], a[i + j]); hi[j] = Math.max(hi[j], a[i + j]); }
    }
  }
  const k = [W0 / (hi[0] - lo[0]), (H0 * R.heap) / (hi[1] - lo[1]), D0 / (hi[2] - lo[2])];
  for (const key of Object.keys(buckets)) {
    const a = buckets[key];
    for (let i = 0; i < a.length; i += 3) { a[i] *= k[0]; a[i + 1] *= k[1]; a[i + 2] *= k[2]; }
  }

  return Object.entries(buckets)
    .map(([zone, pos]) => [zone, dropSlivers(pos)])
    .filter(([, pos]) => pos.length)
    .map(([zone, pos]) => ({ g: posGeo(pos), c: R.C[zone] }));
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
  g.name = 'regolith-mound';

  const merged = mergeGeometries(buildBody(R).map(p => prep(p.g, p.c)));
  if (!merged) throw new Error('regolith-mound: mergeGeometries returned null');

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'regolith-mound-body';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
