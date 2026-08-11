/*
 * Paint Roller
 * https://polyfork.dev/asset/paint-roller-4ad5c2
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './paint-roller-4ad5c2.mjs';
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
 * SPECS  126 triangles, 1 material, 0.28 x 0.32 x 0.06 m (real-world scale).
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
    vertexColors: true, flatShading: true, roughness: 0.9, metalness: 0,
  }));
}

function bentTube(pts, r, seg = 5) {
  const P = pts.map(p => new THREE.Vector3(...p));
  const gap = r * 1.5;
  const segDir = i => new THREE.Vector3().subVectors(P[i + 1], P[i]).normalize();
  const centers = [P[0]], dirs = [segDir(0)];
  for (let i = 1; i < P.length - 1; i++) {
    const d0 = segDir(i - 1), d1 = segDir(i);
    centers.push(P[i].clone().addScaledVector(d0, -gap)); dirs.push(d0);
    centers.push(P[i].clone().addScaledVector(d1, gap)); dirs.push(d1);
  }
  centers.push(P[P.length - 1]); dirs.push(segDir(P.length - 2));
  const rings = [];
  let t = null;
  for (let i = 0; i < centers.length; i++) {
    const dir = dirs[i];
    if (!t) {
      const up = Math.abs(dir.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
      t = new THREE.Vector3().crossVectors(up, dir).normalize();
    } else {
      t = t.clone().addScaledVector(dir, -t.dot(dir)).normalize();
    }
    const b = new THREE.Vector3().crossVectors(dir, t).normalize();
    const ring = [];
    for (let j = 0; j < seg; j++) {
      const a = (j / seg) * Math.PI * 2;
      ring.push(centers[i].clone().addScaledVector(t, Math.cos(a) * r).addScaledVector(b, Math.sin(a) * r));
    }
    rings.push(ring);
  }
  const pos = [];
  const tri = (a, b, c) => pos.push(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z);
  for (let i = 0; i < rings.length - 1; i++)
    for (let j = 0; j < seg; j++) {
      const a = rings[i][j], b = rings[i][(j + 1) % seg];
      const c = rings[i + 1][j], d = rings[i + 1][(j + 1) % seg];
      tri(a, b, c); tri(b, d, c);
    }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const CREAM = '#ece3d0';
const METAL = '#363b42';
const BLUE  = '#2f7fce';

export function createAsset() {
  const H = 0.27;
  const rR = 0.032;
  const rLen = 0.22;

  add(new THREE.CylinderGeometry(rR, rR, rLen, 8)
        .rotateZ(Math.PI / 2).translate(0, H, 0), CREAM);

  const rMetal = 0.008;
  add(bentTube([
    [ 0.10, H,          0],
    [ 0.16, H,          0],
    [ 0.16, H - 0.055,  0],
    [ 0.09, H - 0.115,  0],
    [ 0.09, H - 0.16,   0],
  ], rMetal), METAL);

  add(new THREE.CylinderGeometry(0.016, 0.016, 0.135, 6)
        .translate(0.09, H - 0.15 - 0.135 / 2, 0), BLUE);

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
