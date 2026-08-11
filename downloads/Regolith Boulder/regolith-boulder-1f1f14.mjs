/*
 * Regolith Boulder
 * https://polyfork.dev/asset/regolith-boulder-1f1f14
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './regolith-boulder-1f1f14.mjs';
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
 *   colorway    choice  'regolith-rust' 'regolith-rust' | 'pale-dust' | 'dark-basalt' | 'grey-stone'
 *   rock        color   '#b2684b'      any hex or THREE.Color
 *   squatness   range   1              0.78 to 1.32
 *   facets      choice  'standard'     'chunky' | 'standard' | 'fine'
 *   angularity  range   1              0.35 to 1.65
 *   scars       range   3              1 to 6
 *
 * Every option is described in full at https://polyfork.dev/cdn/regolith-boulder-1f1f14-params.json
 *
 * SPECS  275 triangles, 1 material, 1.12 x 0.96 x 1.02 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'regolith-rust': { rock: '#b2684b' },
  'pale-dust':     { rock: '#ac7c64' },
  'dark-basalt':   { rock: '#5b4337' },
  'grey-stone':    { rock: '#5f6570' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'regolith-rust', label: 'Colorway',
    options: ['regolith-rust', 'pale-dust', 'dark-basalt', 'grey-stone'],
    describe: 'which stone the boulder is cut from. The asset is one flat colour throughout — a rock is a single material, so every colorway sets exactly one albedo and all visible shading comes from the scene lights on the facets. regolith-rust = the default warm rust-brown that matches the kit terrain exactly, so the rock reads as native planet stone; pale-dust = a lighter dust-caked lump that sinks into a bright regolith field; dark-basalt = a dark warm volcanic block that stands out strongly against rust ground; grey-stone = a desaturated grey-blue stone for non-Mars-toned scenes',
  },
  rock: {
    type: 'color', default: '#b2684b', label: 'Rock',
    describe: 'the single albedo of the entire boulder — every facet, every spall-scar terrace, the resting pad, all of it. This is the only colour on the asset. Keep it in the terrain family or the rock stops reading as native to the ground it stands on; darken it for a denser volcanic block, lighten it toward the dust tone for a lump that recedes into the background',
  },
  squatness: {
    type: 'range', default: 1.0, min: 0.78, max: 1.32, label: 'Squatness',
    affects: 'geometry',
    describe: 'trades height for girth at near-constant volume, changing the front silhouette dramatically. 0.78 is a tall upright chunk about 1.09 m high and 0.99 m wide that reads as a standing menhir; 1.0 the default settled boulder at 0.96 x 1.12 m; 1.32 a broad flattened slab about 0.83 m high and 1.29 m wide that hugs the ground',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facets',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'how many cleavage planes are intersected to cut the body, i.e. how coarse the polygonal outline is. chunky = 32 big crude planes (~0.33 m each) for a roughly shattered block with very long straight silhouette edges; standard = 46 (~0.28 m each, the Synty-tier read matching the refs); fine = 60 smaller planes for a rounder weathered lump — going finer than this measurably walks the silhouette back toward a smooth ball',
  },
  angularity: {
    type: 'range', default: 1.0, min: 0.35, max: 1.65, label: 'Angularity',
    affects: 'geometry',
    describe: 'how unequal the cleavage planes are, i.e. how craggy versus how equant the boulder reads. 0.35 cuts every plane at nearly the same distance from the centre, giving an even near-spherical polyhedron of similar facets; 1.0 is the default, a handful of broad cleavage faces among many smaller ones; 1.65 spreads the plane distances widely into a lopsided, roughly shattered chunk with a few very large flats and a visibly off-centre mass',
  },
  scars: {
    type: 'range', default: 3, min: 1, max: 6, label: 'Spall scars',
    affects: 'geometry',
    describe: 'how many facets carry a shallow spall scar — a chip where a flake of crust popped off, cut as a real three-terrace step (outer break, flat ledge, lower floor) so it shades itself with no colour change at all. 1 leaves a nearly pristine convex boulder with a single chip on the upper shoulder; 3 is the default, spread so no two share a height band; 6 makes a battered, heavily flaked rock. Sizes alternate big-small-medium so no two chips ever read as a matched pair',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function dropSlivers(pos, minArea = 3e-5) {
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

const hash01 = (i) => { const h = Math.sin(i * 12.9898 + 78.233) * 43758.5453; return h - Math.floor(h); };

const H0 = 0.96, SX0 = 1.12, SZ0 = 1.02;

const BASE = { n: [0, -1, 0], d: 0.88 };

const PLANES_BY_FACETS = { chunky: 32, standard: 46, fine: 60 };
const GOLDEN = 2.399963229728653;

const HERO_AIM = norm([1.0, 0.55, 0.45]);

const TAN_WALL = Math.tan(58 * Math.PI / 180);

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const pick = (k) => (p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default));
  const num = (k) => (p[k] !== undefined ? p[k] : params[k].default);
  return {
    rock: pick('rock'),
    squat: num('squatness'),
    angular: num('angularity'),
    nScars: Math.max(1, Math.round(num('scars'))),
    nPlanes: PLANES_BY_FACETS[p.facets] || PLANES_BY_FACETS[params.facets.default],
  };
}

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

function basisFor(n) {
  const helper = Math.abs(n[1]) < 0.9 ? [0, 1, 0] : [1, 0, 0];
  const u = norm(cross(helper, n));
  return { u, v: cross(n, u) };
}

function facePolygon(pi, planes, big = 6) {
  const P = planes[pi], n = P.n;
  const { u, v } = basisFor(n);
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

function triOriented(out, a, b, c, want) {
  const n = cross(sub(b, a), sub(c, a));
  if (dot(n, want) >= 0) tri(out, a, b, c); else tri(out, c, b, a);
}

function fan(out, poly, flip = false) {
  const g = centroidOf(poly);
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    if (flip) tri(out, g, b, a); else tri(out, g, a, b);
  }
}

function stitchRing(out, outer, inner, g, u, v, want) {
  const N = outer.length, M = inner.length;
  const angOf = (p) => { const d = sub(p, g); return Math.atan2(dot(d, v), dot(d, u)); };
  const angGap = (a, b) => {
    let d = Math.abs(a - b) % (Math.PI * 2);
    return d > Math.PI ? Math.PI * 2 - d : d;
  };
  const a0 = angOf(outer[0]);
  let s = 0, best = Infinity;
  for (let j = 0; j < M; j++) {
    const d = angGap(angOf(inner[j]), a0);
    if (d < best) { best = d; s = j; }
  }
  let i = 0, j = 0;
  while (i < N || j < M) {
    const takeOuter = (j >= M) || (i < N && (i + 1) / N <= (j + 1) / M);
    const O = outer[i % N], Onext = outer[(i + 1) % N];
    const I = inner[(s + j) % M], Inext = inner[(s + j + 1) % M];
    if (takeOuter) { triOriented(out, O, Onext, I, want); i++; }
    else { triOriented(out, O, Inext, I, want); j++; }
  }
}

const polyArea = (poly) => {
  let s = 0;
  for (let i = 1; i < poly.length - 1; i++) {
    const c = cross(sub(poly[i], poly[0]), sub(poly[i + 1], poly[0]));
    s += Math.hypot(c[0], c[1], c[2]);
  }
  return s / 2;
};
const bearing = (p) => (Math.atan2(p[2], p[0]) * 180 / Math.PI + 360) % 360;
const bearingGap = (a, b) => { const d = Math.abs(a - b) % 360; return d > 180 ? 360 - d : d; };

function inradius(poly, g) {
  let m = Infinity;
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    const e = norm(sub(b, a));
    const w = sub(g, a);
    const perp = sub(w, mul(e, dot(w, e)));
    m = Math.min(m, Math.hypot(perp[0], perp[1], perp[2]));
  }
  return m;
}

function cutScar(out, f, sc) {
  const g = f.g, nOut = f.n;
  const { u, v } = basisFor(nOut);
  const M = 5 + Math.floor(hash01(f.i * 5 + 1) * 3);
  const phase = hash01(f.i * 9 + 4) * Math.PI * 2;
  const R = Math.min(sc.r, inradius(f.poly, g) * 0.78);

  const rr = [];
  const rim = [];
  for (let k = 0; k < M; k++) {
    const a = phase + (k / M) * Math.PI * 2;
    const r = R * (0.84 + 0.30 * hash01(f.i * 23 + k * 7 + 2));
    rr.push(r);
    rim.push(add(g, add(mul(u, Math.cos(a) * r), mul(v, Math.sin(a) * r))));
  }
  const rMin = Math.min(...rr);

  const depth = Math.min(sc.depth, rMin * 0.48);

  const TILT = Math.tan(22 * Math.PI / 180);
  const ta = hash01(f.i * 13 + 6) * Math.PI * 2;
  const td = [Math.cos(ta), Math.sin(ta)];

  const floor = rr.map((r, k) => {
    const a = phase + (k / M) * Math.PI * 2;
    const rq = Math.max(r * 0.30, r - depth / TAN_WALL);
    const px = Math.cos(a) * rq, py = Math.sin(a) * rq;
    const drop = depth * (1 + TILT * (px * td[0] + py * td[1]) / Math.max(1e-6, rMin));
    return add(add(g, add(mul(u, px), mul(v, py))), mul(nOut, -Math.max(depth * 0.30, drop)));
  });

  stitchRing(out, f.poly, rim, g, u, v, nOut);

  for (let k = 0; k < M; k++) {
    const j = (k + 1) % M;
    const inward = norm(sub(g, mul(add(rim[k], rim[j]), 0.5)));
    quadOriented(out, rim[k], rim[j], floor[j], floor[k], inward);
  }
  fan(out, floor, false);

  const fc = centroidOf(floor);
  const probe = cross(sub(floor[0], fc), sub(floor[1], fc));
  if (dot(probe, nOut) < 0) {
    const n3 = out.length - M * 9;
    for (let t = n3; t < out.length; t += 9) {
      for (let c = 0; c < 3; c++) { const tmp = out[t + c]; out[t + c] = out[t + 6 + c]; out[t + 6 + c] = tmp; }
    }
  }
}

function buildBody(R) {
  const N = R.nPlanes;
  const planes = [];

  const spread = 0.28 * R.angular;
  for (let i = 0; i < N; i++) {
    const yv = (1 - 2 * (i + 0.5) / N) * 0.985;
    const rr = Math.sqrt(Math.max(0, 1 - yv * yv));
    const th = i * GOLDEN;
    planes.push({
      n: [rr * Math.cos(th), yv, rr * Math.sin(th)],
      d: 1.0 - spread * 0.5 + spread * hash01(i * 7 + 1),
    });
  }
  const iBase = planes.push(BASE) - 1;

  const faces = [];
  for (let i = 0; i < planes.length; i++) {
    const poly = facePolygon(i, planes);
    if (poly) faces.push({ i, poly, n: norm(planes[i].n), g: centroidOf(poly), a: polyArea(poly) });
  }
  const aMax = Math.max(...faces.map(f => f.a));

  const SIZES = [0.220, 0.125, 0.180, 0.142, 0.200, 0.108];
  const cand = faces.filter(f => f.i !== iBase && f.a > aMax * 0.22
    && inradius(f.poly, f.g) * 0.78 > SIZES[1] * 0.60);
  if (!cand.length) return [];

  let hero = null, heroScore = -Infinity;
  for (const f of cand) {
    const s = dot(f.n, HERO_AIM) + 0.55 * (f.a / aMax);
    if (s > heroScore) { heroScore = s; hero = f; }
  }
  const picked = [hero];
  const want = Math.min(R.nScars, cand.length);
  const rank = (f) => 0.45 * (f.a / aMax) + 0.55 * hash01(f.i * 17 + 9);
  const order = cand.filter(f => f !== hero).sort((x, y) => rank(y) - rank(x));
  const sepAngle = (a, b) => Math.acos(Math.max(-1, Math.min(1, dot(a, b)))) * 180 / Math.PI;

  for (let step = 0; step <= 8 && picked.length < want; step++) {
    const sep = 120 - step * 15, yGap = 0.34 - step * 0.045, bGap = 145 - step * 18;
    for (const f of order) {
      if (picked.length >= want) break;
      if (picked.includes(f)) continue;
      const ok = picked.every(p => sepAngle(f.n, p.n) >= sep
        && (Math.abs(f.g[1] - p.g[1]) >= yGap || bearingGap(bearing(f.g), bearing(p.g)) >= bGap));
      if (ok) picked.push(f);
    }
  }

  const pos = [];
  const scars = new Map();
  picked.forEach((f, c) => {
    const r = SIZES[c % SIZES.length];
    scars.set(f.i, { r, depth: r * 0.46 });
  });

  for (const f of faces) {
    const sc = scars.get(f.i);
    if (sc) cutScar(pos, f, sc); else fan(pos, f.poly);
  }

  const H = H0 / Math.pow(R.squat, 0.62);
  const SX = SX0 * Math.pow(R.squat, 0.45), SZ = SZ0 * Math.pow(R.squat, 0.45);
  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < pos.length; i += 3) {
    for (let c = 0; c < 3; c++) { lo[c] = Math.min(lo[c], pos[i + c]); hi[c] = Math.max(hi[c], pos[i + c]); }
  }
  const k = [SX / (hi[0] - lo[0]), H / (hi[1] - lo[1]), SZ / (hi[2] - lo[2])];
  for (let i = 0; i < pos.length; i += 3) { pos[i] *= k[0]; pos[i + 1] *= k[1]; pos[i + 2] *= k[2]; }

  return [{ g: posGeo(dropSlivers(pos)), c: R.rock }];
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
  g.name = 'regolith-boulder';

  const merged = mergeGeometries(buildBody(R).map(p => prep(p.g, p.c)));
  if (!merged) throw new Error('regolith-boulder: mergeGeometries returned null');

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'regolith-boulder-body';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
