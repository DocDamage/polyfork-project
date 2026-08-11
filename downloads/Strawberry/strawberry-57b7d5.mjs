/*
 * Strawberry
 * https://polyfork.dev/asset/strawberry-57b7d5
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './strawberry-57b7d5.mjs';
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
 * SPECS  129 triangles, 1 material, 0.04 x 0.06 x 0.04 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED   = 0xd42a3a;
const GREEN = 0x3f9a45;
const SEED  = 0xf4d84a;

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
function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

export function createAsset() {

  const H = 0.046;
  const PROFILE = [
    [0.000, 0.000],
    [0.010, 0.008],
    [0.017, 0.020],
    [0.0205, 0.032],
    [0.0155, 0.042],
    [0.006, H],
  ];
  const pts = PROFILE.map(([r, y]) => new THREE.Vector2(r, y));
  add(new THREE.LatheGeometry(pts, 8), RED);

  function radiusAt(y) {
    for (let i = 1; i < PROFILE.length; i++) {
      const [r0, y0] = PROFILE[i-1], [r1, y1] = PROFILE[i];
      if (y <= y1) { const t = (y - y0) / (y1 - y0 || 1); return r0 + (r1 - r0) * t; }
    }
    return PROFILE[PROFILE.length-1][0];
  }

  function slopeAt(y) {
    for (let i = 1; i < PROFILE.length; i++) {
      const [r0, y0] = PROFILE[i-1], [r1, y1] = PROFILE[i];
      if (y <= y1) return (r1 - r0) / (y1 - y0 || 1);
    }
    return 0;
  }

  const seedPos = [];
  const rows = [
    { y: 0.010, n: 3, off: 0.0 },
    { y: 0.019, n: 4, off: 0.6 },
    { y: 0.028, n: 4, off: 0.2 },
    { y: 0.037, n: 3, off: 0.9 },
  ];
  for (const row of rows) {
    for (let i = 0; i < row.n; i++) {
      const a = (i / row.n) * Math.PI * 2 + row.off;
      const r = radiusAt(row.y);
      const ca = Math.cos(a), sa = Math.sin(a);
      const nrm = new THREE.Vector3(ca, -slopeAt(row.y), sa).normalize();
      const p = new THREE.Vector3(ca*r, row.y, sa*r).addScaledVector(nrm, 0.0003);
      const tU = new THREE.Vector3(-sa, 0, ca);
      const tV = new THREE.Vector3().crossVectors(nrm, tU).normalize();
      const w = 0.0015, h = 0.0026;
      const top = p.clone().addScaledVector(tV, h);
      const bot = p.clone().addScaledVector(tV, -h);
      const lft = p.clone().addScaledVector(tU, -w);
      const rgt = p.clone().addScaledVector(tU, w);
      tri(seedPos, top.toArray(), lft.toArray(), rgt.toArray());
      tri(seedPos, bot.toArray(), rgt.toArray(), lft.toArray());
    }
  }
  add(posGeo(seedPos), SEED);

  const cy = H;
  add(new THREE.ConeGeometry(0.013, 0.006, 8, 1, false).translate(0, cy + 0.002, 0), GREEN);

  add(new THREE.ConeGeometry(0.0035, 0.010, 5, 1, true).translate(0, cy + 0.007, 0), GREEN);

  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.7, metalness: 0,
  }));

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
