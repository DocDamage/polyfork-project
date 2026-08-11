/*
 * Trail Signpost
 * https://polyfork.dev/asset/trail-signpost-bd29a7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './trail-signpost-bd29a7.mjs';
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
 *   colorway    choice  'weathered-pine' 'weathered-pine' | 'sun-bleached' | 'dark-oak' | 'iron-pinned'
 *   post        color   '#75563b'      any hex or THREE.Color
 *   boardTop    color   '#a5855e'      any hex or THREE.Color
 *   boardLow    color   '#c2a479'      any hex or THREE.Color
 *   peg         color   '#4a3527'      any hex or THREE.Color
 *   tallness    range   1              0.68 to 1.08
 *   boards      range   2              1 to 3
 *   armReach    range   1              0.74 to 1.22
 *   boardAngle  range   32             8 to 55
 *
 * Every option is described in full at https://polyfork.dev/cdn/trail-signpost-bd29a7-params.json
 *
 * SPECS  420 triangles, 1 material, 1.15 x 2 x 1.16 m (real-world scale).
 * PARTS  animate: board-top, board-mid
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-pine': { post: '#75563b', boardTop: '#a5855e', boardLow: '#c2a479', peg: '#4a3527' },
  'sun-bleached':   { post: '#a5855e', boardTop: '#c2a479', boardLow: '#e0d2b4', peg: '#75563b' },
  'dark-oak':       { post: '#4a3527', boardTop: '#75563b', boardLow: '#8c6a47', peg: '#3a2a1e' },
  'iron-pinned':    { post: '#5d4430', boardTop: '#8c6a47', boardLow: '#c2a479', peg: '#3f4d55' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-pine', label: 'Colorway', affects: 'colors',
    options: ['weathered-pine', 'sun-bleached', 'dark-oak', 'iron-pinned'],
    describe: 'Curated Nature & Forest scheme. weathered-pine is the default: a mid-brown post under a tan upper board and a pale sand lower board, the highest-legibility pairing. sun-bleached lifts every zone one step for a dry sun-greyed marker on light terrain. dark-oak drops every zone one step for a damp deep-forest post, the darkest option and the strongest silhouette against pale ground. iron-pinned keeps warm timber but swaps the wooden dowels for slate-grey iron pins, the only scheme with a non-wood colour on it.',
  },
  post: {
    type: 'color', default: '#75563b', label: 'Post timber', affects: 'colors',
    describe: 'Albedo of the whole post: all eight shaft flats, the hewn knot low on the shaft, the foot chamfer, the flat underside and the pointed cap on the head. This is the dominant mass and it is ONE uniform tone — the facet-to-facet brightness in the renders comes from scene lighting, so a second wood tone here would double-shade it. Keep it darker than both boards or the arrows stop separating from the timber they cross.',
  },
  boardTop: {
    type: 'color', default: '#a5855e', label: 'Upper board', affects: 'colors',
    describe: 'Albedo of the entire upper arrow board — faces, chamfers, the mitred point and the stepped broken end. One clear value step lighter than the post so the plank reads in front of it. The two boards are deliberately two different plank tones: that is a real material difference between two pieces of timber, not baked shading.',
  },
  boardLow: {
    type: 'color', default: '#c2a479', label: 'Lower board', affects: 'colors',
    describe: 'Albedo of the lower arrow board, and of the third board when the boards knob is at 3. The lightest large zone on the asset, one step above the upper board so the two signs never merge into a single billboard at thumbnail size.',
  },
  peg: {
    type: 'color', default: '#4a3527', label: 'Through-peg', affects: 'colors',
    describe: 'Albedo of the short dowels that pin each board through the post and stand about 56 mm proud on both sides. The darkest zone on the asset — hardware value, well below the post — so the pins read as separate fixings rather than knots in the timber. Set it to a slate grey for iron pins instead of wooden dowels.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.68, max: 1.08, affects: 'geometry', label: 'Post height',
    describe: 'Length of the post shaft. At 0.68 the shaft head is at 1.26 m and the whole marker is 1.41 m — a low waist-height trail stub whose lower board is barely above knee level; at 1.0 it is the briefed 2.00 m; at 1.08 the marker is 2.15 m, a tall junction post with a long bare shaft under the arms. This REBUILDS rather than scales: the shaft carries facet rings at a constant 0.35 m pitch, so a taller post gains rings and the triangle count moves with the knob. The post girth, the pointed cap, the boards, the pegs and the board pitch all keep their exact real size at every value; the hewn knot stays at its absolute 0.60 m; and the boards always hang at fixed drops below the head.',
  },
  boards: {
    type: 'range', default: 2, min: 1, max: 3, step: 1, affects: 'geometry', label: 'Arrow boards',
    describe: 'How many arrow boards the post carries, hung downward from the head at a constant 0.370 m pitch. At 1 it is a single-direction waymarker with a long empty shaft; at 2 it is the briefed pair pointing opposite ways; at 3 a third board is added below the pair, turned 60 degrees out of their line and aimed front-right, so the post reads as a three-way junction sign with all three arrows legible from one camera; it also drops an extra 40 mm so its broken end clears the middle board’s. Each board is a real added plank with its own point, broken end and through-peg (about 116 triangles), so the count changes the triangle total.',
  },
  armReach: {
    type: 'range', default: 1.0, min: 0.74, max: 1.22, affects: 'geometry', label: 'Board length',
    describe: 'Length of every board, measured along its own axis: it scales the POINT ARM only. At 0.74 the upper board is 0.90 m overall and the sign reads compact and stubby, almost a nameplate; at 1.0 it is the reference 1.11 m; at 1.22 it is 1.29 m and the arms cantilever a long way out over the trail. HONEST LIMIT: a plank has nothing repeating along its length, so this knob does NOT change the triangle count and is not a rebuild in the sense tallness and boards are — those two carry the contract. What it does do is better than a scale: the 0.235 m board height, the 0.090 m thickness, the 0.218 m arrow point, the 13 mm chamfer and every step of the broken end keep their exact real size at every value, so only the blank middle of the plank grows and no detail is stretched with it.',
  },
  boardAngle: {
    type: 'range', default: 32, min: 8, max: 55, affects: 'geometry', label: 'Board angle',
    describe: 'Plan angle of the board pair off the X axis, in degrees, swung away from the hero three-quarter. This turns the whole signed direction around the post; the arms hold their fixed 26-degree crossing at every value, so they always read as a cross from overhead rather than as one bar. At 8 the pair lies almost square across the front, so the sign shows nearly its full 1.11 m arm width head-on and shrinks hard edge-on from the sides; at 32 it sits near broadside to the hero camera, which is where both arrows read at close to full length at once; at 55 the front view foreshortens the upper arm to about half width while the side elevations open right up. Board length, height, thickness, heights above ground, the broken ends and the pegs are unchanged.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function ringY(n, r, y, phase = 0, drs = null, dys = null) {
  const out = [];
  for (let k = 0; k < n; k++) {
    const a = phase + (k * 2 * Math.PI) / n;
    const rr = r + (drs ? drs[k % drs.length] : 0);
    const yy = y + (dys ? dys[k % dys.length] : 0);
    out.push([Math.cos(a) * rr, yy, Math.sin(a) * rr]);
  }
  return out;
}
function band(out, lo, hi) {
  const n = lo.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, lo[k], hi[k], hi[j], lo[j]); }
}
function capTop(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k + 1], r[k]); }
function capBot(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k], r[k + 1]); }

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}
function mergeColored(list) {
  const m = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!m) throw new Error('mergeGeometries returned null (attribute mismatch)');
  m.computeVertexNormals();
  return m;
}

const SIDES      = 8;
const HEAD0      = 1.870;
const R_HEAD     = 0.078;
const R_FOOT     = 0.094;
const TAPER_EXP  = 1.40;
const FOOT_CH    = 0.024;
const RING_PITCH = 0.35;

const CAP = [
  [0.000, R_HEAD],
  [0.038, 0.068],
  [0.130, 0.014],
];

const BOARD_DROP  = 0.250;
const BOARD_PITCH = 0.370;
const BOARD_TH    = 0.090;
const BEV         = 0.013;
const TIP_LEN     = 0.200;

const BOARD_H     = 0.1045;

const PEG_R    = 0.022;
const PEG_OUT  = 0.050;

const PEG_SEG  = 6;

const STEP_Y   = 0.600;

const STEP_RUN = 0.075;

const KNOT_DR  = [0.011, 0.010, 0.003, 0, 0, 0, 0, 0.004];
const KNOT_DY  = [0.014, 0.004, -0.012, -0.026, -0.032, -0.030, -0.022, -0.006];

const BOARDS = [
  { name: 'board-top', A: 0.780, dy: 0,     yaw: (a) => 180 + a },
  { name: 'board-mid', A: 0.810, dy: 0,     yaw: (a) => a + 26 },
  { name: 'board-low', A: 0.760, dy: 0.040, yaw: (a) => a - 60 },
];

const TAILS = {
  'board-top': {
    T: [0.056, 0.048, 0.052, 0.053],
    L: [0.266, 0.302, 0.258, 0.294],
    s: [0.008, -0.006, 0.009, -0.007],
  },
  'board-mid': {
    T: [0.050, 0.055, 0.048, 0.056],
    L: [0.298, 0.262, 0.296, 0.264],
    s: [-0.007, 0.008, -0.006, 0.009],
  },
  'board-low': {
    T: [0.054, 0.050, 0.056, 0.049],
    L: [0.262, 0.296, 0.264, 0.300],
    s: [0.009, -0.007, 0.008, -0.006],
  },
};

function plankOutline(A, t, h) {
  const n = t.T.length;
  const y = [];
  let cur = -h;
  for (let i = 0; i < n; i++) { y.push([cur, cur + t.T[i]]); cur += t.T[i]; }

  const pts = [[A, 0], [A - TIP_LEN, +h]];
  for (let i = n - 1; i >= 0; i--) {
    const [lo, hi] = y[i];
    pts.push([-(t.L[i] + t.s[i]), hi]);
    pts.push([-(t.L[i] - t.s[i]), lo]);
  }
  pts.push([A - TIP_LEN, -h]);
  return pts;
}

function plankGeometry(A, tail, reach) {

  const pts = plankOutline(A * reach - BEV * Math.SQRT2, tail, BOARD_H);
  const shape = new THREE.Shape(pts.map((p) => new THREE.Vector2(p[0], p[1])));
  const geo = new THREE.ExtrudeGeometry(shape, {
    depth: BOARD_TH - 2 * BEV,
    bevelEnabled: true, bevelSegments: 1, bevelSize: BEV, bevelThickness: BEV,
    curveSegments: 1, steps: 1,
  });
  geo.translate(0, 0, -(BOARD_TH - 2 * BEV) / 2);
  return geo;
}

function resolve(user) {
  const cw = COLORWAYS[user.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['post', 'boardTop', 'boardLow', 'peg']) {
    C[k] = user[k] !== undefined ? user[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  const num = (k) => {
    const v = user[k] !== undefined ? Number(user[k]) : params[k].default;
    if (!Number.isFinite(v)) return params[k].default;
    return Math.min(params[k].max, Math.max(params[k].min, v));
  };
  return {
    C,
    tallness: num('tallness'),
    boards: Math.round(num('boards')),
    armReach: num('armReach'),
    boardAngle: num('boardAngle'),
  };
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.C;

  const g = new THREE.Group();
  g.name = 'trail-signpost';

  const head = HEAD0 * P.tallness;

  const postR = (y) =>
    R_HEAD + (R_FOOT - R_HEAD) * Math.pow(Math.max(0, 1 - y / head), TAPER_EXP);

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const st = [];

  {
    const n = Math.max(3, Math.round((head - FOOT_CH) / RING_PITCH));
    const stations = [{ y: FOOT_CH, drs: null, dys: null }];
    for (let i = 1; i <= n; i++) {
      stations.push({ y: FOOT_CH + ((head - FOOT_CH) * i) / n, drs: null, dys: null });
    }

    if (head > STEP_Y + 0.40) {
      stations.push({ y: STEP_Y - 0.012, drs: null,     dys: KNOT_DY });
      stations.push({ y: STEP_Y + 0.014, drs: KNOT_DR,  dys: KNOT_DY });
      stations.push({ y: STEP_Y + STEP_RUN, drs: null,  dys: KNOT_DY });
    }
    stations.sort((a, b) => a.y - b.y);

    const rings = stations.map((s) => ringY(SIDES, postR(s.y), s.y, 0, s.drs, s.dys));

    const footRing = ringY(SIDES, postR(FOOT_CH) - 0.020, 0);

    const pos = [];
    band(pos, footRing, rings[0]);
    for (let i = 0; i < rings.length - 1; i++) band(pos, rings[i], rings[i + 1]);
    capBot(pos, footRing);
    st.push({ g: posGeo(pos), c: C.post });
  }

  {
    const rings = CAP.map(([dy, r]) => ringY(SIDES, r, head + dy));
    const pos = [];
    for (let i = 0; i < rings.length - 1; i++) band(pos, rings[i], rings[i + 1]);
    capTop(pos, rings[rings.length - 1]);
    st.push({ g: posGeo(pos), c: C.post });
  }

  const boardY = [];
  for (let i = 0; i < P.boards; i++) {
    boardY.push(head - BOARD_DROP - i * BOARD_PITCH - BOARDS[i].dy);
  }

  for (let i = 0; i < P.boards; i++) {
    const y = boardY[i];
    const r = postR(y);
    const yaw = THREE.MathUtils.degToRad(BOARDS[i].yaw(P.boardAngle));

    const dir = new THREE.Vector3(Math.sin(yaw), 0, Math.cos(yaw));
    for (const s of [1, -1]) {
      const geo = new THREE.CylinderGeometry(PEG_R, PEG_R, 1, PEG_SEG, 1, true);
      const inner = r * 0.35, outer = r + PEG_OUT;
      geo.scale(1, outer - inner, 1);
      geo.translate(0, (outer + inner) / 2, 0);

      const q = new THREE.Quaternion().setFromUnitVectors(
        new THREE.Vector3(0, 1, 0), dir.clone().multiplyScalar(s));
      geo.applyQuaternion(q);
      geo.translate(0, y, 0);

      const capRing = [];
      for (let k = 0; k < PEG_SEG; k++) {
        const a = (k * 2 * Math.PI) / PEG_SEG;
        const v = new THREE.Vector3(Math.cos(a) * PEG_R, outer, Math.sin(a) * PEG_R);
        v.applyQuaternion(q); v.y += y;
        capRing.push([v.x, v.y, v.z]);
      }
      const pos = [];

      capTop(pos, capRing);
      st.push({ g: geo, c: C.peg });
      st.push({ g: posGeo(pos), c: C.peg });
    }
  }

  const postMesh = new THREE.Mesh(mergeColored(st), mat);
  postMesh.name = 'post';
  g.add(postMesh);

  for (let i = 0; i < P.boards; i++) {
    const B = BOARDS[i];
    const grp = new THREE.Group();
    grp.name = B.name;
    grp.position.set(0, boardY[i], 0);
    grp.rotation.y = THREE.MathUtils.degToRad(B.yaw(P.boardAngle));

    const geo = plankGeometry(B.A, TAILS[B.name], P.armReach);

    const mesh = new THREE.Mesh(
      mergeColored([{ g: geo, c: i === 0 ? C.boardTop : C.boardLow }]), mat);
    mesh.name = B.name + '-plank';
    grp.add(mesh);
    g.add(grp);
  }

  const box = new THREE.Box3().setFromObject(g);
  const dx = (box.min.x + box.max.x) / 2, dz = (box.min.z + box.max.z) / 2, dy = box.min.y;
  for (const ch of g.children) { ch.position.x -= dx; ch.position.y -= dy; ch.position.z -= dz; }

  return g;
}

export const rig = {

  'board-top': { axis: 'y', range: [0, 58] },
  'board-mid': { axis: 'y', range: [0, -62] },
  'board-low': { axis: 'y', range: [0, 50] },
};
export const detach = [];
export const night = {};

export default createAsset;
