/*
 * Briefcase
 * https://polyfork.dev/asset/briefcase-fbb052
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './briefcase-fbb052.mjs';
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
 * SPECS  332 triangles, 1 material, 0.4 x 0.36 x 0.11 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const C = {
  dark:  0x3F4247,
  brown: 0x8A5A44,
};

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function pushFace(out, pts, want) {
  const [a, b, c] = pts;
  const u = [b[0]-a[0], b[1]-a[1], b[2]-a[2]];
  const v = [c[0]-b[0], c[1]-b[1], c[2]-b[2]];
  const n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]];
  const q = (n[0]*want[0] + n[1]*want[1] + n[2]*want[2] < 0) ? pts.slice().reverse() : pts;
  if (q.length === 3) tri(out, q[0], q[1], q[2]);
  else quad(out, q[0], q[1], q[2], q[3]);
}

function chamferBox(w, h, d, c, cx, cy, cz) {
  const H = [w/2, h/2, d/2];
  const pos = [];
  const S = [1, -1];

  const V = (i, s, u, v) => {
    const j = (i+1) % 3, k = (i+2) % 3;
    const p = [0, 0, 0];
    p[i] = s * H[i]; p[j] = u * (H[j] - c); p[k] = v * (H[k] - c);
    return [p[0] + cx, p[1] + cy, p[2] + cz];
  };
  for (let i = 0; i < 3; i++) {
    const j = (i+1) % 3;
    for (const si of S) {
      const nf = [0, 0, 0]; nf[i] = si;
      pushFace(pos, [V(i,si, 1, 1), V(i,si,-1, 1), V(i,si,-1,-1), V(i,si, 1,-1)], nf);
      for (const sj of S) {
        const ne = [0, 0, 0]; ne[i] = si; ne[j] = sj;
        pushFace(pos, [V(i,si,sj, 1), V(i,si,sj,-1), V(j,sj,-1,si), V(j,sj, 1,si)], ne);
      }
    }
  }
  for (const sx of S) for (const sy of S) for (const sz of S) {
    pushFace(pos, [V(0,sx,sy,sz), V(1,sy,sz,sx), V(2,sz,sx,sy)], [sx, sy, sz]);
  }
  return posGeo(pos);
}

function taperBox(bw, bd, tw, td, y0, y1, cx, cz) {
  const pos = [];
  const b = [[-bw/2,y0,-bd/2],[bw/2,y0,-bd/2],[bw/2,y0,bd/2],[-bw/2,y0,bd/2]];
  const t = [[-tw/2,y1,-td/2],[tw/2,y1,-td/2],[tw/2,y1,td/2],[-tw/2,y1,td/2]];
  const o = (p) => [p[0]+cx, p[1], p[2]+cz];
  for (let i = 0; i < 4; i++) {
    const i2 = (i+1) % 4;
    const m = [b[i][0]+b[i2][0]+t[i][0]+t[i2][0], 0, b[i][2]+b[i2][2]+t[i][2]+t[i2][2]];
    pushFace(pos, [o(b[i]), o(b[i2]), o(t[i2]), o(t[i])], m);
  }
  pushFace(pos, [o(t[0]), o(t[1]), o(t[2]), o(t[3])], [0, 1, 0]);
  pushFace(pos, [o(b[0]), o(b[1]), o(b[2]), o(b[3])], [0, -1, 0]);
  return posGeo(pos);
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

const SEAM = 0.185;
const LID_W = 0.400, LID_D = 0.095;
const BODY_W = 0.394, BODY_D = 0.089;

function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  add(chamferBox(BODY_W, SEAM, BODY_D, 0.014, 0, SEAM / 2, 0), C.dark);
  add(chamferBox(LID_W, 0.075, LID_D, 0.012, 0, SEAM + 0.0375, 0), C.dark);

  add(box(0.404, 0.024, 0.099, 0, 0.012, 0), C.brown);

  const grip = new THREE.CylinderGeometry(0.013, 0.013, 0.106, 10);
  grip.rotateZ(Math.PI / 2);
  grip.scale(1, 0.85, 1);
  grip.translate(0, 0.345, 0);
  add(grip, C.dark);
  for (const s of [1, -1]) {
    add(taperBox(0.030, 0.028, 0.022, 0.022, 0.264, 0.348, s * 0.044, 0), C.dark);
    add(box(0.036, 0.010, 0.036, s * 0.044, 0.264, 0), C.brown);
  }

  for (const s of [1, -1]) {
    const x = s * 0.106;
    add(box(0.042, 0.034, 0.010, x, 0.202, 0.0515), C.brown);
    add(box(0.042, 0.024, 0.010, x, 0.173, 0.0485), C.brown);
    const barrel = new THREE.CylinderGeometry(0.008, 0.008, 0.046, 6);
    barrel.rotateZ(Math.PI / 2);
    barrel.translate(x, 0.218, 0.0525);
    add(barrel, C.brown);
  }

  for (const sx of [1, -1]) for (const sz of [1, -1]) {
    add(box(0.036, 0.045, 0.008, sx * 0.179, 0.048, sz * 0.0475), C.brown);
  }

  const g = new THREE.Group();
  g.name = 'briefcase';
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];
export default createAsset;
