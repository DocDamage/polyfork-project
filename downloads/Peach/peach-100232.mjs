/*
 * Peach
 * https://polyfork.dev/asset/peach-100232
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './peach-100232.mjs';
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
 * SPECS  108 triangles, 1 material, 0.08 x 0.08 x 0.07 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SKIN  = 0xffc978;

const BLUSH = 0xe9694f;
const GREEN = 0x4f9c33;

const R = 0.038;

const SEG_W = 8, SEG_H = 6;

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  const c = new THREE.Color();
  for (let f = 0; f < n; f += 3) {
    c.set(Array.isArray(hex) ? hex[f / 3] : hex);
    for (let k = 0; k < 3; k++) {
      const i = f + k;
      col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b;
    }
  }
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

const HERO_AZ = 0.61;

const CLEFT_AZ = 0.10;

function buildBody() {
  const g = new THREE.SphereGeometry(R, SEG_W, SEG_H);
  const p = g.attributes.position;
  const v = new THREE.Vector3();
  for (let i = 0; i < p.count; i++) {
    v.fromBufferAttribute(p, i);
    const ry = v.y / R;

    const hs = 1 + 0.10 * ry - 0.15 * ry * ry;
    v.x *= hs; v.z *= hs;

    const a = Math.atan2(v.x, v.z);
    const w = Math.pow(Math.max(0, Math.cos(a)), 8);
    v.x *= 1 - 0.38 * w; v.z *= 1 - 0.38 * w;

    const top = Math.pow(Math.max(0, ry), 12);
    v.y = v.y * 0.97 - R * top * (0.30 + 1.20 * w * (1 - Math.pow(Math.max(0, ry), 8)));
    p.setXYZ(i, v.x, v.y, v.z);
  }
  g.rotateY(CLEFT_AZ);

  const cols = [];
  for (let iy = 0; iy < SEG_H; iy++) {
    for (let ix = 0; ix < SEG_W; ix++) {

      const az = ((ix + 0.5) / SEG_W) * Math.PI * 2 - Math.PI / 2 + CLEFT_AZ;

      const shadowWall = Math.cos(az - (CLEFT_AZ - Math.PI / SEG_W)) > 0.9;

      const blush = iy <= 1 || shadowWall;
      const n = (iy === 0 || iy === SEG_H - 1) ? 1 : 2;
      for (let k = 0; k < n; k++) cols.push(blush ? BLUSH : SKIN);
    }
  }
  add(g, cols);
}

function buildStem() {

  const h = 0.013;
  const g = new THREE.CylinderGeometry(0.0045, 0.0075, h, 5);

  g.rotateZ(0.20).translate(0.003, R * 0.66 + h * 0.40, 0.001);
  add(g, GREEN);
}

function buildLeaf() {

  const L = 0.027, W = 0.018, T = 0.0045;
  const A = [0, 0, 0], TIP = [0, 0, L];
  const Lf = [-W, 0, L * 0.40], Rt = [W, 0, L * 0.40];
  const U = [0, T, L * 0.38], D = [0, -T, L * 0.38];
  const pos = [];
  tri(pos, A, Lf, U); tri(pos, Lf, TIP, U); tri(pos, TIP, Rt, U); tri(pos, Rt, A, U);
  tri(pos, Lf, A, D); tri(pos, TIP, Lf, D); tri(pos, Rt, TIP, D); tri(pos, A, Rt, D);
  const g = posGeo(pos);

  g.rotateX(-0.68).rotateY(-1.15).translate(0.001, R * 0.72, 0.001);
  add(g, GREEN);
}

export function createAsset() {
  parts.length = 0;
  buildBody();
  buildStem();
  buildLeaf();
  const mesh = finish(parts);
  mesh.name = 'peach';

  mesh.geometry.computeBoundingBox();
  mesh.geometry.translate(0, -mesh.geometry.boundingBox.min.y, 0);
  const group = new THREE.Group();
  group.name = 'peach';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
