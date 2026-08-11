/*
 * Fallen Log
 * https://polyfork.dev/asset/fallen-log-1685fb
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './fallen-log-1685fb.mjs';
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
 *   colorway  choice  'oak-fallen'   'oak-fallen' | 'dark-damp' | 'pale-birch' | 'sun-dried'
 *   bark      color   '#8c6a47'      any hex or THREE.Color
 *   endGrain  color   '#c2a479'      any hex or THREE.Color
 *   heart     color   '#a5855e'      any hex or THREE.Color
 *   length    range   1              0.55 to 1.15
 *   girth     range   1              0.68 to 1.45
 *   facets    range   10             6 to 12
 *   stubs     range   1              1 to 3
 *
 * Every option is described in full at https://polyfork.dev/cdn/fallen-log-1685fb-params.json
 *
 * SPECS  484 triangles, 1 material, 3.09 x 0.9 x 0.7 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'oak-fallen':  { bark: '#8c6a47', endGrain: '#c2a479', heart: '#a5855e' },
  'dark-damp':   { bark: '#5d4430', endGrain: '#a5855e', heart: '#75563b' },
  'pale-birch':  { bark: '#bcb9b1', endGrain: '#e0d2b4', heart: '#c2a479' },
  'sun-dried':   { bark: '#a5855e', endGrain: '#e0d2b4', heart: '#c2a479' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'oak-fallen', label: 'Colorway',
    options: ['oak-fallen', 'dark-damp', 'pale-birch', 'sun-dried'],
    describe: 'Curated Nature & Forest timber schemes; sets all three zones at once. ' +
      'oak-fallen is the shipped build — mid warm-brown bark with a pale cream sawn ' +
      'face. dark-damp is a shaded waterlogged log, near-chocolate bark with only a ' +
      'muted step up on the cut ends. pale-birch turns the barrel silver-grey with a ' +
      'bone-cream end grain, a birch trunk down in the same forest. sun-dried is old ' +
      'sun-bleached timber, light tan bark under an almost white cut face. Every ' +
      'scheme keeps the cut faces clearly LIGHTER than the bark, which is what makes ' +
      'the ends read as freshly sawn.',
  },
  bark: {
    type: 'color', default: '#8c6a47', label: 'Bark',
    describe: 'Albedo of the whole outer barrel and of every branch-stub shaft — about ' +
      '70% of the asset. A log is one material, so this single tone carries all of it; ' +
      'there is no second bark tone and no painted grain.',
  },
  endGrain: {
    type: 'color', default: '#c2a479', label: 'Sawn end grain',
    describe: 'Albedo of the broad SUNKEN field inside both cut faces — the pale heart ' +
      'of the timber the saw exposed. Keep it the lightest of the three: it sits at the ' +
      'bottom of a 30 mm recess, so a tone level with the bark shades down into a dark ' +
      'blank hole and the concentric end-grain rings stop reading.',
  },
  heart: {
    type: 'color', default: '#a5855e', label: 'Rim and break faces',
    describe: 'Albedo of the sawn chamfer, the rim band around each cut face, the small ' +
      'centre pip, and the break face capping every branch stub. It is the middle rung ' +
      'between Bark and Sawn end grain — matched to either one, the cut end collapses ' +
      'from three concentric rings to one flat disc.',
  },
  length: {
    type: 'range', default: 1.0, min: 0.55, max: 1.15, step: 0.01, label: 'Length',
    affects: 'geometry',
    describe: 'How long the log is, REBUILT rather than stretched: stations are added ' +
      'along the barrel at a constant 0.33 m pitch, so the triangle count moves with ' +
      'the knob and the bow keeps the same curvature per metre. 0.55 is a 1.65 m ' +
      'section barely three diameters long, a chunk cut for firewood; 1.0 is the ' +
      'approved 3 m log; 1.15 is a 3.45 m trunk length. Girth, end relief and the ' +
      'branch stubs keep their real size, so a short log reads crowded with detail and ' +
      'a long one sparse.',
  },
  girth: {
    type: 'range', default: 1.0, min: 0.68, max: 1.45, step: 0.01, label: 'Girth',
    affects: 'geometry',
    describe: 'Thickness of the barrel. 0.68 is a slim 0.36 m pole that reads as a ' +
      'fallen sapling; 1.0 is the approved 0.53 m log; 1.45 is a 0.77 m bole from a ' +
      'mature tree. There is nothing repeating across a trunk\'s girth, so this one ' +
      'honestly resizes the section instead of adding structure — the end relief and ' +
      'the stub bases are derived from the profile, so they follow it exactly.',
  },
  facets: {
    type: 'range', default: 10, min: 6, max: 12, step: 1, label: 'Facets',
    affects: 'geometry',
    describe: 'Number of flat stave columns around the barrel, which is also the number ' +
      'of sides on the sawn end polygon. 6 is a chunky hexagonal beam with broad planks ' +
      'and a blocky end hexagon; 10 is the approved log; 12 is nearly round and reads ' +
      'as a smoother, younger trunk. Whatever the count, one whole column is pinned ' +
      'flat on the ground so the log never balances on an edge.',
  },
  stubs: {
    type: 'range', default: 1, min: 1, max: 3, step: 1, label: 'Branch stubs',
    affects: 'geometry',
    describe: 'How many broken branch stubs stand off the barrel. 1 is the approved log ' +
      '— a single forked stub on the +Z flank at about a third of the length. 2 adds a ' +
      'shorter one leaning back over the far half, 3 a third near the butt end, so the ' +
      'skyline is broken in three places and the log reads as a limbed-out trunk rather ' +
      'than a clean length of timber. Each stub is capped with its own break face.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const cross = (a, b) => [
  a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0],
];
function norm(a) {
  const l = Math.hypot(a[0], a[1], a[2]) || 1;
  return [a[0] / l, a[1] / l, a[2] / l];
}

function frameAt(t, up) {
  const T = norm(t);
  const u = norm(cross(up, T));
  return [u, cross(T, u)];
}

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['oak-fallen'];
  const pick = (k) => userParams[k] ?? (userParams.colorway ? way[k] : params[k].default);
  const C = { bark: pick('bark'), endGrain: pick('endGrain'), heart: pick('heart') };

  const N = Math.max(6, Math.min(12, Math.round(P.facets)));
  const GIRTH = P.girth;
  const STUBS = Math.max(1, Math.min(3, Math.round(P.stubs)));

  const LEN = 3.00 * P.length;

  const PITCH = 0.28;
  const ST = Math.max(6, Math.min(15, Math.round(LEN / PITCH) + 1));

  const TRIS = [];
  const tri = (a, b, c, z) => TRIS.push({ p: [a, b, c], z });
  const quad = (a, b, c, d, z) => { tri(a, b, c, z); tri(a, c, d, z); };

  function ringAt(c, u, v, radii, phase) {
    const n = radii.length, out = [];
    const ang = typeof phase === 'function' ? phase : (j) => phase + (j / n) * Math.PI * 2;
    for (let j = 0; j < n; j++) {
      const a = ang(j);
      const ca = Math.cos(a) * radii[j], sa = Math.sin(a) * radii[j];
      out.push([
        c[0] + u[0] * ca + v[0] * sa,
        c[1] + u[1] * ca + v[1] * sa,
        c[2] + u[2] * ca + v[2] * sa,
      ]);
    }
    return out;
  }

  function skin(rings, z) {
    const n = rings[0].length;
    for (let i = 0; i + 1 < rings.length; i++) {
      for (let j = 0; j < n; j++) {
        const k = (j + 1) % n;
        quad(rings[i][j], rings[i][k], rings[i + 1][k], rings[i + 1][j], z);
      }
    }
  }
  const centroid = (r) => {
    const c = [0, 0, 0];
    for (const p of r) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
    return [c[0] / r.length, c[1] / r.length, c[2] / r.length];
  };

  function capFwd(r, apex, z) {
    for (let j = 0; j < r.length; j++) tri(apex, r[j], r[(j + 1) % r.length], z);
  }

  function capBack(r, apex, z) {
    for (let j = 0; j < r.length; j++) tri(apex, r[(j + 1) % r.length], r[j], z);
  }

  const APO = Math.cos(Math.PI / N);

  const PHASE = -Math.PI / 2 - Math.PI / N;

  const R0 = 0.265 * GIRTH;

  const logR = (t) => R0 * (1 - 0.130 * t) * (1 + 0.048 * Math.sin(4.1 * t + 0.6));

  const staveRaw = (j) => {
    const a = PHASE + (j / N) * Math.PI * 2;
    return 1 + 0.155 * Math.sin(2 * a + 1.3) + 0.085 * Math.sin(3 * a + 2.9);
  };

  const skew = (j) => 0.22 * (Math.PI / N) * (Math.sin(2.7 * j + 1.9) + 0.6 * Math.sin(4.3 * j));

  const pinned = (j) => j === 0 || j === 1;
  const stave = (j) => (pinned(j) ? 1 : staveRaw(j));
  const angleOf = (j) => PHASE + (j / N) * Math.PI * 2 + (pinned(j) ? 0 : skew(j));

  const bowZ = (t) => (0.135 * P.length) * (Math.sin(Math.PI * (t * 0.92 + 0.10)) - 0.63);

  const path = (t) => [(t - 0.5) * LEN, logR(t) * APO, bowZ(t)];

  function frameOf(t) {
    const e = 0.004;
    const T = norm(sub(path(Math.min(1, t + e)), path(Math.max(0, t - e))));
    const [u, v] = frameAt(T, [0, 1, 0]);
    return { T, u, v };
  }
  function ringOf(t) {
    const { u, v } = frameOf(t);
    const radii = [];
    for (let j = 0; j < N; j++) radii.push(logR(t) * stave(j));
    return ringAt(path(t), u, v, radii, angleOf);
  }

  const rings = [];
  for (let i = 0; i < ST; i++) rings.push(ringOf(i / (ST - 1)));

  {
    const y0 = path(0)[1];
    for (const p of rings[0]) p[0] += 0.115 * (p[1] - y0);
  }

  skin(rings, 'bark');

  const END_RINGS = [
    { s: 0.930, d: 0.012, z: 'heart' },
    { s: 0.720, d: 0.032, z: 'heart' },
    { s: 0.300, d: 0.038, z: 'endGrain' },

    { s: 0.230, d: 0.032, z: 'heart' },
  ];
  function sawnEnd(t, sign) {
    const { T } = frameOf(t);
    const ring = rings[sign > 0 ? ST - 1 : 0];
    const c = centroid(ring);
    const stack = [ring];
    for (const R of END_RINGS) {
      stack.push(ring.map((p) => [
        c[0] + (p[0] - c[0]) * R.s - T[0] * R.d * sign,
        c[1] + (p[1] - c[1]) * R.s - T[1] * R.d * sign,
        c[2] + (p[2] - c[2]) * R.s - T[2] * R.d * sign,
      ]));
    }

    for (let i = 0; i < END_RINGS.length; i++) {
      const pair = [stack[i], stack[i + 1]];
      skin(sign > 0 ? pair : [pair[1], pair[0]], END_RINGS[i].z);
    }

    const inner = stack[stack.length - 1];
    (sign > 0 ? capFwd : capBack)(inner, centroid(inner), 'heart');
  }
  sawnEnd(1, 1);
  sawnEnd(0, -1);

  function limb(base, dir, bend, reach, rb, seg, sides, ref) {
    const d0 = norm(dir);
    const at = (s) => [
      base[0] + d0[0] * reach * s + bend[0] * s * s,
      base[1] + d0[1] * reach * s + bend[1] * s * s,
      base[2] + d0[2] * reach * s + bend[2] * s * s,
    ];
    const rs = [];
    let lastT = d0;
    for (let i = 0; i <= seg; i++) {
      const s = i / seg;
      const T = norm(sub(at(Math.min(1, s + 0.02)), at(Math.max(0, s - 0.02))));
      lastT = T;
      const [u, v] = frameAt(T, ref);
      const r = rb * (1 - 0.40 * s) * (1 + 0.09 * Math.sin(3.1 * s + 1.4));
      const radii = [];
      for (let j = 0; j < sides; j++) {
        radii.push(r * (1 + 0.11 * Math.sin(2 * (j / sides) * Math.PI * 2 + 0.7)));
      }
      rs.push(ringAt(at(s), u, v, radii, 0.30));
    }
    skin(rs, 'bark');

    const tip = rs[seg], tc = centroid(tip);
    capFwd(tip, [tc[0] + lastT[0] * 0.016, tc[1] + lastT[1] * 0.016, tc[2] + lastT[2] * 0.016], 'heart');
    return { at, tc, T: lastT };
  }

  const STUB_DEFS = [
    { t: 0.36, dir: [0.16, 0.94, 0.30], bend: [0.05, 0.00, 0.05], len: 0.40, rb: 0.058,
      prong: { at: 0.30, dir: [-0.46, 0.83, 0.32], len: 0.20, rb: 0.038 } },
    { t: 0.70, dir: [-0.21, 0.93, -0.30], bend: [-0.04, 0.00, -0.04], len: 0.29, rb: 0.050,
      prong: { at: 0.28, dir: [0.44, 0.85, -0.29], len: 0.15, rb: 0.033 } },
    { t: 0.16, dir: [0.09, 0.90, -0.43], bend: [0.03, 0.00, -0.04], len: 0.22, rb: 0.045,
      prong: null },
  ];

  for (let s = 0; s < STUBS; s++) {
    const S = STUB_DEFS[s];
    const c = path(S.t);
    const d0 = norm(S.dir);
    const rb = S.rb * GIRTH;

    const start = logR(S.t) * 0.82;
    const base = [c[0] + d0[0] * start, c[1] + d0[1] * start, c[2] + d0[2] * start];
    const reach = S.len + logR(S.t) * 0.20;
    const main = limb(base, S.dir, S.bend, reach, rb, 3, 6, [1, 0, 0]);

    {
      const [cu, cv] = frameAt(d0, [1, 0, 0]);
      const collarRing = (s, k) => {
        const radii = [];
        for (let j = 0; j < 6; j++) radii.push(rb * k * (1 + 0.13 * Math.sin(2.2 * j + 1.1)));
        return ringAt(main.at(s), cu, cv, radii, 0.30);
      };

      skin([collarRing(0.00, 2.00), collarRing(0.30, 0.82)], 'bark');
    }

    if (S.prong) {

      const o = main.at(S.prong.at);
      const pd = norm(S.prong.dir);

      const pb = [o[0] - pd[0] * rb * 1.3, o[1] - pd[1] * rb * 1.3, o[2] - pd[2] * rb * 1.3];
      limb(pb, S.prong.dir, [0.01, 0.00, 0.01], S.prong.len + rb * 1.3,
        S.prong.rb * GIRTH, 2, 6, [1, 0, 0]);
    }
  }

  let mnx = Infinity, mxx = -Infinity, mny = Infinity, mnz = Infinity, mxz = -Infinity;
  for (const T of TRIS) for (const p of T.p) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[1] < mny) mny = p[1];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
  }
  const ox = (mnx + mxx) / 2, oz = (mnz + mxz) / 2, oy = mny;

  const pos = [], col = [];
  const tmp = new THREE.Color();
  const put = (p) => pos.push(p[0] - ox, p[1] - oy, p[2] - oz);
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b); };

  const ZONE = { bark: C.bark, endGrain: C.endGrain, heart: C.heart };
  for (const T of TRIS) {
    for (const p of T.p) put(p);
    paint(ZONE[T.z] || C.bark);
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'log';

  const g = new THREE.Group();
  g.name = 'fallen-log';
  g.add(mesh);
  return g;
}

export default createAsset;
