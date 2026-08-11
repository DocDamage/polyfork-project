/*
 * Water Blob
 * https://polyfork.dev/asset/water-blob-e2cdf2
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './water-blob-e2cdf2.mjs';
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
 * SPECS  208 triangles, 1 material, 8 x 0.04 x 7.01 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const WATER = 0x6390ac;

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
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const N = 13;
const TOP_Y = 0.040;

const SPAN_X = 8.0;
const SQUASH = 0.90;
const BAND = 0.955;
const SKIRT_INSET = 0.985;
const RINGS = [0, 0.20, 0.38, 0.55, 0.70, 0.83, BAND, 1.0];

function profile(t) {
  return 1
    + 0.030 * Math.sin(t * 2 + 0.62)
    + 0.055 * Math.sin(t * 3 - 1.94)
    + 0.048 * Math.sin(t * 5 + 2.71)
    + 0.030 * Math.sin(t * 7 + 0.35);
}

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'water-blob';

  const rand = prng(9);

  const hs = Math.PI / N;
  const phase = [0, hs, 0, hs, 0, hs, 0, 0];
  const jit = [0, 0.035, 0.030, 0.026, 0.020, 0.014, 0, 0];

  const RX = [], RZ = [];
  for (let i = 0; i < RINGS.length; i++) {
    RX.push([]); RZ.push([]);
    if (RINGS[i] === 0) { RX[i].push(0); RZ[i].push(0); continue; }
    for (let j = 0; j < N; j++) {
      const t = (j / N) * Math.PI * 2 + phase[i];
      const r = profile(t) * RINGS[i] * (1 + (rand() - 0.5) * 2 * jit[i]);
      RX[i].push(Math.cos(t) * r);
      RZ[i].push(Math.sin(t) * r * SQUASH);
    }
  }

  let minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity;
  for (let j = 0; j < N; j++) {
    minX = Math.min(minX, RX[7][j]); maxX = Math.max(maxX, RX[7][j]);
    minZ = Math.min(minZ, RZ[7][j]); maxZ = Math.max(maxZ, RZ[7][j]);
  }
  const S = SPAN_X / (maxX - minX);
  const OX = -(minX + maxX) / 2, OZ = -(minZ + maxZ) / 2;
  for (let i = 0; i < RINGS.length; i++) {
    for (let j = 0; j < RX[i].length; j++) {
      RX[i][j] = (RX[i][j] + OX) * S;
      RZ[i][j] = (RZ[i][j] + OZ) * S;
    }
  }

  const P = [];
  for (let i = 0; i < RINGS.length; i++) {
    P.push(RX[i].map((x, j) => [x, TOP_Y, RZ[i][j]]));
  }

  const pos = [];

  for (let j = 0; j < N; j++) {
    tri(pos, P[0][0], P[1][(j + 1) % N], P[1][j]);
  }
  for (let i = 1; i < 6; i++) {
    for (let j = 0; j < N; j++) {
      const k = (j + 1) % N;
      tri(pos, P[i][j], P[i][k], P[i + 1][k]);
      tri(pos, P[i][j], P[i + 1][k], P[i + 1][j]);
    }
  }
  for (let j = 0; j < N; j++) {
    const k = (j + 1) % N;
    quad(pos, P[6][j], P[6][k], P[7][k], P[7][j]);
  }

  const bot = P[7].map((p) => [p[0] * SKIRT_INSET, 0, p[2] * SKIRT_INSET]);
  for (let j = 0; j < N; j++) {
    const k = (j + 1) % N;
    quad(pos, P[7][j], P[7][k], bot[k], bot[j]);
  }
  for (let j = 0; j < N; j++) tri(pos, [0, 0, 0], bot[j], bot[(j + 1) % N]);

  g.add(finish([{ g: posGeo(pos), c: WATER }]));
  return g;
}

export const rig = {};
export const detach = [];
export default createAsset;
