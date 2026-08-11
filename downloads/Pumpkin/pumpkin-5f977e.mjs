/*
 * Pumpkin
 * https://polyfork.dev/asset/pumpkin-5f977e
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pumpkin-5f977e.mjs';
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
 * SPECS  120 triangles, 1 material, 0.33 x 0.27 x 0.33 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const ORANGE = 0xf5821f;
const RUST = 0xc7530c;
const GREEN = 0x2f5d29;

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
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
  for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const N = 10;
const RINGS = [
  [0.070, 0.000],
  [0.152, 0.042],
  [0.172, 0.105],
  [0.138, 0.172],
  [0.055, 0.208],
];
const PINCH = 0.92;

function ringPoint(ring, i) {
  const a = (i / N) * Math.PI * 2;
  const r = RINGS[ring][0] * (i % 2 ? PINCH : 1);
  return [Math.cos(a) * r, RINGS[ring][1], Math.sin(a) * r];
}

const lit = [], shade = [];
const bottomC = [0, 0, 0];
const topC = [0, 0.196, 0];
for (let i = 0; i < N; i++) {
  const j = (i + 1) % N;
  const out = i % 2 ? shade : lit;
  tri(out, bottomC, ringPoint(0, i), ringPoint(0, j));
  for (let r = 0; r < RINGS.length - 1; r++)
    quad(out, ringPoint(r, i), ringPoint(r + 1, i), ringPoint(r + 1, j), ringPoint(r, j));
  tri(out, topC, ringPoint(RINGS.length - 1, j), ringPoint(RINGS.length - 1, i));
}
add(posGeo(lit), ORANGE);
add(posGeo(shade), RUST);

const stem = new THREE.CylinderGeometry(0.036, 0.026, 0.078, 5)
  .translate(0, 0.039, 0)
  .rotateZ(-0.16)
  .translate(0.006, 0.192, 0);
add(stem, GREEN);

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'pumpkin';
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
