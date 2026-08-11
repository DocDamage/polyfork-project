/*
 * Signpost
 * https://polyfork.dev/asset/signpost-ed3d77
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './signpost-ed3d77.mjs';
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
 *   colorway    choice  'weathered-oak' 'weathered-oak' | 'salt-bleached' | 'tarred-pitch' | 'harbour-oak'
 *   post        color   '#6B4526'      any hex or THREE.Color
 *   finial      color   '#4A2E1B'      any hex or THREE.Color
 *   boardTop    color   '#9C6B3C'      any hex or THREE.Color
 *   boardLow    color   '#C9975C'      any hex or THREE.Color
 *   tallness    range   1              0.72 to 1.1
 *   boards      range   2              1 to 3
 *   armReach    range   1              0.78 to 1.25
 *   boardAngle  range   35             12 to 58
 *
 * Every option is described in full at https://polyfork.dev/cdn/signpost-ed3d77-params.json
 *
 * SPECS  404 triangles, 1 material, 1.17 x 2.2 x 0.85 m (real-world scale).
 * PARTS  animate: board-top, board-mid
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-oak': { post: '#6B4526', finial: '#4A2E1B', boardTop: '#9C6B3C', boardLow: '#C9975C' },
  'salt-bleached': { post: '#A79680', finial: '#8A8071', boardTop: '#B99B68', boardLow: '#DCCBA6' },
  'tarred-pitch':  { post: '#4A2E1B', finial: '#2A2320', boardTop: '#6B4526', boardLow: '#9C6B3C' },
  'harbour-oak':   { post: '#9C6B3C', finial: '#6B4526', boardTop: '#C9975C', boardLow: '#E0A579' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway', affects: 'colors',
    options: ['weathered-oak', 'salt-bleached', 'tarred-pitch', 'harbour-oak'],
    describe: 'Curated Pirate Cove scheme, all four built on brown timber because every part of this prop is wood. weathered-oak is the default dark cocoa post under two warmer tan boards; salt-bleached is a sun-greyed driftwood post with pale sand boards; tarred-pitch is a near-black pitched post with mid-brown boards, the darkest and highest-contrast option; harbour-oak is a warm honey post under peach boards, the lightest overall.',
  },
  post: {
    type: 'color', default: '#6B4526', label: 'Post timber', affects: 'colors',
    describe: 'Albedo of the entire tapered shaft, all eight facets and the flared foot and its underside. This is the dominant mass and it is ONE uniform tone; the facet-to-facet brightness comes from scene lighting, so a second wood tone here would double-shade it. Keep it darker than both boards or the arrows stop separating from the post they cross.',
  },
  finial: {
    type: 'color', default: '#4A2E1B', label: 'Finial knob', affects: 'colors',
    describe: 'Albedo of the carved acorn on the post head, from the pinched neck up to the small sawn top flat. A step DARKER than the shaft so the knob reads as a separately carved piece capping the post; lighter than the shaft and it reads as a lamp or a blob of light instead.',
  },
  boardTop: {
    type: 'color', default: '#9C6B3C', label: 'Upper board', affects: 'colors',
    describe: 'Albedo of the whole upper arrow plank including its chamfers and its chipped ends. One step lighter than the post so the plank reads in front of the timber it crosses; the two boards are deliberately two different plank tones, which is a real material difference, not shading.',
  },
  boardLow: {
    type: 'color', default: '#C9975C', label: 'Lower board', affects: 'colors',
    describe: 'Albedo of the lower arrow plank (and of the third plank when the boards knob is at 3). The lightest zone on the asset, one clear step above the upper board so the two signs never merge into one billboard at thumbnail size.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.72, max: 1.10, affects: 'geometry', label: 'Post height',
    describe: 'Length of the post shaft. At 0.72 the head sits at 1.41 m and the whole sign is 1.65 m — a stumpy beach marker whose boards nearly reach the ground; at 1.0 it is the 2.20 m reference; at 1.10 the head is at 2.16 m and the sign is 2.40 m, a tall crossroads post with a long bare shaft under the arms. This REBUILDS rather than scales: the shaft carries facet rings at a constant 0.32 m pitch, so a taller post gains rings and the triangle count moves with the knob. The foot girth, the head girth, the finial and the boards keep their own size at every value; the boards always hang at fixed offsets below the head.',
  },
  boards: {
    type: 'range', default: 2, min: 1, max: 3, step: 1, affects: 'geometry', label: 'Arrow boards',
    describe: 'How many arrow planks the post carries, hung downward from the head at a constant 0.342 m pitch. At 1 it is a single-direction waymarker; at 2 it is the reference pair pointing opposite ways; at 3 a third plank is added below, turned 40° out of the pair and aimed front-right, so the post reads as a three-way crossroads sign. Each plank is a real added board (about 100 triangles), so the count changes the triangle total.',
  },
  armReach: {
    type: 'range', default: 1.0, min: 0.78, max: 1.25, affects: 'geometry', label: 'Board length',
    describe: 'Length of every plank, measured along its own axis. At 0.78 the upper board is 0.98 m and the sign reads compact and stubby; at 1.0 it is the reference 1.258 m; at 1.25 it is 1.57 m and the arms cantilever a long way out. A plank has nothing repeating along its length, so this cannot gain sections — but it is still a rebuild and not a stretch: the board height, the 0.070 m thickness, the 0.145 m arrow point, the 12 mm chamfer and every chipped notch keep their exact real size, and only the blank middle of the plank grows.',
  },
  boardAngle: {
    type: 'range', default: 35, min: 12, max: 58, affects: 'geometry', label: 'Board angle',
    describe: 'Plan angle of the pair of boards off the X axis, in degrees. The two boards stay exactly antiparallel at every value — this swings the whole signed direction round the post. At 12 they lie almost square across the front, so the sign is nearly its full 1.26 m wide head-on and almost vanishes edge-on from either side; at 35 they are turned into the three-quarter, which is where both arrows read at full length at once; at 58 the front view foreshortens them to about half width and the side views open right up. The boards keep their length, height, thickness and heights above ground.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function ringY(n, r, y, phase = 0) {
  const out = [];
  for (let k = 0; k < n; k++) {
    const a = phase + (k * 2 * Math.PI) / n;
    out.push([Math.cos(a) * r, y, Math.sin(a) * r]);
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
function mergeColored(list) {
  const m = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!m) throw new Error('mergeGeometries returned null (attribute mismatch)');
  m.computeVertexNormals();
  return m;
}

const SIDES     = 8;
const HEAD0     = 1.960;
const R_HEAD    = 0.0500;
const R_FOOT    = 0.1065;
const TAPER_EXP = 1.55;
const FOOT_CH   = 0.022;
const RING_PITCH = 0.32;

const FINIAL = [
  [0.000, 0.0500],
  [0.046, 0.0350],
  [0.102, 0.0760],
  [0.157, 0.0865],
  [0.212, 0.0570],
  [0.240, 0.0310],
];

const BOARD_DROP  = 0.150;
const BOARD_PITCH = 0.342;
const BOARD_TH    = 0.070;
const BEV         = 0.012;
const TIP_LEN     = 0.145;

const BOARDS = [
  { name: 'board-top', A: 0.713, B: 0.545, h: 0.1485, yaw: (a) => 180 + a },
  { name: 'board-mid', A: 0.670, B: 0.529, h: 0.1450, yaw: (a) => a },
  { name: 'board-low', A: 0.691, B: 0.535, h: 0.1470, yaw: (a) => a - 40 },
];

function plankOutline(A, B, h) {
  return [
    [-B,          +h],
    [-B + 0.040,  +0.20 * h],
    [-B + 0.032,  -0.30 * h],
    [-B + 0.004,  -h],
    [-B + 0.155,  -h],
    [-B + 0.225,  -0.84 * h],
    [-B + 0.295,  -h],
    [A - TIP_LEN, -h],
    [A,            0],
    [A - TIP_LEN, +h],
    [-B + 0.480,  +h],
    [-B + 0.400,  +0.86 * h],
    [-B + 0.320,  +h],
  ];
}

function plankGeometry(A, B, h) {

  const pts = plankOutline(A - BEV * Math.SQRT2, B - BEV, h - BEV);
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
  for (const k of ['post', 'finial', 'boardTop', 'boardLow']) {
    C[k] = user[k] !== undefined ? user[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  const num = (k) => {
    const v = user[k] !== undefined ? Number(user[k]) : params[k].default;
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
  g.name = 'signpost';

  const head = HEAD0 * P.tallness;

  const postR = (y) =>
    R_HEAD + (R_FOOT - R_HEAD) * Math.pow(Math.max(0, 1 - y / head), TAPER_EXP);

  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const st = [];

  {
    const n = Math.max(3, Math.round((head - FOOT_CH) / RING_PITCH));
    const ys = [FOOT_CH];
    for (let i = 1; i <= n; i++) ys.push(FOOT_CH + ((head - FOOT_CH) * i) / n);

    const rings = ys.map((y) => ringY(SIDES, postR(y), y));

    const footRing = ringY(SIDES, postR(FOOT_CH) - 0.020, 0);

    const pos = [];
    band(pos, footRing, rings[0]);
    for (let i = 0; i < rings.length - 1; i++) band(pos, rings[i], rings[i + 1]);
    capBot(pos, footRing);
    st.push({ g: posGeo(pos), c: C.post });
  }

  {
    const rings = FINIAL.map(([dy, r]) => ringY(SIDES, r, head + dy));
    const pos = [];
    for (let i = 0; i < rings.length - 1; i++) band(pos, rings[i], rings[i + 1]);
    capTop(pos, rings[rings.length - 1]);
    st.push({ g: posGeo(pos), c: C.finial });
  }

  const postMesh = new THREE.Mesh(mergeColored(st), mat);
  postMesh.name = 'post';
  g.add(postMesh);

  for (let i = 0; i < P.boards; i++) {
    const B = BOARDS[i];
    const grp = new THREE.Group();
    grp.name = B.name;
    grp.position.set(0, head - BOARD_DROP - i * BOARD_PITCH, 0);
    grp.rotation.y = THREE.MathUtils.degToRad(B.yaw(P.boardAngle));

    const geo = plankGeometry(B.A * P.armReach, B.B * P.armReach, B.h);

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

  'board-top': { axis: 'y', range: [0, 42] },
  'board-mid': { axis: 'y', range: [0, -48] },
  'board-low': { axis: 'y', range: [0, 40] },
};
export const detach = [];
export const night = {};

export default createAsset;
