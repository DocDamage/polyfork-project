/*
 * Two-Lane Street Tile
 * https://polyfork.dev/asset/two-lane-street-tile-fe56b6
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './two-lane-street-tile-fe56b6.mjs';
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
 *   piece        choice  'straight'     'straight' | 'corner' | 't-junction' | 'crossroads' | 'end'
 *   lines        choice  'none'         'none' | 'centre' | 'centre-dashed' | 'edges' | 'both' | 'both-dashed'
 *   crossing     toggle  false          true | false
 *   vergeCourse  toggle  true           true | false
 *   colorway     choice  'fresh-asphalt' 'fresh-asphalt' | 'sun-bleached' | 'oiled-tarmac' | 'desert-highway'
 *   asphalt      color   '#3d3f46'      any hex or THREE.Color
 *   course       color   '#4c4f57'      any hex or THREE.Color
 *   shoulder     color   '#999ca3'      any hex or THREE.Color
 *   paint        color   '#f1f2ef'      any hex or THREE.Color
 *   substrate    color   '#1a1f26'      any hex or THREE.Color
 *
 * Every option is described in full at https://polyfork.dev/cdn/two-lane-street-tile-fe56b6-params.json
 *
 * SPECS  138 triangles, 1 material, 8 x 0.05 x 8 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 8.0;
const HALF = SIZE / 2;
const THICK = 0.05;
const TOP_Y = 0.0;
const BOT_Y = TOP_Y - THICK;

const SHOULDER = 0.5;
const CARR = HALF - SHOULDER;

const VERGE = 0.75;

const FIELD = [-1.375, 0, 1.375];

const PAINT_UP = 0.002;
const LW = 0.15;
const E1 = CARR, E0 = CARR - LW;
const C_IN = LW / 2, C_OUT = LW * 1.5;

const DASH_N = 5, DASH_PITCH = 1.6, DASH_ON = 0.8;

const BAR_W = 0.5, BAR_GAP = 0.38;
const BAR_SPAN = E0 - 0.02;

const BAND_IN = 2.4, BAND_OUT = 3.4;
const BAND_STRAIGHT = 0.6;

const STOP_DEEP = 0.25, STOP_CLEAR = 0.25;

const COLORWAYS = {
  'fresh-asphalt':  { asphalt: '#3d3f46', course: '#4c4f57', shoulder: '#999ca3', paint: '#f1f2ef', substrate: '#1a1f26' },
  'sun-bleached':   { asphalt: '#676b72', course: '#898c95', shoulder: '#c2c7cd', paint: '#f1f2ef', substrate: '#3d3f46' },
  'oiled-tarmac':   { asphalt: '#2a2d35', course: '#3d3f46', shoulder: '#747c8a', paint: '#ecf1cb', substrate: '#0c0e14' },
  'desert-highway': { asphalt: '#4c4f57', course: '#676b72', shoulder: '#c7baa6', paint: '#ecf1cb', substrate: '#4e3c30' },
};
const COLOR_KEYS = ['asphalt', 'course', 'shoulder', 'paint', 'substrate'];

const LINE_MODES = ['none', 'centre', 'centre-dashed', 'edges', 'both', 'both-dashed'];
const DEF = { colorway: 'fresh-asphalt', piece: 'straight', lines: 'none', crossing: false, vergeCourse: true };

const PIECE_ARMS = {
  straight:     ['S', 'N'],
  corner:       ['S', 'E'],
  't-junction': ['S', 'N', 'E'],
  crossroads:   ['S', 'N', 'E', 'W'],
  end:          ['S'],
};
const PIECE_KEYS = Object.keys(PIECE_ARMS);

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const crs = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

function quadN(out, a, b, c, d, want) {
  if (dot(crs(sub(b, a), sub(c, a)), want) < 0) quad(out, d, c, b, a); else quad(out, a, b, c, d);
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
  const merged = mergeGeometries(list.filter(p => p.g.attributes.position.count > 0)
    .map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const rect = (a, b, c, d) => [Math.min(a, b), Math.max(a, b), Math.min(c, d), Math.max(c, d)];
const areal = (r) => r[1] - r[0] > 1e-6 && r[3] - r[2] > 1e-6;

function rectDiff(r, b) {
  const [x0, x1, z0, z1] = r, [bx0, bx1, bz0, bz1] = b;
  if (bx1 <= x0 || bx0 >= x1 || bz1 <= z0 || bz0 >= z1) return [r];
  const out = [];
  if (bz0 > z0) out.push([x0, x1, z0, bz0]);
  if (bz1 < z1) out.push([x0, x1, bz1, z1]);
  const mz0 = Math.max(z0, bz0), mz1 = Math.min(z1, bz1);
  if (bx0 > x0) out.push([x0, bx0, mz0, mz1]);
  if (bx1 < x1) out.push([bx1, x1, mz0, mz1]);
  return out.filter(areal);
}
const cutAll = (rects, bands) =>
  bands.reduce((acc, b) => acc.flatMap(r => rectDiff(r, b)), rects).filter(areal);

const GX = [-HALF, -CARR, CARR, HALF];

function surfaceLines(verge) {
  const L = [-HALF, -CARR];
  if (verge) L.push(-(CARR - VERGE));
  L.push(...FIELD);
  if (verge) L.push(CARR - VERGE);
  L.push(CARR, HALF);
  return L;
}

function plan(arms) {
  const a = [[false, false, false], [false, false, false], [false, false, false]];
  a[1][1] = true;
  if (arms.includes('S')) a[1][0] = true;
  if (arms.includes('N')) a[1][2] = true;
  if (arms.includes('E')) a[2][1] = true;
  if (arms.includes('W')) a[0][1] = true;
  return a;
}

function edgeRects(road) {
  const R = [];
  const on = (i, j) => i >= 0 && i < 3 && j >= 0 && j < 3 && road[i][j];
  const shoulder = (i, j) => i >= 0 && i < 3 && j >= 0 && j < 3 && !road[i][j];
  for (let i = 0; i < 3; i++) {
    for (let j = 0; j < 3; j++) {
      if (!road[i][j]) continue;
      const x0 = GX[i], x1 = GX[i + 1], z0 = GX[j], z1 = GX[j + 1];
      const left = shoulder(i - 1, j), right = shoulder(i + 1, j);

      for (const [side, hug] of [[-1, left], [1, right]]) {
        if (!hug) continue;
        const ni = i + side;
        const a0 = (on(i, j - 1) && !shoulder(ni, j - 1)) ? z0 - LW : z0;
        const a1 = (on(i, j + 1) && !shoulder(ni, j + 1)) ? z1 + LW : z1;
        R.push(side < 0 ? rect(x0, x0 + LW, a0, a1) : rect(x1 - LW, x1, a0, a1));
      }

      for (const [side, hug] of [[-1, shoulder(i, j - 1)], [1, shoulder(i, j + 1)]]) {
        if (!hug) continue;
        const b0 = x0 + (left ? LW : 0), b1 = x1 - (right ? LW : 0);
        R.push(side < 0 ? rect(b0, b1, z0, z0 + LW) : rect(b0, b1, z1 - LW, z1));
      }
    }
  }
  return R.filter(areal);
}

function centreBands(dashed) {
  return dashed ? [[-C_IN, C_IN]] : [[C_IN, C_OUT], [-C_OUT, -C_IN]];
}

function centreElbow(R, a, b) {
  const la = -b, lb = -a;
  R.push(rect(a, b, -HALF, lb));
  R.push(rect(b, HALF, la, lb));
}

function centreRects(piece, dashed) {
  const R = [];
  const bands = centreBands(dashed);
  if (piece === 'straight') {
    for (const [a, b] of bands) {
      if (dashed) {
        for (let k = 0; k < DASH_N; k++) {
          const c = (k - (DASH_N - 1) / 2) * DASH_PITCH;
          R.push(rect(a, b, c - DASH_ON / 2, c + DASH_ON / 2));
        }
      } else R.push(rect(a, b, -HALF, HALF));
    }
  } else if (piece === 'corner') {

    for (const [a, b] of bands) centreElbow(R, a, b);
  } else if (piece === 't-junction') {

    for (const [a, b] of bands) {
      if (dashed) {
        for (let k = 0; k < DASH_N; k++) {
          const c = (k - (DASH_N - 1) / 2) * DASH_PITCH;
          R.push(rect(a, b, c - DASH_ON / 2, c + DASH_ON / 2));
        }
      } else R.push(rect(a, b, -HALF, HALF));
      R.push(rect(BAND_OUT + 0.05, HALF, a, b));
    }
  } else if (piece === 'crossroads') {

    for (const [a, b] of bands) {
      R.push(rect(a, b, -HALF, -E0), rect(a, b, E0, HALF));
      R.push(rect(-HALF, -E0, a, b), rect(E0, HALF, a, b));
    }
  } else if (piece === 'end') {
    for (const [a, b] of bands) R.push(rect(a, b, -HALF, 2.0));
  }
  return R.filter(areal);
}

function zebra(R, band, across) {
  const [x0, x1, z0, z1] = band;
  const c0 = across === 'x' ? x0 : z0, c1 = across === 'x' ? x1 : z1;
  const n = Math.max(2, Math.floor((c1 - c0 + BAR_GAP) / (BAR_W + BAR_GAP)));
  const used = n * BAR_W + (n - 1) * BAR_GAP;
  const start = (c0 + c1) / 2 - used / 2;
  for (let k = 0; k < n; k++) {
    const a = start + k * (BAR_W + BAR_GAP), b = a + BAR_W;
    R.push(across === 'x' ? rect(a, b, z0, z1) : rect(x0, x1, a, b));
  }
}

function crossingBands(piece, arms) {
  if (piece === 'straight') {
    return [{ band: rect(-BAR_SPAN, BAR_SPAN, -BAND_STRAIGHT, BAND_STRAIGHT), across: 'x' }];
  }
  const lim = (has) => (has ? BAND_IN : BAR_SPAN);
  const xs = [-lim(arms.includes('W')), lim(arms.includes('E'))];
  const zs = [-lim(arms.includes('S')), lim(arms.includes('N'))];
  const out = [];
  for (const a of arms) {
    if (a === 'S') out.push({ band: rect(xs[0], xs[1], -BAND_OUT, -BAND_IN), across: 'x' });
    if (a === 'N') out.push({ band: rect(xs[0], xs[1], BAND_IN, BAND_OUT), across: 'x' });
    if (a === 'E') out.push({ band: rect(BAND_IN, BAND_OUT, zs[0], zs[1]), across: 'z' });
    if (a === 'W') out.push({ band: rect(-BAND_OUT, -BAND_IN, zs[0], zs[1]), across: 'z' });
  }
  return out;
}

function assemble(Z, C) {
  const g = new THREE.Group();
  g.name = 'two-lane-street-tile';
  const mesh = finish(COLOR_KEYS.map(k => ({ g: posGeo(Z[k]), c: C[k] })));
  mesh.name = 'street-surface';
  g.add(mesh);
  return g;
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {};
  for (const k of COLOR_KEYS) C[k] = p[k] !== undefined ? p[k] : cw[k];

  const piece = PIECE_KEYS.includes(p.piece) ? p.piece : DEF.piece;
  const lines = LINE_MODES.includes(p.lines) ? p.lines
    : (p.lines === true ? 'both' : DEF.lines);
  const crossing = p.crossing !== undefined ? !!p.crossing : DEF.crossing;
  const verge = p.vergeCourse !== undefined ? !!p.vergeCourse : DEF.vergeCourse;

  const arms = PIECE_ARMS[piece];
  const road = plan(arms);
  const Z = { asphalt: [], course: [], shoulder: [], paint: [], substrate: [] };

  const isRoad = (x, z) => road[x < -CARR ? 0 : x < CARR ? 1 : 2][z < -CARR ? 0 : z < CARR ? 1 : 2];
  const nearVerge = (x, z) => {
    const d = VERGE * 1.01;
    for (const [ox, oz] of [[d, 0], [-d, 0], [0, d], [0, -d]]) {
      const px = x + ox, pz = z + oz;
      if (Math.abs(px) < HALF && Math.abs(pz) < HALF && !isRoad(px, pz)) return true;
    }
    return false;
  };
  const L = surfaceLines(verge);
  for (let i = 0; i < L.length - 1; i++) {
    for (let j = 0; j < L.length - 1; j++) {
      const x0 = L[i], x1 = L[i + 1], z0 = L[j], z1 = L[j + 1];
      const cx = (x0 + x1) / 2, cz = (z0 + z1) / 2;
      const zone = !isRoad(cx, cz) ? 'shoulder'
        : (verge && nearVerge(cx, cz)) ? 'course' : 'asphalt';
      quadN(Z[zone], [x0, TOP_Y, z0], [x1, TOP_Y, z0], [x1, TOP_Y, z1], [x0, TOP_Y, z1], [0, 1, 0]);
    }
  }

  const P = HALF, M = -HALF;
  quadN(Z.substrate, [P, BOT_Y, M], [P, BOT_Y, P], [P, TOP_Y, P], [P, TOP_Y, M], [1, 0, 0]);
  quadN(Z.substrate, [M, BOT_Y, P], [M, BOT_Y, M], [M, TOP_Y, M], [M, TOP_Y, P], [-1, 0, 0]);
  quadN(Z.substrate, [M, BOT_Y, P], [P, BOT_Y, P], [P, TOP_Y, P], [M, TOP_Y, P], [0, 0, 1]);
  quadN(Z.substrate, [P, BOT_Y, M], [M, BOT_Y, M], [M, TOP_Y, M], [P, TOP_Y, M], [0, 0, -1]);
  quadN(Z.substrate, [M, BOT_Y, M], [P, BOT_Y, M], [P, BOT_Y, P], [M, BOT_Y, P], [0, -1, 0]);

  const wantCentre = lines !== 'none' && lines !== 'edges';
  const wantEdges = lines === 'edges' || lines === 'both' || lines === 'both-dashed';
  const dashed = lines === 'centre-dashed' || lines === 'both-dashed';

  const bands = crossing ? crossingBands(piece, arms) : [];
  const bandRects = bands.map(b => b.band);

  let marks = [];
  if (wantCentre) marks.push(...centreRects(piece, dashed));
  if (wantEdges) marks.push(...edgeRects(road));
  if (crossing) {

    if (piece === 'straight') {
      const z1 = -BAND_STRAIGHT - STOP_CLEAR;
      marks.push(rect(-E0, -C_OUT, z1 - STOP_DEEP, z1));
    }
  }
  if (piece === 't-junction' && wantCentre) {

    const x0 = crossing ? BAND_OUT + 0.05 : E0 - 0.20;
    marks.push(rect(x0, x0 + STOP_DEEP, -E0, -C_OUT));
  }
  marks = cutAll(marks, bandRects);
  for (const { band, across } of bands) zebra(marks, band, across);

  for (const [x0, x1, z0, z1] of marks) {
    quadN(Z.paint, [x0, TOP_Y + PAINT_UP, z0], [x1, TOP_Y + PAINT_UP, z0],
      [x1, TOP_Y + PAINT_UP, z1], [x0, TOP_Y + PAINT_UP, z1], [0, 1, 0]);
  }

  return assemble(Z, C);
}

export const params = {
  piece: {
    type: 'choice', default: 'straight', label: 'Road piece',
    options: ['straight', 'corner', 't-junction', 'crossroads', 'end'], affects: 'geometry',
    describe: 'Which piece of the road network this 8 m tile is — one asset covering every ' +
      'street surface the kit needs, so the honest alternative is five assets whose briefs ' +
      'differ by one word. The plan is REBUILT per value, not rotated: each value decides ' +
      'which of the four 7 m arms is carriageway and which is pale shoulder, so the margin ' +
      'wraps the outside of a turn on a corner, runs past the closed side of a t-junction, ' +
      'shrinks to four 0.5 m corner squares at a crossroads and closes the road on end. The ' +
      'markings follow the same plan. Every value is the same exact 8.000 m square centred on ' +
      'the origin and 0.05 m thick with the walkable face at y=0, so any piece drops into any ' +
      '2x2 block of the kit grid and butts its neighbours with no gap at any setting of any ' +
      'other knob. straight is the shipped default and runs the road along Z; corner turns ' +
      'traffic 90 degrees, entering at -Z and leaving at +X; t-junction adds a minor arm at ' +
      '+X; crossroads opens all four; end closes the road, leaving one mouth at -Z. Aim a ' +
      'piece in a scene with yaw alone.',
  },
  lines: {
    type: 'choice', default: 'none', label: 'Lane markings',
    options: ['none', 'centre', 'centre-dashed', 'edges', 'both', 'both-dashed'], affects: 'geometry',
    describe: 'Painted lane markings, as real geometry 2 mm proud of the road in the `paint` ' +
      'zone — never a texture, never a floating mesh. Whatever is selected FOLLOWS THE PIECE. ' +
      'none is the DEFAULT and leaves the asphalt bare, which is what you pave a whole street ' +
      'with: a mark baked into the default repeats across every copy in a grid. centre paints ' +
      'the twin solid no-passing lines that straddle the crown of the road in the reference, ' +
      'two 0.15 m stripes 0.15 m apart, bent round a corner as a pair of mitred right angles ' +
      'and stopped at the kerb line of the crossing road at a junction. centre-dashed swaps ' +
      'them for a single dashed lane line — five 0.8 m dashes on a 1.6 m pitch, phased so the ' +
      'gap across a tile joint equals the gap inside the tile and a chain of clones dashes ' +
      'evenly forever. edges paints a continuous line along the inner side of each shoulder, ' +
      'reaching every mouth at the same 0.15 m width and the same 0.425 m offset so butted ' +
      'copies read as one unbroken painted line, turning into every open arm as a mitred ' +
      'corner rather than stopping level and stepping past by a line width. both paints the ' +
      'twin centre lines and the edge lines together — the fully marked no-passing street. ' +
      'both-dashed is the same with the dashed lane line instead, which is the fully marked ' +
      'street of the reference and the busiest this tile gets.',
  },
  crossing: {
    type: 'toggle', default: false, label: 'Zebra crossing', affects: 'geometry',
    describe: 'Adds a zebra crossing in the same 2 mm proud paint — chunky 0.5 m bars running ' +
      'along the direction of travel and arrayed across the road, which is what makes it read ' +
      'as a ladder from above — plus the solid stop bar across the approaching lane that the ' +
      'reference draws behind it. OFF by default, for the same reason lines is none. On a ' +
      'straight the crossing lies across the middle of the cell; on every junction piece there ' +
      'is one at each open arm, stopping at the kerb line of any perpendicular arm exactly as ' +
      'a real crossing spans only the road it crosses. Every other marking is cut against the ' +
      'crossing, so a centre line stops at the zebra the way a real one does and no two ' +
      'painted faces ever overlap.',
  },
  vergeCourse: {
    type: 'toggle', default: true, label: 'Verge course', affects: 'geometry',
    describe: 'Whether the outermost 0.75 m paving pass either side of the carriageway is laid ' +
      'as a course of its own — a real longitudinal paving joint, one value rung off the running ' +
      'surface, in the `course` zone. ON by default and on every piece: it is the structure that ' +
      'breaks a 7 m sheet of tarmac into read-able planes, and it grades the margin from pale ' +
      'shoulder through mid course into the dark road so the direction of travel lands at a ' +
      'glance. It is not a mark and cannot make tiling readable: the course runs the full length ' +
      'of the road at a fixed offset, crossing both mouths and continuing straight into the next ' +
      'tile exactly as the shoulder does. Turn it OFF for a road resurfaced in one pass — the ' +
      'carriageway becomes one flat tone, the field grid drops the two course lines and the ' +
      'triangle count falls with them, which is the completely plain tile.',
  },
  colorway: {
    type: 'choice', default: 'fresh-asphalt', label: 'Colorway',
    options: ['fresh-asphalt', 'sun-bleached', 'oiled-tarmac', 'desert-highway'],
    describe: 'Curated kit-palette street scheme; sets all four zone colours at once. ' +
      'fresh-asphalt is the shipped dark blue-grey tarmac of the refs and carries the kit\'s ' +
      'REGISTERED road surface, so this tile and the 4 m road tile are one street. ' +
      'sun-bleached lifts the whole ladder for a pale weathered highway with near-white ' +
      'margins. oiled-tarmac drops it for an almost black freshly sealed road with cool steel ' +
      'shoulders. desert-highway keeps a mid grey road but takes the margins and the substrate ' +
      'to warm sand and earth, for a dusty roadside. Every scheme keeps the same ladder — verge ' +
      'course one rung off the asphalt, shoulder two clear rungs above that, paint above them ' +
      'all — because with the markings off that graded margin is the whole read.',
  },
  asphalt: {
    type: 'color', default: '#3d3f46', label: 'Asphalt',
    describe: 'Albedo of the running surface — the middle of the carriageway and every arm of a ' +
      'junction, about two thirds of the top face on the default piece (the outer paving pass ' +
      'either side belongs to the `course` zone). This is the kit\'s ' +
      'registered road surface: move it and this tile stops matching the 4 m road tile beside ' +
      'it. Keep it grey and dark; a tinted value here reads as painted floor, not asphalt.',
  },
  course: {
    type: 'color', default: '#4c4f57', label: 'Verge course',
    describe: 'Albedo of the outermost paving pass either side of the carriageway — the 0.75 m ' +
      'course laid against the verge, about 20% of the road. Keep it ONE rung off the asphalt: ' +
      'this is a paving joint between two pours of the same material, so a wide step here stops ' +
      'reading as asphalt and starts reading as a painted band. Take it darker than the asphalt ' +
      'instead for a road whose outer pass is the newer one. It emits nothing when vergeCourse ' +
      'is off.',
  },
  shoulder: {
    type: 'color', default: '#999ca3', label: 'Shoulder',
    describe: 'Albedo of the 0.5 m concrete margin down each side of the carriageway, flush ' +
      'with the road (a kerb standing proud cannot ship on a tile). On the plain default tile ' +
      'this is the ONLY value break the asset has, and it is what makes the square read as a ' +
      'road at all, so keep it clearly lighter than the asphalt — two rungs or more. On a ' +
      'junction piece it is also the shape that tells a viewer which way the road turns.',
  },
  paint: {
    type: 'color', default: '#f1f2ef', label: 'Marking paint',
    describe: 'Albedo of every painted marking — the twin centre lines, the edge lines, the ' +
      'stop bar and the zebra bars alike. It emits no triangles at all while lines is none and ' +
      'crossing is off, so on the bare default road it costs nothing. Keep it the lightest ' +
      'value in the scheme: paint reads by value against its own asphalt, so a mid grey here ' +
      'disappears. Take it warm off-white for old worn thermoplastic, or yellow-white for a ' +
      'street that marks its centre line in yellow.',
  },
  substrate: {
    type: 'color', default: '#1a1f26', label: 'Substrate',
    describe: 'Albedo of the 0.05 m cut edge all round the slab and the whole underside — the ' +
      'base course the road is laid on, and the same dark section the kit\'s 4 m road tile ' +
      'ships so a mixed run of the two shows one continuous dark line at the ground. It never ' +
      'reaches the top face, so it cannot disturb the road or the markings. Take it lighter ' +
      'for a road laid on pale gravel; keep it clearly darker than the asphalt or the tile ' +
      'loses the crisp line under its edge.',
  },
};

export const presets = COLORWAYS;
export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
