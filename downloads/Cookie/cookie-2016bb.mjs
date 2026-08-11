/*
 * Cookie
 * https://polyfork.dev/asset/cookie-2016bb
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cookie-2016bb.mjs';
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
 * SPECS  174 triangles, 1 material, 0.1 x 0.03 x 0.1 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const parts = [];
const add = (g, c) => parts.push({ g, c });

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
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const C = {
  dough: 0xe0aa5e,
  edge: 0xc4843c,
  chip: 0x3d2113,
};

const R = 0.05;
const T = 0.024;
const N = 20;

function rimAt(i) {
  const rand = prng(1000 + i * 7);
  return R * (0.96 + rand() * 0.07);
}

function cookieBodySplit() {
  const topPos = [], edgePos = [];
  const ringB = [], ringM = [], ringT = [];
  for (let i = 0; i < N; i++) {
    const a = (i / N) * Math.PI * 2;
    const ca = Math.cos(a), sa = Math.sin(a);
    const r = rimAt(i);
    ringB.push([ca * r * 0.90, 0, sa * r * 0.90]);
    ringM.push([ca * r, T * 0.42, sa * r]);
    ringT.push([ca * r * 0.93, T * 0.80, sa * r * 0.93]);
  }
  const top = [0, T, 0];
  const bot = [0, 0, 0];

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    tri(topPos, top, ringT[j], ringT[i]);
    tri(edgePos, ringT[i], ringM[j], ringM[i]); tri(edgePos, ringT[i], ringT[j], ringM[j]);
    tri(edgePos, ringM[i], ringB[j], ringB[i]); tri(edgePos, ringM[i], ringM[j], ringB[j]);
    tri(edgePos, bot, ringB[i], ringB[j]);
  }
  return { top: posGeo(topPos), edge: posGeo(edgePos) };
}

function topY(f) { return T * (0.80 + 0.20 * (1 - f / 0.93)); }

function chip(cx, cz, r, h, yaw) {
  const pos = [];
  const cy = topY(Math.hypot(cx, cz) / R);
  const apex = [cx, cy + h, cz];
  const ring = [];
  for (let i = 0; i < 6; i++) {
    const a = yaw + (i / 6) * Math.PI * 2;
    ring.push([cx + Math.cos(a) * r, cy - 0.0025, cz + Math.sin(a) * r]);
  }

  for (let i = 0; i < 6; i++) tri(pos, apex, ring[(i + 1) % 6], ring[i]);
  return posGeo(pos);
}

export function createAsset() {
  const body = cookieBodySplit();
  add(body.top, C.dough);
  add(body.edge, C.edge);

  const rand = prng(42);
  const chips = [];
  for (let tries = 0; tries < 120 && chips.length < 10; tries++) {
    const a = rand() * Math.PI * 2;
    const f = 0.16 + rand() * 0.54;
    const x = Math.cos(a) * f * R, z = Math.sin(a) * f * R;
    if (chips.some(p => Math.hypot(p[0] - x, p[1] - z) < 0.019)) continue;
    const cr = 0.0085 + rand() * 0.0025;
    add(chip(x, z, cr, 0.005, rand() * Math.PI), C.chip);
    chips.push([x, z]);
  }

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];
