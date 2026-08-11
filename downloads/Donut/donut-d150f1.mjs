/*
 * Donut
 * https://polyfork.dev/asset/donut-d150f1
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './donut-d150f1.mjs';
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
 * SPECS  140 triangles, 1 material, 0.1 x 0.04 x 0.1 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

function mergeGeometries(geos) {
  let n = 0;
  for (const g of geos) n += g.attributes.position.count;
  const pos = new Float32Array(n * 3), col = new Float32Array(n * 3);
  let o = 0;
  for (const g of geos) {
    pos.set(g.attributes.position.array, o);
    col.set(g.attributes.color.array, o);
    o += g.attributes.position.count * 3;
  }
  const merged = new THREE.BufferGeometry();
  merged.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  merged.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return merged;
}

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
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

const R      = 0.035;
const TUBE   = 0.016;
const DRIP   = 0.0045;
const TUBSEG = 8;

const DOUGH  = '#d9954f';
const PINK   = '#ee6a99';
const WHITE  = '#fbfbf6';
const BLUE   = '#3aa7e0';

function frostingBand(radius, baseTube, drip, tubSeg, vStart, vEnd, vSeg) {
  const pos = [];
  const tubeAt = (v) =>
    baseTube + drip * Math.sin(((v - vStart) / (vEnd - vStart)) * Math.PI);
  const p = (u, v) => {
    const t = tubeAt(v);
    const rr = radius + t * Math.cos(v);
    return [rr * Math.cos(u), t * Math.sin(v), rr * Math.sin(u)];
  };
  for (let i = 0; i < tubSeg; i++) {
    const u0 = (i / tubSeg) * Math.PI * 2, u1 = ((i + 1) / tubSeg) * Math.PI * 2;
    for (let j = 0; j < vSeg; j++) {
      const v0 = vStart + (vEnd - vStart) * (j / vSeg);
      const v1 = vStart + (vEnd - vStart) * ((j + 1) / vSeg);

      quad(pos, p(u0, v0), p(u0, v1), p(u1, v1), p(u1, v0));
    }
  }
  return posGeo(pos);
}

function sprinkle(cx, cy, cz, angle, len = 0.012, wid = 0.004) {
  const dx = Math.cos(angle), dz = Math.sin(angle);
  const px = -dz, pz = dx;
  const hx = dx * len / 2, hz = dz * len / 2;
  const wx = px * wid / 2, wz = pz * wid / 2;
  const a = [cx - hx - wx, cy, cz - hz - wz];
  const b = [cx + hx - wx, cy, cz + hz - wz];
  const c = [cx + hx + wx, cy, cz + hz + wz];
  const d = [cx - hx + wx, cy, cz - hz + wz];
  const pos = [];
  quad(pos, a, d, c, b);
  return posGeo(pos);
}

export function createAsset() {

  add(new THREE.TorusGeometry(R, TUBE, 5, TUBSEG).rotateX(-Math.PI / 2), DOUGH);

  const vA = 0.18, vB = Math.PI - 0.18;
  add(frostingBand(R, TUBE, DRIP, TUBSEG, vA, vB, 3), PINK);

  const tubeAt = (v) => TUBE + DRIP * Math.sin(((v - vA) / (vB - vA)) * Math.PI);
  const rand = prng(7);
  const N = 6;
  for (let i = 0; i < N; i++) {
    const u = (i / N) * Math.PI * 2 + (rand() - 0.5) * 0.6;
    const v = Math.PI / 2 - 0.05 + rand() * 0.32;
    const t = tubeAt(v);
    const rr = R + t * Math.cos(v);
    const y  = t * Math.sin(v) + 0.0012;
    add(sprinkle(Math.cos(u) * rr, y, Math.sin(u) * rr, rand() * Math.PI),
        i % 2 ? BLUE : WHITE);
  }

  const mesh = finish(parts);
  mesh.geometry.translate(0, TUBE, 0);

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
