/*
 * Screwdriver
 * https://polyfork.dev/asset/screwdriver-284fac
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './screwdriver-284fac.mjs';
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
 * SPECS  118 triangles, 1 material, 0.27 x 0.04 x 0.04 m (real-world scale).
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
  for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.7, metalness: 0,
  }));
}

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const RED   = '#d23b2c';
const STEEL = '#b9c0c7';
const DARK  = '#33383d';

export function createAsset() {

  const rHandleBack = 0.019, rHandleFront = 0.016, handleLen = 0.095;
  const handleX0 = -0.135, handleX1 = handleX0 + handleLen;

  const handle = new THREE.CylinderGeometry(rHandleFront, rHandleBack, handleLen, 8)
    .rotateZ(-Math.PI / 2)
    .translate(handleX0 + handleLen / 2, 0, 0);
  add(handle, RED);

  const cap = new THREE.IcosahedronGeometry(rHandleBack, 0)
    .scale(0.55, 1, 1)
    .translate(handleX0, 0, 0);
  add(cap, RED);

  const collar = new THREE.CylinderGeometry(rHandleFront * 0.75, rHandleFront * 0.85, 0.012, 8)
    .rotateZ(-Math.PI / 2)
    .translate(handleX1 + 0.005, 0, 0);
  add(collar, DARK);

  const rShaft = 0.006;
  const shaftX0 = handleX1 + 0.008, shaftX1 = 0.10;
  const shaftLen = shaftX1 - shaftX0;
  const shaft = new THREE.CylinderGeometry(rShaft, rShaft, shaftLen, 6)
    .rotateZ(-Math.PI / 2)
    .translate(shaftX0 + shaftLen / 2, 0, 0);
  add(shaft, STEEL);

  const xi = shaftX1 - 0.004;
  const xo = shaftX1 + 0.022;
  const hy_i = rShaft, hz_i = rShaft;
  const hy_o = 0.0015, hz_o = 0.013;

  const iA = [xi, -hy_i, -hz_i], iB = [xi, -hy_i, hz_i], iC = [xi, hy_i, hz_i], iD = [xi, hy_i, -hz_i];
  const oA = [xo, -hy_o, -hz_o], oB = [xo, -hy_o, hz_o], oC = [xo, hy_o, hz_o], oD = [xo, hy_o, -hz_o];

  const bp = [];
  quad(bp, iA, oA, oB, iB);
  quad(bp, iD, iC, oC, oD);
  quad(bp, iB, oB, oC, iC);
  quad(bp, iA, iD, oD, oA);
  quad(bp, oA, oD, oC, oB);
  add(posGeo(bp), STEEL);

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(0, -bb.min.y, 0);

  mesh.geometry.computeBoundingBox();
  const bb2 = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb2.min.x + bb2.max.x) / 2, 0, 0);

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
