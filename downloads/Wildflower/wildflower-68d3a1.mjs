/*
 * Wildflower
 * https://polyfork.dev/asset/wildflower-68d3a1
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wildflower-68d3a1.mjs';
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
 * OPTIONS  createAsset({ ... })
 *
 *   colorway  choice  'meadow-gold'  'meadow-gold' | 'poppy-red' | 'thistle-violet' | 'snow-daisy'
 *   stage     choice  'bloom'        'bud' | 'bloom' | 'seed'
 *   tallness  range   1              0.6 to 1.15
 *   petals    range   12             9 to 16
 *   nod       range   95             25 to 115
 *   petal     color   '#f0c05a'      any hex or THREE.Color
 *   disc      color   '#e2833f'      any hex or THREE.Color
 *   stem      color   '#5f9a4b'      any hex or THREE.Color
 *   leaf      color   '#3d6b34'      any hex or THREE.Color
 *   calyx     color   '#2f4f2e'      any hex or THREE.Color
 *
 * Every option is described in full at https://polyfork.dev/cdn/wildflower-68d3a1-params.json
 *
 * SPECS  405 triangles, 1 material, 0.15 x 0.4 x 0.15 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const TAU = Math.PI * 2;

const COLORWAYS = {
  'meadow-gold':    { petal: '#f0c05a', disc: '#e2833f', stem: '#5f9a4b', leaf: '#3d6b34', calyx: '#2f4f2e' },
  'poppy-red':      { petal: '#c94f3d', disc: '#4a3527', stem: '#4c8140', leaf: '#2f4f2e', calyx: '#25402c' },
  'thistle-violet': { petal: '#b8577f', disc: '#7a5a8e', stem: '#6f8f3c', leaf: '#4c8140', calyx: '#2f4f2e' },
  'snow-daisy':     { petal: '#f4ece0', disc: '#f0c05a', stem: '#77b258', leaf: '#3d6b34', calyx: '#25402c' },
};
export const presets = COLORWAYS;

const ZONES = ['petal', 'disc', 'stem', 'leaf', 'calyx'];

export const params = {
  colorway: {
    type: 'choice', default: 'meadow-gold', label: 'Species',
    options: ['meadow-gold', 'poppy-red', 'thistle-violet', 'snow-daisy'],
    describe: 'which wildflower this is; only the five albedos change, the geometry is identical. meadow-gold (default) is the warm golden petal round an amber centre on mid-green foliage. poppy-red is a hot red bloom round a dark brown eye on deeper green. thistle-violet is a pink-violet bloom round a muted purple eye on a yellow-green stalk. snow-daisy is a cream-white bloom round a golden eye on a bright light-green stalk.',
  },
  stage: {
    type: 'choice', default: 'bloom', affects: 'geometry', label: 'Stage',
    options: ['bud', 'bloom', 'seed'],
    describe: 'the same plant at three moments of its season; height and footprint barely move, the triangle count drops hard at bud and seed. bud: no petals at all, the head is a closed pointed green ovoid with just a sliver of species colour at its tip and the plant reads as a green stalk with a knob on it. bloom (default): both petal rings open into the full 0.13 m nodding head. seed: the petals have dropped and the centre has swollen into a rounded seed head standing on the bare calyx.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.6, max: 1.15, affects: 'geometry', label: 'Tallness',
    describe: 'REBUILDS the stalk instead of scaling it: the stalk is a chain of nodes at a constant 0.064 m pitch and this knob changes HOW MANY — 3 nodes at 0.6 (a squat 0.27 m meadow flower), 4 in the middle, 5 at the default 1.0 (the 0.40 m plant of the brief), 6 at 1.15. The stalk section, the leaf pair, the head diameter and every petal stay exactly the same size at every value, so a scattered run of these reads as one species at different ages. Height quantizes in 0.064 m steps and the triangle count steps with it.',
  },
  petals: {
    type: 'range', default: 12, min: 9, max: 16, step: 1, affects: 'geometry', label: 'Petal count',
    describe: 'how many petals in the broad outer ring; the short inner ring always carries five fewer. 9 is a sparse open star with wide gaps of the centre disc showing between chunky planks, 16 is a dense overlapping daisy whose petals touch edge to edge. The head DIAMETER never changes, only how crowded the ring is.',
  },
  nod: {
    type: 'range', default: 95, min: 25, max: 115, affects: 'geometry', label: 'Nod',
    describe: 'how far the head hangs over, in DEGREES off vertical, and the whole neck follows it: the stalk hooks over in a crook through this angle and the head is seated on the outside of the hook, so the flower always faces where the crook points. 25 is the literal reading of the one-line brief — an almost upright cup whose face you see from above. At the default 95 the head has nodded right over as the reference turnaround shows it: the face aims level at the viewer and the petal bell hangs under the crook. 115 is a heavy overblown bloom drooping toward the ground. The foot of the stalk stays dead plumb at every value.',
  },
  petal: { type: 'color', default: '#f0c05a', label: 'Petal', describe: 'albedo of every petal in both rings, and of the colour sliver at the tip of a bud' },
  disc:  { type: 'color', default: '#e2833f', label: 'Centre disc', describe: 'albedo of the domed centre of the flower, and of the swollen seed head at stage seed' },
  stem:  { type: 'color', default: '#5f9a4b', label: 'Stalk', describe: 'albedo of the stalk and its swollen nodes' },
  leaf:  { type: 'color', default: '#3d6b34', label: 'Leaf', describe: 'albedo of the two lance leaf blades; a clear value step darker than the stalk' },
  calyx: { type: 'color', default: '#2f4f2e', label: 'Calyx', describe: 'albedo of the green cup under the flower head and of the closed bud' },
};

export const rig = {};
export const detach = [];
export const night = {};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
const roll = (seed) => prng(seed)();

function ngonCap(r, segs, y, up) {
  const pos = [];
  const p = (i) => [Math.sin((i / segs) * TAU) * r, y, Math.cos((i / segs) * TAU) * r];
  const c = [0, y, 0];
  for (let i = 0; i < segs; i++) {
    const a = p(i), b = p((i + 1) % segs);
    if (up) tri(pos, c, a, b); else tri(pos, c, b, a);
  }
  return posGeo(pos);
}

function coneCap(r, segs, y, apexY) {
  const pos = [];
  const p = (i) => [Math.sin((i / segs) * TAU) * r, y, Math.cos((i / segs) * TAU) * r];
  const apex = [0, apexY, 0];
  for (let i = 0; i < segs; i++) tri(pos, apex, p(i), p((i + 1) % segs));
  return posGeo(pos);
}

function tubeGeo(stations, segs) {
  const P = stations.map((s) => new THREE.Vector3(s.x, s.y, s.z));
  const ux = new THREE.Vector3(1, 0, 0);
  const ring = (k) => {
    const a = P[Math.max(0, k - 1)], b = P[Math.min(P.length - 1, k + 1)];
    const d = new THREE.Vector3().subVectors(b, a).normalize();
    const v = new THREE.Vector3().crossVectors(ux, d).normalize();
    const out = [];
    for (let i = 0; i < segs; i++) {
      const t = (i / segs) * TAU, r = stations[k].r;
      const s = Math.sin(t) * r, c = Math.cos(t) * r;
      out.push([P[k].x + ux.x * s + v.x * c, P[k].y + v.y * c, P[k].z + v.z * c]);
    }
    return out;
  };
  const pos = [];
  let lo = ring(0);
  for (let k = 1; k < stations.length; k++) {
    const hi = ring(k);
    for (let i = 0; i < segs; i++) {
      const j = (i + 1) % segs;
      quad(pos, lo[i], lo[j], hi[j], hi[i]);
    }
    lo = hi;
  }
  return posGeo(pos);
}

function leafGeo({ len, stations, rise, drop, cup, thick }) {
  const N = stations.length;
  const M = [], R = [], L = [], Mb = [];
  for (let i = 0; i < N; i++) {
    const s = stations[i], t = s.t;
    const z = t * len;
    const y = (rise * t - drop * t * t) * len;
    const wR = s.wR * len, wL = s.wL * len;
    M.push([0, y, z]);
    Mb.push([0, (wR > 0 || wL > 0) ? y - thick : y, z]);
    R.push([wR, y - cup * wR, z]);
    L.push([-wL, y - cup * wL, z]);
  }
  const pos = [];
  for (let i = 0; i < N - 1; i++) {
    const j = i + 1;
    const rI = stations[i].wR > 0, rJ = stations[j].wR > 0;
    const lI = stations[i].wL > 0, lJ = stations[j].wL > 0;
    if (rI && rJ) { tri(pos, M[i], R[j], R[i]); tri(pos, M[i], M[j], R[j]); }
    else if (rJ) tri(pos, M[i], M[j], R[j]);
    else if (rI) tri(pos, M[i], M[j], R[i]);
    if (lI && lJ) { tri(pos, M[i], L[i], L[j]); tri(pos, M[i], L[j], M[j]); }
    else if (lJ) tri(pos, M[i], L[j], M[j]);
    else if (lI) tri(pos, M[i], L[i], M[j]);
    if (rI && rJ) { tri(pos, Mb[i], R[i], R[j]); tri(pos, Mb[i], R[j], Mb[j]); }
    else if (rJ) tri(pos, Mb[i], R[j], Mb[j]);
    else if (rI) tri(pos, Mb[i], R[i], Mb[j]);
    if (lI && lJ) { tri(pos, Mb[i], L[j], L[i]); tri(pos, Mb[i], Mb[j], L[j]); }
    else if (lJ) tri(pos, Mb[i], Mb[j], L[j]);
    else if (lI) tri(pos, Mb[i], Mb[j], L[i]);
  }
  return posGeo(pos);
}

const mkStations = (T, W) => T.map((t, i) => ({ t, wR: W[i], wL: W[i] }));
const mirrorStations = (st) => st.map((s) => ({ t: s.t, wR: s.wL, wL: s.wR }));

function placeLeaf(geo, az, pitch, y, r, zOff = 0) {
  geo.rotateX(-pitch);
  geo.rotateY(az);
  geo.translate(Math.sin(az) * r, y, zOff + Math.cos(az) * r);
  return geo;
}

function whorl(n, phase) {
  const az = [];
  for (let i = 0; i < n; i++) {
    const a = phase + (i / n) * TAU;
    az.push(((a + Math.PI) % TAU + TAU) % TAU - Math.PI);
  }
  const mag = az.map((a) => Math.round(Math.abs(a) * 1e5));
  const uniq = [...new Set(mag)].sort((a, b) => a - b);
  const pair = mag.map((m) => uniq.indexOf(m));
  return { az, pair };
}

function petalGeo(rIn, rOut, wBase, wTip, ridgeH, tipDrop) {
  const L = rOut - rIn;
  const A = [wBase, 0, rIn], B = [-wBase, 0, rIn];
  const C = [wTip, tipDrop, rOut], D = [-wTip, tipDrop, rOut];
  const Rb = [0, ridgeH, rIn + L * 0.25];
  const Rt = [0, tipDrop + ridgeH * 0.55, rOut];
  const pos = [];
  tri(pos, A, Rb, Rt); tri(pos, A, Rt, C);
  tri(pos, B, Rt, Rb); tri(pos, B, D, Rt);
  tri(pos, C, Rt, D);
  tri(pos, A, C, D); tri(pos, A, D, B);
  return posGeo(pos);
}

function placePetal(geo, az, pitch) {
  geo.rotateX(-pitch);
  geo.rotateY(az);
  return geo;
}

const NODE_PITCH = 0.064;
const R_STEM_FOOT = 0.0068;
const R_STEM_TOP = 0.0050;
const STEM_SEG = 6;
const HEAD_R = 0.065;
const LEAF_Y = 0.062;
const NECK_N = 3;
const NECK_STEP = 0.015;

const LEAF_T = [0, 0.22, 0.50, 0.78, 1];
const LEAF_W = [0, 0.250, 0.280, 0.190, 0];

const DISC = [[0.019, 0.014], [0.022, 0.023], [0.019, 0.031], [0.011, 0.036]];
const DISC_APEX = 0.039;

function profileR(prof, y) {
  if (y <= prof[0][1]) return prof[0][0];
  for (let i = 1; i < prof.length; i++) {
    if (y <= prof[i][1]) {
      const [r0, y0] = prof[i - 1], [r1, y1] = prof[i];
      return r0 + (r1 - r0) * ((y - y0) / (y1 - y0));
    }
  }
  return 0;
}

function seatPetal(prof, rIn, y0, halfW, pitch, margin = 0.0035) {
  let r = rIn;
  for (let i = 0; i < 60 && r > 0.003; i++) {
    const y = y0 + r * Math.sin(pitch);
    const corner = Math.hypot(halfW, r * Math.cos(pitch));
    if (corner + margin <= profileR(prof, y)) break;
    r -= 0.0005;
  }
  return r;
}

export function createAsset(opts = {}) {
  const P = {
    colorway: params.colorway.default,
    stage: params.stage.default,
    tallness: params.tallness.default,
    petals: params.petals.default,
    nod: params.nod.default,
    ...opts,
  };
  const cw = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  const C = { ...cw };
  for (const z of ZONES) if (opts[z] !== undefined) C[z] = opts[z];

  const stage = ['bud', 'bloom', 'seed'].includes(P.stage) ? P.stage : 'bloom';
  const tall = Math.min(1.15, Math.max(0.6, P.tallness));
  const nOuter = Math.max(9, Math.min(16, Math.round(P.petals)));
  const nodes = Math.max(3, Math.min(6, Math.round(5 * tall)));
  const nod = (Math.min(115, Math.max(25, P.nod)) * Math.PI) / 180;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const H = nodes * NODE_PITCH;
  const bow = 0.026 + nod * 0.020;
  const bz = (y) => bow * Math.pow(Math.max(0, y) / H, 2.6);
  const rAt = (y) => R_STEM_FOOT + (R_STEM_TOP - R_STEM_FOOT) * (y / H);

  const stations = [];
  for (let k = 0; k <= nodes; k++) {
    const y = k * NODE_PITCH;
    const swell = k === 0 ? 1.12 : (k % 2 ? 1.08 : 0.99);
    stations.push({ x: 0, y, z: bz(y), r: rAt(y) * swell });
    if (k >= nodes - 2 && k < nodes) {
      const ym = y + NODE_PITCH * 0.5;
      stations.push({ x: 0, y: ym, z: bz(ym), r: rAt(ym) * 0.89 });
    }
  }

  const lean = Math.atan((2.6 * bow) / H);
  let nx = 0, ny = H, nz = bz(H);
  for (let k = 1; k <= NECK_N; k++) {
    const ang = lean + (nod - lean) * ((k - 0.5) / NECK_N);
    ny += Math.cos(ang) * NECK_STEP;
    nz += Math.sin(ang) * NECK_STEP;
    stations.push({ x: nx, y: ny, z: nz, r: R_STEM_TOP * (0.95 - 0.15 * (k / NECK_N)) });
  }
  add(tubeGeo(stations, STEM_SEG), C.stem);
  add(ngonCap(R_STEM_FOOT * 1.12, STEM_SEG, 0, false), C.stem);

  const headY = ny - Math.cos(nod) * 0.012;
  const headZ = nz - Math.sin(nod) * 0.012;

  const baseSt = mkStations(LEAF_T, LEAF_W);
  const spread = Math.PI / 2 - 0.35;
  for (const az of [spread, -spread]) {
    const g = leafGeo({
      len: 0.082, stations: az < 0 ? mirrorStations(baseSt) : baseSt,

      rise: 0.58, drop: 0.44, cup: 0.13, thick: 0.007,
    });
    add(placeLeaf(g, az, 0.30, LEAF_Y, rAt(LEAF_Y) * 0.75, bz(LEAF_Y)), C.leaf);
  }

  const head = [];
  const hAdd = (g, c) => head.push({ g, c });

  if (stage === 'bud') {

    hAdd(new THREE.LatheGeometry([
      new THREE.Vector2(0.0035, 0),
      new THREE.Vector2(0.020, 0.014),
      new THREE.Vector2(0.023, 0.036),
      new THREE.Vector2(0.011, 0.058),
    ], 7), C.calyx);
    hAdd(new THREE.LatheGeometry([
      new THREE.Vector2(0.013, 0.052),
      new THREE.Vector2(0.009, 0.066),
    ], 7), C.petal);
    hAdd(coneCap(0.009, 7, 0.066, 0.074), C.petal);
  } else {

    hAdd(new THREE.LatheGeometry([
      new THREE.Vector2(0.0035, 0),
      new THREE.Vector2(0.017, 0.007),
      new THREE.Vector2(0.023, 0.016),
      new THREE.Vector2(0.019, 0.023),
    ], 7), C.calyx);

    if (stage === 'seed') {

      hAdd(new THREE.LatheGeometry([
        new THREE.Vector2(0.014, 0.012),
        new THREE.Vector2(0.030, 0.030),
        new THREE.Vector2(0.026, 0.050),
        new THREE.Vector2(0.010, 0.062),
      ], 8), C.disc);
      hAdd(coneCap(0.010, 8, 0.062, 0.068), C.disc);
    } else {

      hAdd(new THREE.LatheGeometry(DISC.map(([r, y]) => new THREE.Vector2(r, y)), 8), C.disc);
      hAdd(coneCap(DISC[DISC.length - 1][0], 8, DISC[DISC.length - 1][1], DISC_APEX), C.disc);

      const wo = whorl(nOuter, 0);

      const wBaseO = Math.min(0.011, (TAU * 0.044 / nOuter) * 0.44);
      const wTipO = Math.min(0.0150, (TAU * HEAD_R / nOuter) * 0.47);
      for (let i = 0; i < nOuter; i++) {
        const jr = roll(211 + wo.pair[i] * 37);
        const front = wo.pair[i] % 2 === 0;
        const pitch = (front ? 0.38 : 0.46) + jr * 0.05;
        const yOuter = front ? 0.019 : 0.024;
        const rIn = seatPetal(DISC, 0.024, yOuter, wBaseO, pitch, 0.003);
        const g = petalGeo(rIn, HEAD_R * (0.97 + jr * 0.06), wBaseO, wTipO, 0.006, -0.005);
        hAdd(placePetal(g, wo.az[i], pitch).translate(0, yOuter, 0), C.petal);
      }

      const nInner = Math.max(5, nOuter - 5);
      const wi = whorl(nInner, Math.PI / nInner);
      const yInner = 0.029;
      const wBaseI = Math.min(0.008, (TAU * 0.030 / nInner) * 0.44);
      const wTipI = Math.min(0.0110, (TAU * 0.034 / nInner) * 0.47);
      for (let i = 0; i < nInner; i++) {
        const jr = roll(307 + wi.pair[i] * 41);
        const pitch = 0.60 + jr * 0.10;
        const rIn = seatPetal(DISC, 0.018, yInner, wBaseI, pitch, 0.003);
        const g = petalGeo(rIn, 0.034 * (0.96 + jr * 0.07), wBaseI, wTipI, 0.005, 0.000);
        hAdd(placePetal(g, wi.az[i], pitch).translate(0, yInner, 0), C.petal);
      }
    }
  }

  const m = new THREE.Matrix4()
    .makeTranslation(0, headY, headZ)
    .multiply(new THREE.Matrix4().makeRotationX(nod));
  for (const p of head) add(p.g.applyMatrix4(m), p.c);

  return assemble(parts);
}

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

function assemble(parts) {
  const merged = mergeGeometries(parts.map((p) => prep(p.g, p.c)));

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, 0, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'plant';
  const g = new THREE.Group();
  g.name = 'wildflower';
  g.add(mesh);
  return g;
}

export default createAsset;
