/*
 * Apple
 * https://polyfork.dev/asset/apple-b15012
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './apple-b15012.mjs';
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
 * SPECS  100 triangles, 1 material, 0.11 x 0.12 x 0.09 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED = '#d83a2c';
const BROWN = '#5f4326';
const GREEN = '#4ea23e';

const parts = [];
const add = (g, c) => parts.push({ g, c });

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
function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

export function createAsset() {

  const prof = [
    [0.000, 0.000],
    [0.012, 0.031],
    [0.032, 0.046],
    [0.055, 0.044],
    [0.074, 0.029],
    [0.084, 0.015],
    [0.082, 0.000],
  ];
  const pts = prof.map(([y, r]) => new THREE.Vector2(r, y));
  const body = new THREE.LatheGeometry(pts, 7);
  add(body, RED);

  const stem = new THREE.BoxGeometry(0.009, 0.026, 0.009)
    .translate(0, 0.013, 0)
    .rotateZ(0.18)
    .translate(0.002, 0.078, 0);
  add(stem, BROWN);

  const leaf = [];
  const base  = [0.012, 0.084, 0.000];
  const side1 = [0.029, 0.113, 0.006];
  const side2 = [0.045, 0.086, 0.006];
  const tip   = [0.062, 0.115, 0.010];
  tri(leaf, base, side2, tip);
  tri(leaf, base, tip, side1);
  tri(leaf, base, tip, side2);
  tri(leaf, base, side1, tip);
  add(posGeo(leaf), GREEN);

  const mesh = finish(parts);
  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
