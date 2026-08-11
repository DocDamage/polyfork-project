/*
 * Wooden Bench
 * https://polyfork.dev/asset/wooden-bench-661da4
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wooden-bench-661da4.mjs';
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
 *   colorway    choice  'teak-charcoal' 'teak-charcoal' | 'ash-slate' | 'walnut-ink' | 'park-green'
 *   wood        color   '#8C7355'      any hex or THREE.Color
 *   frame       color   '#2E3134'      any hex or THREE.Color
 *   bolt        color   '#6B7278'      any hex or THREE.Color
 *   length      range   1.6            1.1 to 2.6
 *   backrest    choice  'full'         'full' | 'low' | 'none'
 *   seatBoards  range   3              2 to 4
 *
 * Every option is described in full at https://polyfork.dev/cdn/wooden-bench-661da4-params.json
 *
 * SPECS  374 triangles, 1 material, 1.6 x 0.86 x 0.5 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLOR_KEYS = ['wood', 'frame', 'bolt'];

const COLORWAYS = {

  'teak-charcoal': { wood: '#8C7355', frame: '#2E3134', bolt: '#6B7278' },
  'ash-slate':     { wood: '#B9A88C', frame: '#4E5459', bolt: '#8A9197' },
  'walnut-ink':    { wood: '#63503C', frame: '#1B1D20', bolt: '#4E5459' },
  'park-green':    { wood: '#B9A88C', frame: '#2F6B4F', bolt: '#6B7278' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'teak-charcoal', label: 'Colorway',
    options: ['teak-charcoal', 'ash-slate', 'walnut-ink', 'park-green'],
    describe: 'Curated kit-coherent scheme. teak-charcoal is warm mid-brown timber on ' +
      'near-black steel (the reference bench); ash-slate is pale weathered timber on mid ' +
      'grey steel; walnut-ink is dark timber on almost-black steel; park-green puts pale ' +
      'timber on a municipal green frame.',
  },
  wood: {
    type: 'color', default: '#8C7355', label: 'Timber',
    describe: 'Albedo of all six boards, seat and backrest alike — they are one material ' +
      'and always share one colour.',
  },
  frame: {
    type: 'color', default: '#2E3134', label: 'Steel frame',
    describe: 'Albedo of the painted steel: both tube end frames and the slim flat-bar ' +
      'backrest U. Keep it well below the timber in value or the bench loses its two-mass read.',
  },
  bolt: {
    type: 'color', default: '#6B7278', label: 'Bolt heads',
    describe: 'Albedo of the six bolt heads fixing the backrest boards to the posts. One ' +
      'value step lighter than the frame so they read as hardware, not as dents.',
  },
  length: {
    type: 'range', default: 1.6, min: 1.1, max: 2.6, affects: 'geometry', label: 'Length',
    describe: 'Bench length in metres, end of board to end of board. REBUILT, not scaled: ' +
      'board and tube SECTIONS never change, only the boards get longer, and at 2.0 m and ' +
      'above a third identical end frame is added at mid-span (the step where the triangle ' +
      'count jumps). 1.1 m is a two-seater stub, 2.6 m a long platform bench.',
  },
  backrest: {
    type: 'choice', default: 'full', options: ['full', 'low', 'none'], affects: 'geometry',
    label: 'Backrest',
    describe: 'Which bench this is. full = three backrest boards on a full-height flat-bar U ' +
      '(the reference, 0.859 m tall). low = two boards on a shorter U, 0.732 m, a waist-high ' +
      'perch. none = the backless bench of the title: U frame and boards gone, the end ' +
      'frames shorten to the seat depth and the silhouette drops to the 0.45 m seat line. ' +
      'Same origin, same length, same board sections and same palette in every value.',
  },
  seatBoards: {
    type: 'range', default: 3, min: 2, max: 4, step: 1, affects: 'geometry', label: 'Seat boards',
    describe: 'How many boards make the seat. The board WIDTH and the gap are fixed, so the ' +
      'seat and the end frames get deeper with every board: 2 boards = 0.361 m deep (a narrow ' +
      'perch), 3 = 0.503 m (the reference), 4 = 0.646 m (a deep lounging bench). Each step ' +
      'adds exactly 0.1425 m of depth.',
  },
};

const CH        = 0.009;

const TUBE_X    = 0.080;
const TUBE_P    = 0.070;

const SEAT_Y    = 0.450;
const SB_T      = 0.060;
const SB_W      = 0.120;
const SB_GAP    = 0.0225;
const SEAT_BED  = 0.020;

const BB_H      = 0.115;
const BB_T      = 0.050;
const BB_GAP    = 0.012;
const BACK_RISE = 0.040;

const BAR_X     = 0.064;
const BAR_Z     = 0.042;
const BAR_OL    = 0.014;
const BAR_SET   = 0.014;
const BAR_HEAD  = 0.032;
const BAR_FOOT  = 0.020;

const OVH_X     = 0.020;
const OVH_Z     = 0.008;
const SEAT_BACK_GAP = 0.006;

const MID_FRAME_AT = 2.0;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
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
function finish(list) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function rivet(cx, cy, cz, nx, ny, nz, r = 0.018, h = 0.007) {
  const n = new THREE.Vector3(nx, ny, nz).normalize();
  const up = Math.abs(n.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const t = new THREE.Vector3().crossVectors(up, n).normalize();
  const b = new THREE.Vector3().crossVectors(n, t).normalize();
  const apex = [cx + n.x * h, cy + n.y * h, cz + n.z * h];
  const ring = [];
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2, cs = Math.cos(a) * r, sn = Math.sin(a) * r;
    ring.push([cx + t.x * cs + b.x * sn, cy + t.y * cs + b.y * sn, cz + t.z * cs + b.z * sn]);
  }
  const pos = [];
  for (let i = 0; i < 6; i++) tri(pos, apex, ring[i], ring[(i + 1) % 6]);
  return posGeo(pos);
}

function cullBuried(geo, boxes) {
  const p = geo.attributes.position;
  const kept = [];
  for (let t = 0; t < p.count / 3; t++) {
    let dead = false;
    for (const b of boxes) {
      let all = true;
      for (let k = 0; k < 3 && all; k++) {
        const i = t * 3 + k, x = p.getX(i), y = p.getY(i), z = p.getZ(i);
        all = x >= b[0] && x <= b[1] && y >= b[2] && y <= b[3] && z >= b[4] && z <= b[5];
      }
      if (all) { dead = true; break; }
    }
    if (dead) continue;
    for (let k = 0; k < 3; k++) {
      const i = t * 3 + k;
      kept.push(p.getX(i), p.getY(i), p.getZ(i));
    }
  }
  return posGeo(kept);
}

function shapeFrom(pts) {
  const s = new THREE.Shape();
  s.moveTo(pts[0][0], pts[0][1]);
  for (let i = 1; i < pts.length; i++) s.lineTo(pts[i][0], pts[i][1]);
  s.closePath();
  return s;
}
function pathFrom(pts) {
  const p = new THREE.Path();
  p.moveTo(pts[0][0], pts[0][1]);
  for (let i = 1; i < pts.length; i++) p.lineTo(pts[i][0], pts[i][1]);
  p.closePath();
  return p;
}

function extrude(shape, thickness) {
  return new THREE.ExtrudeGeometry(shape, {
    depth: thickness - 2 * CH, bevelEnabled: true, bevelSegments: 1,
    bevelThickness: CH, bevelSize: CH, bevelOffset: -CH, curveSegments: 1,
  });
}

function endFrame(cx, zBack, zFront, yTop) {
  const shape = shapeFrom([
    [zBack, 0], [zFront, 0], [zFront, yTop], [zBack, yTop],
  ]);
  shape.holes = [pathFrom([
    [zBack + TUBE_P, TUBE_P], [zBack + TUBE_P, yTop - TUBE_P],
    [zFront - TUBE_P, yTop - TUBE_P], [zFront - TUBE_P, TUBE_P],
  ])];
  const geo = extrude(shape, TUBE_X);
  geo.rotateY(-Math.PI / 2);
  geo.translate(cx + (TUBE_X - 2 * CH) / 2, 0, 0);
  return geo;
}

function backFrame(postXs, yBot, yRailBot, yTop, zBack) {
  const hp = BAR_X / 2;
  const pts = [];
  for (let i = 0; i < postXs.length; i++) {
    const c = postXs[i];
    if (i > 0) { pts.push([c - hp, yRailBot]); pts.push([c - hp, yBot]); }
    else pts.push([c - hp, yBot]);
    pts.push([c + hp, yBot]);
    pts.push([c + hp, i === postXs.length - 1 ? yTop : yRailBot]);
  }
  pts.push([postXs[0] - hp, yTop]);
  const geo = extrude(shapeFrom(pts), BAR_Z);
  geo.translate(0, 0, zBack + CH);
  return geo;
}

function board(len, w, t, cz, cy) {
  const W = w / 2, T = t / 2;
  const prof = [
    [cz - W + CH, cy - T], [cz + W - CH, cy - T], [cz + W, cy - T + CH], [cz + W, cy + T - CH],
    [cz + W - CH, cy + T], [cz - W + CH, cy + T], [cz - W, cy + T - CH], [cz - W, cy - T + CH],
  ];
  const geo = new THREE.ExtrudeGeometry(shapeFrom(prof), {
    depth: len, bevelEnabled: false, curveSegments: 1,
  });
  geo.rotateY(-Math.PI / 2);
  geo.translate(len / 2, 0, 0);
  return geo;
}

function resolveColors(opts) {
  const cw = COLORWAYS[opts.colorway] || COLORWAYS[params.colorway.default];
  const c = {};
  for (const k of COLOR_KEYS) c[k] = params[k].default;
  Object.assign(c, cw);
  for (const k of COLOR_KEYS) if (opts[k] != null) c[k] = opts[k];
  return c;
}

export function createAsset(opts = {}) {
  const C = resolveColors(opts);
  const L = Math.min(2.6, Math.max(1.1, opts.length != null ? +opts.length : params.length.default));
  const mode = params.backrest.options.includes(opts.backrest) ? opts.backrest : params.backrest.default;
  const nSeat = Math.round(Math.min(4, Math.max(2,
    opts.seatBoards != null ? +opts.seatBoards : params.seatBoards.default)));
  const nBack = mode === 'full' ? 3 : mode === 'low' ? 2 : 0;

  const g = new THREE.Group();
  g.name = 'wooden-bench';
  const parts = [];
  const add = (geo, c) => parts.push({ g: geo, c });

  const frameCx = L / 2 - OVH_X - TUBE_X / 2;
  const frameXs = [-frameCx, frameCx];
  if (L >= MID_FRAME_AT) frameXs.splice(1, 0, 0);

  const seatDepth = nSeat * SB_W + (nSeat - 1) * SB_GAP;
  const zSeatFront = 0;
  const zSeatBack = zSeatFront - seatDepth;

  let zFrameFront = zSeatFront - OVH_Z;
  let zFrameBack, zBoardFront, zBarBack;
  if (nBack > 0) {
    zBoardFront = zSeatBack - SEAT_BACK_GAP;
    zBarBack = zBoardFront - BB_T - BAR_Z + BAR_OL;

    zFrameBack = zBarBack - BAR_SET;
  } else {
    zFrameBack = zSeatBack + OVH_Z;
  }

  const yFrameTop = SEAT_Y - SB_T + SEAT_BED;
  for (const cx of frameXs) add(endFrame(cx, zFrameBack, zFrameFront, yFrameTop), C.frame);

  const cySeat = SEAT_Y - SB_T / 2;
  for (let i = 0; i < nSeat; i++) {
    const cz = zSeatFront - SB_W / 2 - i * (SB_W + SB_GAP);
    add(board(L, SB_W, SB_T, cz, cySeat), C.wood);
  }

  if (nBack > 0) {
    const yBoard0 = SEAT_Y + BACK_RISE;
    const yBackTop = yBoard0 + nBack * BB_H + (nBack - 1) * BB_GAP;
    const yBarTop = yBackTop - BAR_HEAD;
    const cyBoards = [];
    const buried = frameXs.map((cx) => [
      cx - TUBE_X / 2, cx + TUBE_X / 2,
      yFrameTop - TUBE_P + CH, yFrameTop - CH,
      zFrameBack + CH, zFrameFront - CH,
    ]);
    for (let i = 0; i < nBack; i++) {
      const cy = yBoard0 + i * (BB_H + BB_GAP) + BB_H / 2;
      cyBoards.push(cy);
      add(board(L, BB_T, BB_H, zBoardFront - BB_T / 2, cy), C.wood);

      buried.push([-L / 2, L / 2, cy - BB_H / 2 + CH, cy + BB_H / 2 - CH,
        zBoardFront - BB_T + 1e-4, zBoardFront - 1e-4]);
    }
    add(cullBuried(backFrame(frameXs, yFrameTop - BAR_FOOT, yBarTop - BAR_X, yBarTop, zBarBack),
      buried), C.frame);

    for (const cx of frameXs) {
      for (const cy of cyBoards) add(rivet(cx, cy, zBarBack, 0, 0, -1), C.bolt);
    }
  }

  const mesh = finish(parts);
  mesh.name = 'bench';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, 0, -(bb.min.z + bb.max.z) / 2);

  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};

export default createAsset;
