/*
 * Watermelon Slice
 * https://polyfork.dev/asset/watermelon-slice-bd255f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './watermelon-slice-bd255f.mjs';
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
 * SPECS  108 triangles, 1 material, 0.16 x 0.14 x 0.05 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED = 0xe0343f;
const PALE = 0xf3efdd;
const GREEN = 0x2c7a38;
const SEED = 0x241b16;

const R = 0.14;
const T = 0.042;
const TH = 0.6109;
const R_FLESH = R * 0.845;
const R_PALE = R * 0.90;

const AY = R;

const P = (r, a, z) => [Math.sin(a) * r, AY - Math.cos(a) * r, z];

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }

function triO(out, a, b, c, ref) {
  const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
  const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
  if (nx * ref[0] + ny * ref[1] + nz * ref[2] < 0) tri(out, a, c, b);
  else tri(out, a, b, c);
}
function quadO(out, a, b, c, d, ref) { triO(out, a, b, c, ref); triO(out, a, c, d, ref); }

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const N = 6;
const ANG = i => -TH + (2 * TH) * (i / N);

function band(rIn, rOut, arcWall) {
  const pos = [];
  const F = T / 2, B = -T / 2;
  for (let i = 0; i < N; i++) {
    const a0 = ANG(i), a1 = ANG(i + 1);
    const oF0 = P(rOut, a0, F), oF1 = P(rOut, a1, F);
    const oB0 = P(rOut, a0, B), oB1 = P(rOut, a1, B);
    if (rIn === 0) {
      triO(pos, P(0, 0, F), oF0, oF1, [0, 0, 1]);
      triO(pos, P(0, 0, B), oB0, oB1, [0, 0, -1]);
    } else {
      const iF0 = P(rIn, a0, F), iF1 = P(rIn, a1, F);
      const iB0 = P(rIn, a0, B), iB1 = P(rIn, a1, B);
      quadO(pos, iF0, oF0, oF1, iF1, [0, 0, 1]);
      quadO(pos, iB0, oB0, oB1, iB1, [0, 0, -1]);
    }
    if (arcWall) {
      const am = (a0 + a1) / 2;
      quadO(pos, oF0, oF1, oB1, oB0, [Math.sin(am), -Math.cos(am), 0]);
    }
  }

  for (const s of [-1, 1]) {
    const a = s * TH;
    const ref = [s * Math.cos(a), s * Math.sin(a), 0];
    quadO(pos, P(rIn, a, T / 2), P(rOut, a, T / 2), P(rOut, a, -T / 2), P(rIn, a, -T / 2), ref);
  }
  return posGeo(pos);
}

function seed(r, a, side, len = 0.018, wid = 0.011, h = 0.0045) {
  const c = P(r, a, side * T / 2);
  const u = [Math.sin(a), -Math.cos(a), 0];
  const v = [Math.cos(a), Math.sin(a), 0];
  const at = (du, dv) => [c[0] + u[0] * du + v[0] * dv, c[1] + u[1] * du + v[1] * dv, c[2]];
  const ring = [at(len / 2, 0), at(0, wid / 2), at(-len / 2, 0), at(0, -wid / 2)];
  const apex = [c[0], c[1], c[2] + side * h];
  const pos = [];
  for (let i = 0; i < 4; i++) {
    const p = ring[i], q = ring[(i + 1) % 4];
    const ref = [(p[0] + q[0]) / 2 - c[0], (p[1] + q[1]) / 2 - c[1], side * 0.004];
    triO(pos, apex, p, q, ref);
  }
  return posGeo(pos);
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

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  add(band(0, R_FLESH, false), RED);
  add(band(R_FLESH, R_PALE, false), PALE);
  add(band(R_PALE, R, true), GREEN);

  const SEEDS = [[0.74 * R, -0.24], [0.57 * R, 0.01], [0.38 * R, 0.25]];
  for (const side of [1, -1]) {
    for (const [r, a] of SEEDS) add(seed(r, side * a, side), SEED);
  }

  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'watermelon-slice';

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
