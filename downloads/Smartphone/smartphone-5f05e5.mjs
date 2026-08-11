/*
 * Smartphone
 * https://polyfork.dev/asset/smartphone-5f05e5
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './smartphone-5f05e5.mjs';
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
 * SPECS  102 triangles, 1 material, 0.07 x 0.15 x 0.01 m (real-world scale).
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
    vertexColors: true, flatShading: true, roughness: 0.6, metalness: 0.1,
  }));
}

function roundedRectShape(w, h, r) {
  const x = -w / 2, y = -h / 2;
  const s = new THREE.Shape();
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y);
  s.absarc(x + w - r, y + r, r, -Math.PI / 2, 0, false);
  s.lineTo(x + w, y + h - r);
  s.absarc(x + w - r, y + h - r, r, 0, Math.PI / 2, false);
  s.lineTo(x + r, y + h);
  s.absarc(x + r, y + h - r, r, Math.PI / 2, Math.PI, false);
  s.lineTo(x, y + r);
  s.absarc(x + r, y + r, r, Math.PI, Math.PI * 1.5, false);
  return s;
}

export function createAsset() {
  const W = 0.072, H = 0.150, D = 0.009;
  const R = 0.013;

  const body = new THREE.ExtrudeGeometry(roundedRectShape(W, H, R), {
    depth: D, bevelEnabled: false, curveSegments: 2,
  });
  body.translate(0, 0, -D / 2);
  add(body, '#25282d');

  const margin = 0.006;
  const screen = new THREE.ShapeGeometry(
    roundedRectShape(W - 2 * margin, H - 2 * margin, R - 0.004), 2);
  screen.translate(0, 0, D / 2 + 0.0004);
  add(screen, '#dfe7ee');

  const cam = new THREE.CircleGeometry(0.0045, 8);
  cam.translate(0, H / 2 - 0.011, D / 2 + 0.0009);
  add(cam, '#171a1f');

  const mesh = finish(parts);
  const g = new THREE.Group();
  g.add(mesh);

  const box = new THREE.Box3().setFromObject(g);
  g.position.y -= box.min.y;
  g.position.x -= (box.min.x + box.max.x) / 2;
  g.position.z -= (box.min.z + box.max.z) / 2;
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
