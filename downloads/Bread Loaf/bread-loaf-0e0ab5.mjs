/*
 * Bread Loaf
 * https://polyfork.dev/asset/bread-loaf-0e0ab5
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './bread-loaf-0e0ab5.mjs';
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
 * SPECS  110 triangles, 1 material, 0.18 x 0.13 x 0.24 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CRUST = 0xd08f4c;
const CRUMB = 0xf7ead0;
const BAKE  = 0x8a4d1e;

const D = 0.24;
const ZF = D / 2;
const ZB = -D / 2;
const BACK_S = 0.93;
const INNER_S = 0.74;
const RECESS = 0.010;
const ZC = ZF - RECESS;

const PROFILE = [
  [-0.058, 0.000], [ 0.058, 0.000],
  [ 0.078, 0.038], [ 0.088, 0.078],
  [ 0.072, 0.108], [ 0.040, 0.128], [ 0.000, 0.134],
  [-0.040, 0.128], [-0.072, 0.108],
  [-0.088, 0.078], [-0.078, 0.038],
];
const N = PROFILE.length;
const TOP_FIRST = 4, TOP_LAST = 8;

const BANDS = [
  [0.00, 0.15, false], [0.15, 0.25, true],
  [0.25, 0.43, false], [0.43, 0.53, true],
  [0.53, 0.71, false], [0.71, 0.81, true],
  [0.81, 1.00, false],
];

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const CX = 0, CY = 0.062;
function ring(i, s, z) {
  const [x, y] = PROFILE[i];
  return [CX + (x - CX) * s, CY + (y - CY) * s, z];
}

const at = (i, t) => ring(i, 1 + (BACK_S - 1) * t, ZF + (ZB - ZF) * t);

function build() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  const crust = [], dark = [];

  for (let i = 1; i < N - 1; i++) tri(crust, at(0, 1), at(i + 1, 1), at(i, 1));

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    const crown = i >= TOP_FIRST && i < TOP_LAST;
    const spans = crown ? BANDS : [[0, 1, false]];
    for (const [t0, t1, isDark] of spans) {
      quad(isDark ? dark : crust, at(i, t0), at(i, t1), at(j, t1), at(j, t0));
    }
  }

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    quad(crust, ring(i, 1, ZF), ring(j, 1, ZF), ring(j, INNER_S, ZC), ring(i, INNER_S, ZC));
  }
  add(posGeo(crust), CRUST);
  add(posGeo(dark), BAKE);

  const crumb = [];
  for (let i = 1; i < N - 1; i++) {
    tri(crumb, ring(0, INNER_S, ZC), ring(i, INNER_S, ZC), ring(i + 1, INNER_S, ZC));
  }
  add(posGeo(crumb), CRUMB);

  return parts;
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

export function createAsset() {
  const g = new THREE.Group();
  g.add(finish(build()));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
