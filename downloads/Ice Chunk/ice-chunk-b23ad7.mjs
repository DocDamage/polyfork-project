/*
 * Ice Chunk
 * https://polyfork.dev/asset/ice-chunk-b23ad7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './ice-chunk-b23ad7.mjs';
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
 *   colorway       choice  'glacier'      'glacier' | 'frost-white' | 'deep-core' | 'regolith-crust'
 *   ice            color   '#8bbcc7'      any hex or THREE.Color
 *   fracture       color   '#c6e4e8'      any hex or THREE.Color
 *   core           color   '#eef8f8'      any hex or THREE.Color
 *   dust           color   '#ac7c64'      any hex or THREE.Color
 *   squatness      range   1              0.78 to 1.3
 *   fractureDepth  range   1              0.55 to 1.35
 *   facets         choice  'standard'     'chunky' | 'standard' | 'fine'
 *
 * Every option is described in full at https://polyfork.dev/cdn/ice-chunk-b23ad7-params.json
 *
 * SPECS  253 triangles, 1 material, 0.83 x 0.88 x 0.86 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  glacier: { ice: '#8bbcc7', fracture: '#c6e4e8', core: '#eef8f8', dust: '#ac7c64' },
  'frost-white': { ice: '#a8c2c8', fracture: '#d8ebec', core: '#f2f8f8', dust: '#989ea7' },
  'deep-core': { ice: '#638ea3', fracture: '#a8d2e0', core: '#dcf0f5', dust: '#73594d' },
  'regolith-crust': { ice: '#95b2b4', fracture: '#cde2dd', core: '#edf5f0', dust: '#b2684b' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'glacier', label: 'Colorway',
    options: ['glacier', 'frost-white', 'deep-core', 'regolith-crust'],
    describe: 'curated kit-coherent scheme for all four zones. glacier = pale cyan ice on rust dust (default); frost-white = near-white rime, cool grey dust; deep-core = saturated blue glacier ice with dark earth crust; regolith-crust = dulled grey-green ice heavily caked in rust regolith',
  },
  ice: {
    type: 'color', default: '#8bbcc7', label: 'Ice',
    describe: 'albedo of the un-broken outer faces of the block — the dominant mass, around half the surface. The darkest ice tone; the fracture zones step lighter from here',
  },
  fracture: {
    type: 'color', default: '#c6e4e8', label: 'Fracture wall',
    describe: 'albedo of the stepped rim wall around every pocket and of the wedge standing in the front one. One step lighter than the hull, one step darker than the floor it sits against, so the wedge separates from the floor by value as well as by form',
  },
  core: {
    type: 'color', default: '#eef8f8', label: 'Fracture floor',
    describe: 'albedo of the recessed pocket floors — the lightest zone on the asset (clean unweathered ice). Keep it lighter than Fracture or the recess reads as baked shadow',
  },
  dust: {
    type: 'color', default: '#ac7c64', label: 'Regolith crust',
    describe: 'albedo of the five whole faces of dried rust dust caked low on the block. The only warm colour on the asset; lower its value for damp soil, raise it for dry pale dust',
  },
  squatness: {
    type: 'range', default: 1.0, min: 0.78, max: 1.30, label: 'Squatness',
    affects: 'geometry',
    describe: 'trades height for girth at near-constant volume: 0.78 is a tall upright shard about 1.00 m high and 0.75 m wide, 1.0 the default equant boulder, 1.30 a broad flat slab about 0.77 m high and 0.95 m wide. Changes the front silhouette dramatically',
  },
  fractureDepth: {
    type: 'range', default: 1.0, min: 0.55, max: 1.35, label: 'Fracture depth',
    affects: 'geometry',
    describe: 'how deep the four pockets are cut below the faces they break: 0.55 shallow scuffs whose rims barely notch the outline, 1.0 the default step of about 55 mm that casts a clear shadow across each floor, 1.35 deep cavities whose rim walls dominate every view. The standing wedge scales with them and always stays below the surrounding face',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facets',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'how many cleavage planes are intersected to cut the block: chunky = 22, giving a few big crude faces (a roughly hewn boulder), standard = 32, fine = 42 smaller faces (a rounder, more crystalline lump). The four scars are aimed by compass bearing, so they stay on the front, right, back and left at every count',
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
const add = (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const mul = (a, s) => [a[0] * s, a[1] * s, a[2] * s];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const norm = (a) => { const l = Math.hypot(a[0], a[1], a[2]) || 1; return [a[0] / l, a[1] / l, a[2] / l]; };
const centroidOf = (poly) => mul(poly.reduce(add, [0, 0, 0]), 1 / poly.length);

const H0 = 0.88, RX0 = 0.415, RZ0 = 0.430;

const CROWN = { n: norm([0.40, 0.86, 0.31]), d: 0.74 };
const BASE = { n: [0, -1, 0], d: 1.0 };

const POCKET_AZ = [90, 0, 270, 180];
const POCKET_DEPTH = [0.095, 0.078, 0.086, 0.068];
const PLANES_BY_FACETS = { chunky: 22, standard: 32, fine: 42 };

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const pick = (k) => p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  return {
    C: { ice: pick('ice'), fracture: pick('fracture'), core: pick('core'), dust: pick('dust') },
    squat: p.squatness !== undefined ? p.squatness : params.squatness.default,
    fdepth: p.fractureDepth !== undefined ? p.fractureDepth : params.fractureDepth.default,
    nPlanes: PLANES_BY_FACETS[p.facets] || PLANES_BY_FACETS[params.facets.default],
  };
}

const hash01 = (i) => { const h = Math.sin(i * 12.9898 + 78.233) * 43758.5453; return h - Math.floor(h); };

function clip2d(poly, A, B, C) {
  const out = [];
  for (let i = 0; i < poly.length; i++) {
    const p = poly[i], q = poly[(i + 1) % poly.length];
    const dp = A * p[0] + B * p[1] - C, dq = A * q[0] + B * q[1] - C;
    if (dp <= 0) out.push(p);
    if ((dp < 0 && dq > 0) || (dp > 0 && dq < 0)) {
      const t = dp / (dp - dq);
      out.push([p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t]);
    }
  }
  return out;
}

function facePolygon(pi, planes, big = 6) {
  const P = planes[pi], n = P.n;
  const helper = Math.abs(n[1]) < 0.9 ? [0, 1, 0] : [1, 0, 0];
  const u = norm(cross(helper, n));
  const v = cross(n, u);
  const c = mul(n, P.d);
  let poly = [[-big, -big], [big, -big], [big, big], [-big, big]];
  for (let j = 0; j < planes.length && poly.length; j++) {
    if (j === pi) continue;
    const Q = planes[j];
    poly = clip2d(poly, dot(Q.n, u), dot(Q.n, v), Q.d - dot(Q.n, c));
  }
  if (poly.length < 3) return null;

  const pts = [];
  for (const [s, t] of poly) {
    const p = add(c, add(mul(u, s), mul(v, t)));
    const last = pts[pts.length - 1];
    if (!last || Math.hypot(p[0] - last[0], p[1] - last[1], p[2] - last[2]) > 1e-6) pts.push(p);
  }
  if (pts.length > 2) {
    const a = pts[0], b = pts[pts.length - 1];
    if (Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]) < 1e-6) pts.pop();
  }
  return pts.length >= 3 ? pts : null;
}

function quadOriented(out, a, b, c, d, want) {
  const n = cross(sub(b, a), sub(c, a));
  if (dot(n, want) >= 0) quad(out, a, b, c, d);
  else quad(out, d, c, b, a);
}

function fan(out, poly, flip = false) {
  const g = centroidOf(poly);
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    if (flip) tri(out, g, b, a); else tri(out, g, a, b);
  }
}

function buildChunk(R) {
  const N = R.nPlanes;
  const planes = [];

  for (let i = 0; i < N; i++) {
    const yv = (1 - 2 * (i + 0.5) / N) * 0.62;
    const rr = Math.sqrt(Math.max(0, 1 - yv * yv));
    const th = i * 2.399963229728653;

    planes.push({ n: [rr * Math.cos(th), yv, rr * Math.sin(th)], d: 0.68 + 0.46 * hash01(i * 7 + 1) });
  }
  const iCrown = planes.push(CROWN) - 1;
  const iBase = planes.push(BASE) - 1;

  const area2 = (poly) => {
    let s = 0;
    for (let i = 1; i < poly.length - 1; i++) {
      const c = cross(sub(poly[i], poly[0]), sub(poly[i + 1], poly[0]));
      s += Math.hypot(c[0], c[1], c[2]);
    }
    return s;
  };
  const faces = [];
  for (let i = 0; i < planes.length; i++) {
    const poly = facePolygon(i, planes);
    if (poly) faces.push({ i, poly, n: planes[i].n, g: centroidOf(poly), a: area2(poly) });
  }

  const pockets = new Map();
  for (let b = 0; b < POCKET_AZ.length; b++) {
    const a = POCKET_AZ[b] * Math.PI / 180;
    const want = [Math.cos(a), 0, Math.sin(a)];
    const aMax = Math.max(...faces.map(f => f.a));
    let best = null, bestScore = -Infinity;
    for (const f of faces) {
      if (f.i === iBase || f.i === iCrown || pockets.has(f.i)) continue;

      const s = dot(norm(f.n), want) + 1.15 * (f.a / aMax);
      if (s > bestScore) { bestScore = s; best = f; }
    }
    if (best) pockets.set(best.i, POCKET_DEPTH[b] * R.fdepth);
  }
  const frontFace = [...pockets.keys()][0];

  const dusty = new Set();
  {

    const med = [...faces.map(f => f.a)].sort((x, y) => x - y)[Math.floor(faces.length / 2)];
    const cand = faces
      .filter(f => f.i !== iBase && f.i !== iCrown && !pockets.has(f.i)
        && f.g[1] < -0.10 && f.a < med)
      .sort((a, b) => a.a - b.a);
    const bearing = (f) => (Math.atan2(f.g[2], f.g[0]) * 180 / Math.PI + 360) % 360;
    for (const f of cand) {
      if (dusty.size >= 5) break;
      let ok = true;
      for (const j of dusty) {
        const other = faces.find(x => x.i === j);
        let dd = Math.abs(bearing(f) - bearing(other)) % 360;
        if (dd > 180) dd = 360 - dd;
        if (dd < 45) ok = false;
      }
      if (ok) dusty.add(f.i);
    }
  }

  const buckets = { ice: [], fracture: [], core: [], dust: [] };

  for (const f of faces) {
    const depth = pockets.get(f.i);
    if (depth === undefined) {
      fan(dusty.has(f.i) ? buckets.dust : buckets.ice, f.poly);
      continue;
    }

    const g = f.g, nOut = norm(f.n);
    const wide = f.i === frontFace;
    const rimF = wide ? 0.74 : 0.62, flrF = wide ? 0.62 : 0.48;
    const rim = f.poly.map(p => add(g, mul(sub(p, g), rimF)));
    const floor = f.poly.map(p => add(add(g, mul(sub(p, g), flrF)), mul(nOut, -depth)));
    fan(buckets.core, floor);
    for (let i = 0; i < f.poly.length; i++) {
      const j = (i + 1) % f.poly.length;

      quadOriented(buckets.ice, f.poly[i], f.poly[j], rim[j], rim[i], nOut);

      const mid = mul(add(rim[i], rim[j]), 0.5);
      quadOriented(buckets.fracture, rim[i], rim[j], floor[j], floor[i], norm(sub(g, mid)));
    }

    if (f.i === frontFace) {
      const fg = centroidOf(floor);

      const off = add(fg, mul(norm(sub(floor[0], fg)), 0.22 * Math.hypot(
        floor[0][0] - fg[0], floor[0][1] - fg[1], floor[0][2] - fg[2])));
      const base = floor.map(p => add(off, mul(sub(p, off), 0.46)));
      const rise = depth * 0.66;
      const top = floor.map(p => add(add(off, mul(sub(p, off), 0.30)), mul(nOut, rise)));
      for (let i = 0; i < base.length; i++) {
        const j = (i + 1) % base.length;
        quad(buckets.fracture, base[i], base[j], top[j], top[i]);
      }
      fan(buckets.fracture, top);
    }
  }

  const H = H0 / Math.pow(R.squat, 0.55);
  const SX = 2 * RX0 * Math.pow(R.squat, 0.5), SZ = 2 * RZ0 * Math.pow(R.squat, 0.5);
  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (const key of Object.keys(buckets)) {
    const a = buckets[key];
    for (let i = 0; i < a.length; i += 3) {
      for (let c = 0; c < 3; c++) { lo[c] = Math.min(lo[c], a[i + c]); hi[c] = Math.max(hi[c], a[i + c]); }
    }
  }
  const k = [SX / (hi[0] - lo[0]), H / (hi[1] - lo[1]), SZ / (hi[2] - lo[2])];
  for (const key of Object.keys(buckets)) {
    const a = buckets[key];
    for (let i = 0; i < a.length; i += 3) {
      a[i] *= k[0]; a[i + 1] *= k[1]; a[i + 2] *= k[2];
    }
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
  g.name = 'ice-chunk';

  const merged = mergeGeometries(buildChunk(R).map(p => prep(p.g, p.c)));
  if (!merged) throw new Error('ice-chunk: mergeGeometries returned null');

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.42, metalness: 0,
    emissive: new THREE.Color(0x11363c), emissiveIntensity: 0.16,
  }));
  mesh.name = 'ice';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
