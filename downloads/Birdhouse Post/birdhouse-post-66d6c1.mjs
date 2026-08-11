/*
 * Birdhouse Post
 * https://polyfork.dev/asset/birdhouse-post-66d6c1
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './birdhouse-post-66d6c1.mjs';
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
 *   colorway    choice  'oak-and-moss' 'oak-and-moss' | 'weathered-grey' | 'cedar-and-red' | 'deep-pine'
 *   timber      color   '#a5855e'      any hex or THREE.Color
 *   walls       color   '#75563b'      any hex or THREE.Color
 *   roof        color   '#3d6b34'      any hex or THREE.Color
 *   cavity      color   '#3a2a1e'      any hex or THREE.Color
 *   postHeight  range   1.8            1.15 to 1.92
 *   mount       choice  'top'          'top' | 'side'
 *   battens     range   3              0 to 4
 *
 * Every option is described in full at https://polyfork.dev/cdn/birdhouse-post-66d6c1-params.json
 *
 * SPECS  393 triangles, 1 material, 0.45 x 1.8 x 0.48 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {

  'oak-and-moss':   { timber: '#a5855e', walls: '#75563b', roof: '#3d6b34', cavity: '#3a2a1e' },
  'weathered-grey': { timber: '#a3a099', walls: '#87847c', roof: '#6e6b63', cavity: '#3a2a1e' },
  'cedar-and-red':  { timber: '#c2a479', walls: '#75563b', roof: '#c94f3d', cavity: '#3a2a1e' },
  'deep-pine':      { timber: '#8c6a47', walls: '#5d4430', roof: '#25402c', cavity: '#1c3323' },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'oak-and-moss', label: 'Colorway', affects: 'colors',
    options: ['oak-and-moss', 'weathered-grey', 'cedar-and-red', 'deep-pine'],
    describe: 'Curated Nature & Forest scheme. oak-and-moss is the default: warm oak frame timber, a mid-brown box and a mossy green roof. weathered-grey is a silvered unpainted box with a pewter roof for old fence lines. cedar-and-red is a pale cedar frame under a dark box and a barn-red painted roof, the loudest of the four. deep-pine is a dark creosoted box under a near-black forest-green roof for dense conifer scenes.',
  },
  timber: {
    type: 'color', default: '#a5855e', label: 'Frame timber', affects: 'colors',
    describe: 'Albedo of every piece of sawn frame timber: the foot slab, the post, the floor plank and its bearer, the applied wall battens, the perch peg and its gusset, and the mid-post cleat. Keep it a clear rung LIGHTER than the box walls — the plank ledge and the battens read as proud carpentry only because they are lighter than what they sit on.',
  },
  walls: {
    type: 'color', default: '#75563b', label: 'Box walls', affects: 'colors',
    describe: 'Albedo of the nest box shell: all four walls, the gable and the drilled front plate. This is ONE material, so the face-to-face tone differences in the reference renders come from scene lighting, not from a second wood colour here. Keep it a WIDE step under the frame timber — two rungs of the kit browns, not one: the proud battens and the floor-plank ledge are lit-side carpentry on top of this field, and at thumbnail size a narrow step washes both of them into the box.',
  },
  roof: {
    type: 'color', default: '#3d6b34', label: 'Roof', affects: 'colors',
    describe: 'Albedo of the two mitred roof slabs, their gable-end faces, the soffit under the overhang, the ridge cap board and the two barge boards down the gable rakes. The one non-wood colour on the asset and the darkest large mass, so the wide roof reads as a hard dark cap on a pale stick at thumbnail size. Greens tie it to the kit foliage; a painted red also works (see cedar-and-red).',
  },
  cavity: {
    type: 'color', default: '#3a2a1e', label: 'Nest cavity', affects: 'colors',
    describe: 'Albedo of the inside of the box, seen down the entry tunnel: the tunnel wall and the cavity back face. Its own zone because it is the only near-black on the asset and the whole point of the entry hole is that it reads as a real dark opening rather than a painted dot. Always keep it several rungs darker than the walls.',
  },
  postHeight: {
    type: 'range', default: 1.80, min: 1.15, max: 1.92, affects: 'geometry', label: 'Post height',
    describe: 'Total height of the prop in metres, ground to roof ridge. REBUILT, not scaled: the box, the roof, the plank, the perch and the foot slab keep their exact built size at every value and the post section stays a 0.10 m baulk, so only the post length changes — and with it the number of mid-post cleats, which sit at a constant 0.55 m pitch measured down from the post head. At 1.15 the post is too short to carry a cleat at all and it reads as a low garden nest box you can look into; at 1.80 it is the reference post with one cleat at 0.99 m; at 1.92 a second cleat appears lower down. The range is skewed downward on purpose so the tall end still fits the proof camera.',
  },
  mount: {
    type: 'choice', default: 'top', label: 'Mounting', affects: 'geometry',
    options: ['top', 'side'],
    describe: 'How the box is carried, the two ways this prop is really built. top (the reference) stands the box centred on the post head, on the overhanging plank. side runs the post on up past the box and brackets the box out to one side on a cantilevered plank with a diagonal knee brace under it, with a widened foot slab counterweighting the offset — the same box, plank and roof, rehung. Both values keep the same total height, the same flat foot at y=0 and the same palette.',
  },
  battens: {
    type: 'range', default: 3, min: 0, max: 4, step: 1, affects: 'geometry', label: 'Wall battens',
    describe: 'Number of raised board-and-batten strips per wall, evenly spaced across the side and back walls, with a symmetric pair flanking the entry hole on the front whenever the count is at least 1. Each batten is a real 0.028 m strip standing 0.010 m proud of the wall and bedded 0.020 m into it, so the count genuinely rebuilds the walls and the triangle total moves with it. At 0 the box is smooth flush boarding; at 3 it is the reference four-board wall; at 4 the boarding reads narrow and busy, like a small nest box built from offcuts.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const BASIS = {
  x: [[0, 0, 1], [0, 1, 0]],
  y: [[1, 0, 0], [0, 0, 1]],
  z: [[1, 0, 0], [0, -1, 0]],
};
const AXIS_I = { x: 0, y: 1, z: 2 };
const place = (uv, e1, e2, ctr) => uv.map(([u, v]) => [
  ctr[0] + e1[0] * u + e2[0] * v,
  ctr[1] + e1[1] * u + e2[1] * v,
  ctr[2] + e1[2] * u + e2[2] * v,
]);
function ringAt(axis, uv, a) {
  const ctr = [0, 0, 0]; ctr[AXIS_I[axis]] = a;
  return place(uv, BASIS[axis][0], BASIS[axis][1], ctr);
}
function band(out, lo, hi) {
  const n = lo.length;
  for (let k = 0; k < n; k++) { const j = (k + 1) % n; quad(out, lo[k], hi[k], hi[j], lo[j]); }
}
function capTop(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k + 1], r[k]); }
function capBot(out, r) { for (let k = 1; k < r.length - 1; k++) tri(out, r[0], r[k], r[k + 1]); }

const uvY = (ptsXZ) => ptsXZ;
const uvX = (ptsZY) => ptsZY;
const uvZ = (ptsXY) => ptsXY.map(([x, y]) => [x, -y]).reverse();

const rect = (hu, hv, cu = 0, cv = 0) => [
  [cu - hu, cv - hv], [cu + hu, cv - hv], [cu + hu, cv + hv], [cu - hu, cv + hv],
];
const octPts = (h, c) => [
  [-(h - c), -h], [h - c, -h], [h, -(h - c)], [h, h - c],
  [h - c, h], [-(h - c), h], [-h, h - c], [-h, -(h - c)],
];
const nGon = (r, n, phase = 0) => {
  const p = [];
  for (let i = 0; i < n; i++) {
    const a = phase + (i / n) * Math.PI * 2;
    p.push([Math.cos(a) * r, Math.sin(a) * r]);
  }
  return p;
};

function prism(out, axis, uv, a0, a1, capLo, capHi) {
  const r0 = ringAt(axis, uv, a0), r1 = ringAt(axis, uv, a1);
  band(out, r0, r1);
  if (capLo) capBot(out, r0);
  if (capHi) capTop(out, r1);
}

function chevronPrism(out, pts, z0, z1, capLo, capHi, halves) {
  prism(out, 'z', uvZ(pts), z0, z1, false, false);
  for (const idx of halves) {
    const f = idx.map((i) => [pts[i][0], pts[i][1], z1]);
    const b = idx.map((i) => [pts[i][0], pts[i][1], z0]);
    for (let k = 1; k < idx.length - 1; k++) {
      if (capHi) tri(out, f[0], f[k], f[k + 1]);
      if (capLo) tri(out, b[0], b[k + 1], b[k]);
    }
  }
}

function frameDir(d) {
  const D = new THREE.Vector3(d[0], d[1], d[2]).normalize();
  const tmp = Math.abs(D.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const e1 = new THREE.Vector3().crossVectors(D, tmp).normalize();
  const e2 = new THREE.Vector3().crossVectors(D, e1).negate();
  return [[e1.x, e1.y, e1.z], [e2.x, e2.y, e2.z]];
}

function strut(out, uv, p0, p1, capEnd) {
  const [e1, e2] = frameDir([p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]]);
  const r0 = place(uv, e1, e2, p0), r1 = place(uv, e1, e2, p1);
  band(out, r0, r1);
  if (capEnd) capTop(out, r1);
}

function classify(geo, pick) {
  const p = geo.toNonIndexed().attributes.position.array;
  const out = {};
  const u = new THREE.Vector3(), v = new THREE.Vector3(), n = new THREE.Vector3();
  for (let i = 0; i < p.length; i += 9) {
    u.set(p[i + 3] - p[i], p[i + 4] - p[i + 1], p[i + 5] - p[i + 2]);
    v.set(p[i + 6] - p[i], p[i + 7] - p[i + 1], p[i + 8] - p[i + 2]);
    n.crossVectors(u, v).normalize();
    const c = [(p[i] + p[i + 3] + p[i + 6]) / 3, (p[i + 1] + p[i + 4] + p[i + 7]) / 3,
      (p[i + 2] + p[i + 5] + p[i + 8]) / 3];
    const key = pick(c, n);
    if (!key) continue;
    (out[key] = out[key] || []).push(...p.slice(i, i + 9));
  }
  return out;
}

function cullHidden(pos, plankY, underY, ridgeX) {
  const out = [];
  for (let i = 0; i < pos.length; i += 9) {
    let inPlank = true, loY = Infinity, xLo = Infinity, xHi = -Infinity;
    for (let k = 0; k < 9; k += 3) {
      if (pos[i + k + 1] > plankY + 1e-6) inPlank = false;
      loY = Math.min(loY, pos[i + k + 1]);
      xLo = Math.min(xLo, pos[i + k]); xHi = Math.max(xHi, pos[i + k]);
    }
    const peak = underY(Math.min(Math.max(ridgeX, xLo), xHi));
    if (inPlank || loY >= peak - 1e-6) continue;
    for (let k = 0; k < 9; k++) out.push(pos[i + k]);
  }
  return out;
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
function mergeColored(list) {
  const m = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!m) throw new Error('mergeGeometries returned null (attribute mismatch)');
  m.computeVertexNormals();
  return m;
}

const BASE_HW   = 0.200;
const BASE_H    = 0.050;
const BASE_CHAM = 0.014;

const POST_HW   = 0.050;
const POST_CHAM = 0.010;
const POST_BED  = 0.020;

const PLK_HW    = 0.200;
const PLK_HD    = 0.190;
const PLK_H     = 0.045;
const BEAR_HW   = 0.065;
const BEAR_HD   = 0.170;
const BEAR_H    = 0.035;

const BOX_HW    = 0.150;
const BOX_HD    = 0.135;
const WALL_H    = 0.260;
const GABLE     = 0.190;
const PLATE_T   = 0.045;
const BOX_BED   = 0.020;

const HOLE_R    = 0.058;
const HOLE_Y    = 0.205;
const HOLE_SEG  = 12;

const ROOF_HW   = 0.225;
const ROOF_HD   = 0.205;
const ROOF_BED  = 0.022;
const ROOF_TV   = 0.055;
const ROOF_CHAM = 0.013;
const RIDGE_HW  = 0.055;
const RIDGE_UP  = 0.014;
const RIDGE_BED = 0.010;
const RIDGE_END = 0.020;
const BARGE_IN  = 0.008;
const BARGE_OUT = 0.012;
const BARGE_BED = 0.015;
const BARGE_DROP = 0.026;
const BARGE_TOP = 0.004;

const BAT_HW    = 0.014;
const BAT_OUT   = 0.010;
const BAT_IN    = 0.020;
const BAT_FRONT = 0.099;
const BAT_FOOT  = 0.010;

const PERCH_Y   = 0.095;
const PERCH_R   = 0.019;
const PERCH_LEN = 0.145;
const PERCH_DIP = 0.22;

const CLEAT_PITCH = 0.550;
const CLEAT_TOP   = 0.330;
const CLEAT_HW    = 0.062;

const CLEAT_T     = 0.022;
const BOSS_R      = 0.026;
const BOSS_LEN    = 0.035;

const APEX = WALL_H + GABLE - ROOF_BED + ROOF_TV + RIDGE_UP;

const ZONES = ['timber', 'walls', 'roof', 'cavity'];

function resolve(user) {
  const cw = COLORWAYS[user.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ZONES) {
    C[k] = user[k] !== undefined ? user[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  const num = (k) => {
    const v = user[k] !== undefined ? Number(user[k]) : params[k].default;
    if (!Number.isFinite(v)) return params[k].default;
    return Math.min(params[k].max, Math.max(params[k].min, v));
  };
  return {
    C,
    postHeight: num('postHeight'),
    battens: Math.round(num('battens')),
    mount: user.mount === 'side' ? 'side' : 'top',
  };
}

function battenAt(n, span) {
  const out = [];
  for (let i = 0; i < n; i++) out.push(span * ((i + 1) / (n + 1) - 0.5));
  return out;
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.C;
  const side = P.mount === 'side';

  const H = P.postHeight;
  const Yf = H - APEX;
  const bx = side ? 0.160 : 0;
  const plkTop = Yf + BOX_BED;
  const plkBot = plkTop - PLK_H;
  const plkCx = side ? (bx + 0.20 - 0.060) / 2 : 0;
  const plkHW = side ? (bx + 0.20 + 0.060) / 2 : PLK_HW;
  const postTop = side ? Yf + 0.120 : plkBot + 0.028;
  const postBot = BASE_H - POST_BED;
  const postLen = postTop - postBot;
  const baseHW = side ? 0.260 : BASE_HW;
  const baseCx = side ? 0.060 : 0;

  const slope = GABLE / BOX_HW;
  const gy = (x) => WALL_H + GABLE * (1 - Math.abs(x) / BOX_HW);

  const underY = (x) => Yf + WALL_H + GABLE - ROOF_BED - slope * Math.abs(x - bx);

  const st = [];
  const add = (pos, c) => { if (pos.length) st.push({ g: posGeo(pos), c }); };

  const addBox = (pos, c) => add(cullHidden(pos, plkTop, underY, bx), c);

  {
    const pos = [];
    const r0 = ringAt('y', uvY(rect(baseHW, BASE_HW, baseCx, 0)), 0);
    const r1 = ringAt('y', uvY(rect(baseHW, BASE_HW, baseCx, 0)), BASE_H - BASE_CHAM);
    const r2 = ringAt('y', uvY(rect(baseHW - BASE_CHAM, BASE_HW - BASE_CHAM, baseCx, 0)), BASE_H);
    band(pos, r0, r1); band(pos, r1, r2);
    capTop(pos, r2); capBot(pos, r0);
    add(pos, C.timber);
  }

  {
    const sec = uvY(octPts(POST_HW, POST_CHAM));
    const pos = [];

    prism(pos, 'y', sec, postBot, postTop, false, side);
    add(pos, C.timber);
  }

  {
    const n = postLen < 0.80 ? 0 : (postLen < 1.36 ? 1 : 2);
    for (let i = 0; i < n; i++) {
      const cy = postTop - CLEAT_TOP - i * CLEAT_PITCH;
      const pos = [];

      prism(pos, 'z', uvZ(rect(CLEAT_HW, CLEAT_HW, 0, cy)),
        -POST_HW - CLEAT_T, -POST_HW + BAT_IN, true, true);
      strut(pos, nGon(BOSS_R, 6), [0, cy, -POST_HW - CLEAT_T + 0.004],
        [0, cy, -POST_HW - CLEAT_T - BOSS_LEN], true);
      add(pos, C.timber);
    }
  }

  {
    const pos = [];
    prism(pos, 'y', uvY(rect(BEAR_HW, BEAR_HD, side ? bx * 0.35 : 0, 0)),
      plkBot - BEAR_H, plkBot + 0.006, true, false);

    const outer = uvY(rect(plkHW, PLK_HD, plkCx, 0));
    const inner = uvY(rect(plkHW - 0.012, PLK_HD - 0.012, plkCx, 0));
    const r0 = ringAt('y', inner, plkBot);
    const r1 = ringAt('y', outer, plkBot + 0.012);
    const r2 = ringAt('y', outer, plkTop);
    band(pos, r0, r1); band(pos, r1, r2);
    capTop(pos, r2); capBot(pos, r0);
    add(pos, C.timber);
  }

  if (side) {
    const pos = [];
    strut(pos, uvY(octPts(0.026, 0.006)),
      [POST_HW - 0.020, plkBot - 0.300, 0], [bx + 0.020, plkBot + 0.012, 0], false);
    add(pos, C.timber);
  }

  const pent = [
    [bx - BOX_HW, Yf], [bx + BOX_HW, Yf], [bx + BOX_HW, Yf + WALL_H],
    [bx, Yf + WALL_H + GABLE], [bx - BOX_HW, Yf + WALL_H],
  ];
  {
    const uv = uvZ(pent);
    const wall = [], cav = [];
    prism(wall, 'z', uv, -BOX_HD, BOX_HD - PLATE_T, true, false);
    capTop(cav, ringAt('z', uv, BOX_HD - PLATE_T));
    addBox(wall, C.walls);
    addBox(cav, C.cavity);
  }

  {
    const sh = new THREE.Shape(pent.map(([x, y]) => new THREE.Vector2(x, y)));
    const hole = new THREE.Path();
    hole.absarc(bx, Yf + HOLE_Y, HOLE_R, 0, Math.PI * 2, true);
    sh.holes.push(hole);
    const geo = new THREE.ExtrudeGeometry(sh, {
      depth: PLATE_T, bevelEnabled: false, steps: 1, curveSegments: HOLE_SEG,
    });
    geo.translate(0, 0, BOX_HD - PLATE_T);
    const hy = Yf + HOLE_Y;
    const parts = classify(geo, (c, n) => {
      if (n.z < -0.5) return null;
      const d = Math.hypot(c[0] - bx, c[1] - hy);
      return (Math.abs(n.z) < 0.5 && d < HOLE_R * 1.4) ? 'cav' : 'wall';
    });
    addBox(parts.wall || [], C.walls);
    addBox(parts.cav || [], C.cavity);
  }

  {
    const n = P.battens;
    const pos = [];

    for (const z of battenAt(n, BOX_HD * 2)) {
      const sec = uvX(rect(BAT_HW, (WALL_H - BAT_FOOT) / 2, z, Yf + (WALL_H + BAT_FOOT) / 2));
      prism(pos, 'x', sec, bx + BOX_HW - BAT_IN, bx + BOX_HW + BAT_OUT, false, true);
      prism(pos, 'x', sec, bx - BOX_HW - BAT_OUT, bx - BOX_HW + BAT_IN, true, false);
    }

    for (const x of battenAt(n, BOX_HW * 2)) {
      const sec = uvZ([
        [bx + x - BAT_HW, Yf + BAT_FOOT], [bx + x + BAT_HW, Yf + BAT_FOOT],
        [bx + x + BAT_HW, Yf + WALL_H], [bx + x - BAT_HW, Yf + WALL_H],
      ]);
      prism(pos, 'z', sec, -BOX_HD - BAT_OUT, -BOX_HD + BAT_IN, true, false);
    }

    if (n >= 1) for (const s of [1, -1]) {
      const x0 = s * BAT_FRONT - BAT_HW, x1 = s * BAT_FRONT + BAT_HW;
      const sec = uvZ([
        [bx + x0, Yf + BAT_FOOT], [bx + x1, Yf + BAT_FOOT],
        [bx + x1, Yf + gy(x1)], [bx + x0, Yf + gy(x0)],
      ]);
      prism(pos, 'z', sec, BOX_HD - BAT_IN, BOX_HD + BAT_OUT, false, true);
    }
    addBox(pos, C.timber);
  }

  {
    const pos = [];
    const py = Yf + PERCH_Y;
    const dir = new THREE.Vector3(0, -PERCH_DIP, 1).normalize();
    const p0 = [bx, py + 0.012, BOX_HD - 0.030];
    const p1 = [p0[0], p0[1] + dir.y * PERCH_LEN, p0[2] + dir.z * PERCH_LEN];
    strut(pos, nGon(PERCH_R, 6, Math.PI / 6), p0, p1, true);

    const gus = uvX([
      [BOX_HD - 0.015, py - 0.078], [BOX_HD + 0.055, py - 0.008], [BOX_HD - 0.015, py - 0.008],
    ]);
    prism(pos, 'x', gus, bx - 0.013, bx + 0.013, true, true);
    add(pos, C.timber);
  }

  {
    const ya = Yf + WALL_H + GABLE - ROOF_BED;
    const ye = ya - slope * ROOF_HW;
    const c = ROOF_CHAM;
    const pos = [];
    chevronPrism(pos, [
      [bx - ROOF_HW + c, ye], [bx, ya], [bx + ROOF_HW - c, ye],
      [bx + ROOF_HW, ye + c], [bx + ROOF_HW, ye + ROOF_TV],
      [bx, ya + ROOF_TV], [bx - ROOF_HW, ye + ROOF_TV], [bx - ROOF_HW, ye + c],
    ], -ROOF_HD, ROOF_HD, true, true, [[0, 1, 5, 6, 7], [1, 2, 3, 4, 5]]);

    const bw = ROOF_HW - BARGE_IN;
    const yb = ya - slope * bw;
    const bargePts = [
      [bx - bw, yb - BARGE_DROP], [bx, ya - BARGE_DROP], [bx + bw, yb - BARGE_DROP],
      [bx + bw, yb + ROOF_TV - BARGE_TOP], [bx, ya + ROOF_TV - BARGE_TOP],
      [bx - bw, yb + ROOF_TV - BARGE_TOP],
    ];
    const bargeHalves = [[0, 1, 4, 5], [1, 2, 3, 4]];
    chevronPrism(pos, bargePts, ROOF_HD - BARGE_BED, ROOF_HD + BARGE_OUT,
      true, true, bargeHalves);
    chevronPrism(pos, bargePts, -ROOF_HD - BARGE_OUT, -ROOF_HD + BARGE_BED,
      true, true, bargeHalves);

    const yr = ya + ROOF_TV - slope * RIDGE_HW;
    chevronPrism(pos, [
      [bx - RIDGE_HW, yr - RIDGE_BED], [bx, ya + ROOF_TV - RIDGE_BED],
      [bx + RIDGE_HW, yr - RIDGE_BED],
      [bx + RIDGE_HW, yr + RIDGE_UP], [bx, ya + ROOF_TV + RIDGE_UP],
      [bx - RIDGE_HW, yr + RIDGE_UP],
    ], -ROOF_HD - RIDGE_END, ROOF_HD + RIDGE_END, true, true, bargeHalves);

    add(pos, C.roof);
  }

  const mesh = new THREE.Mesh(mergeColored(st), new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'nest-box-post';
  const g = new THREE.Group();
  g.name = 'birdhouse-post';
  g.add(mesh);

  const box = new THREE.Box3().setFromObject(g);
  const dx = (box.min.x + box.max.x) / 2, dz = (box.min.z + box.max.z) / 2, dy = box.min.y;
  for (const ch of g.children) { ch.position.x -= dx; ch.position.y -= dy; ch.position.z -= dz; }

  return g;
}

export const rig = {};
export const detach = [];
export const night = {};

export default createAsset;
