/*
 * Orange
 * https://polyfork.dev/asset/orange-ea3791
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './orange-ea3791.mjs';
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
 * SPECS  98 triangles, 1 material, 0.08 x 0.1 x 0.08 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const ORANGE = 0xf4881f;
const LEAF   = 0x5aa832;
const STEM   = 0x2f6b1a;

const R = 0.040;
const SQUASH = 0.93;
const CY = R * SQUASH;
const LEN = 0.048;
const WID = 0.021;

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

function leafSheet(flip) {
  const s = flip ? -1 : 1;
  const y = flip ? -0.0011 : 0;
  const B  = [0, y, 0];
  const C  = [0.40 * LEN, y + 0.006, 0];
  const Lp = [0.40 * LEN, y - 0.002,  WID];
  const Rp = [0.40 * LEN, y - 0.002, -WID];
  const T  = [LEN, y, 0];
  const p = [];
  const face = (a, b, c) => (s > 0 ? tri(p, a, b, c) : tri(p, a, c, b));
  face(B, Lp, C); face(B, C, Rp); face(Lp, T, C); face(C, T, Rp);
  return posGeo(p);
}

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  add(new THREE.IcosahedronGeometry(R, 1).scale(1, SQUASH, 1).translate(0, CY, 0), ORANGE);

  add(new THREE.ConeGeometry(0.011, 0.014, 5).translate(0, CY * 2 - 0.003, 0), STEM);

  const leaf = mergeGeometries([leafSheet(false), leafSheet(true)]);

  leaf.rotateX(0.9).rotateZ(0.35).rotateY(0.175).translate(0, CY * 2 + 0.003, 0);
  add(leaf, LEAF);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
