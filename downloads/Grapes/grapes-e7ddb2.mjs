/*
 * Grapes
 * https://polyfork.dev/asset/grapes-e7ddb2
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './grapes-e7ddb2.mjs';
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
 * SPECS  144 triangles, 1 material, 0.15 x 0.25 x 0.14 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const PURPLE   = 0x8952c6;
const PURPLE_D = 0x5c2f88;
const GREEN    = 0x7fbc46;
const WOOD     = 0x5a3d22;

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
function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function berry(r) {
  return new THREE.IcosahedronGeometry(r, 0);
}

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  const rand = prng(11);
  const R = 0.040;

  const ROWS = [
    { y: 0.040, n: 1, r: 0.000, phase: 0.00 },

    { y: 0.102, n: 2, r: 0.028, phase: 0.80 },
    { y: 0.148, n: 3, r: 0.038, phase: 0.00 },
  ];
  let k = 0;
  for (const row of ROWS) {
    for (let i = 0; i < row.n; i++) {
      const a = ((i + row.phase) / row.n) * Math.PI * 2;
      const rr = row.r + (rand() - 0.5) * 0.006;
      const yy = row.y + (rand() - 0.5) * 0.008;
      const b = berry(R * (0.94 + rand() * 0.12));
      b.rotateY(rand() * Math.PI);
      b.rotateX((rand() - 0.5) * 0.6);
      b.translate(Math.cos(a) * rr, yy, Math.sin(a) * rr);

      add(b, (k++ % 2) ? PURPLE_D : PURPLE);
    }
  }

  const stem = new THREE.CylinderGeometry(0.010, 0.014, 0.055, 4);
  stem.rotateZ(0.14);
  stem.translate(-0.006, 0.196, -0.004);
  add(stem, WOOD);

  const L = [
    [0, 0, 0],
    [0.036, 0.003, 0.026],
    [0.030, 0.007, 0.058],
    [0, 0.010, 0.078],
    [-0.030, 0.007, 0.058],
    [-0.036, 0.003, 0.026],
  ];
  const lp = [];
  for (let i = 1; i < L.length - 1; i++) {
    tri(lp, L[0], L[i + 1], L[i]);
    tri(lp, L[0], L[i], L[i + 1]);
  }
  const leaf = posGeo(lp);
  leaf.rotateX(-0.50);
  leaf.rotateY(-1.35);
  leaf.translate(-0.012, 0.214, -0.004);
  add(leaf, GREEN);

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2);

  const group = new THREE.Group();
  group.name = 'grapes';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
