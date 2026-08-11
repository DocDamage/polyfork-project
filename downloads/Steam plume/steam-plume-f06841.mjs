/*
 * Steam plume
 * https://polyfork.dev/asset/steam-plume-f06841
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './steam-plume-f06841.mjs';
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
 *   colorway  choice  'sunlit-steam' 'sunlit-steam' | 'copper-vent' | 'galvanised-vent' | 'dusk-vapour'
 *   wear      choice  'weathered'    'kept' | 'weathered' | 'derelict'
 *   courses   range   1              1 to 3
 *   facets    range   10             8 to 12
 *   plate     color   '#8FD3B6'      any hex or THREE.Color
 *   brass     color   '#E3B34A'      any hex or THREE.Color
 *   oxide     color   '#C2531F'      any hex or THREE.Color
 *   rust      color   '#E88C3C'      any hex or THREE.Color
 *   dark      color   '#13284D'      any hex or THREE.Color
 *   moss      color   '#5EA83A'      any hex or THREE.Color
 *   leaf      color   '#3B7A2E'      any hex or THREE.Color
 *
 * Every option is described in full at https://polyfork.dev/cdn/steam-plume-f06841-params.json
 *
 * SPECS  292 triangles, 1 material, 0.73 x 0.9 x 0.66 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const TAU = Math.PI * 2;

const COLORWAYS = {
  'sunlit-steam': {
    plate: '#8FD3B6', brass: '#E3B34A', oxide: '#C2531F', rust: '#E88C3C',
    dark: '#13284D', moss: '#5EA83A', leaf: '#3B7A2E',
  },
  'copper-vent': {
    plate: '#D2703A', brass: '#E3B34A', oxide: '#9E3B18', rust: '#E88C3C',
    dark: '#13284D', moss: '#5EA83A', leaf: '#24552A',
  },
  'galvanised-vent': {
    plate: '#B6BFC2', brass: '#D8A63A', oxide: '#C2531F', rust: '#E88C3C',
    dark: '#3A2C21', moss: '#8FCB4A', leaf: '#5EA83A',
  },
  'dusk-vapour': {
    plate: '#3E8F7C', brass: '#D8A63A', oxide: '#A8412F', rust: '#C2531F',
    dark: '#13284D', moss: '#3B7A2E', leaf: '#24552A',
  },
};
export const presets = COLORWAYS;

const ZONES = ['plate', 'brass', 'oxide', 'rust', 'dark', 'moss', 'leaf'];

export const params = {
  colorway: {
    type: 'choice', default: 'sunlit-steam', label: 'Colorway',
    options: ['sunlit-steam', 'copper-vent', 'galvanised-vent', 'dusk-vapour'],
    describe: 'curated kit-coherent scheme. sunlit-steam is the shipped default: a faded mint painted pot with warm orange rust, yellow brass and a deep navy throat. copper-vent turns the sheet to warm copper over a deeper barn-red oxide, so the pot reads hotter and heavier. galvanised-vent strips it back to bare grey sheet with bright orange blooms, a warm brown throat and fresh spring-green moss — the coolest and most industrial of the four. dusk-vapour drops the pot to a deep teal with a duller brass and a darker moss: the evening read.',
  },
  wear: {
    type: 'choice', default: 'weathered', affects: 'geometry', label: 'Wear',
    options: ['kept', 'weathered', 'derelict'],
    describe: 'how looked-after the pot is, and it is geometry rather than a repaint. kept: the pot is straight and freshly painted, its brass hoop bands and front seam strap whole, no repair plates, no oxide at all, and a thin tidy moss edging with two blades at the foot. weathered (default): oxide blooms in two warm tones at the foot seam, across the hourglass and under the rim flare, a pair of bolted brass repair plates proud of the flanks, and a fuller moss fillet with four blades. derelict: the lowest hoop band has broken clean away over two facets and the seam strap has gone with it, and a young sapling has come up out of a deep moss cushion with six blades. The footprint is identical at all three.',
  },
  courses: {
    type: 'range', default: 1, min: 1, max: 3, step: 1, affects: 'geometry', label: 'Barrel courses',
    describe: 'REBUILDS the pot taller by stacking more rolled-plate barrel courses above the waist step, it does not stretch it: a course is always the same 0.34 m of straight sheet and it arrives with its own brass hoop band at the seam, so every step adds real geometry and the triangle count moves with it. 1 (default) is the 0.90 m squat roof vent from the refs, with the single hoop band at the step. 2 is a 1.24 m pot with a second band. 3 is a 1.58 m banded stack pot for a boiler house. The foot, the hourglass, the flare, the rim bore and everything bolted to them are identical at every setting — only the barrel between them grows, which is how a real rolled-plate vessel is made taller.',
  },
  facets: {
    type: 'range', default: 10, min: 8, max: 12, step: 2, affects: 'geometry', label: 'Plate facets',
    describe: 'how many rolled-plate facets go round the pot. 8 is a chunky, obviously hand-beaten octagon that reads as heavy salvage; 10 (default) is the reference; 12 rounds it off into a smoothly spun vessel. Everything booked on the shell — the oxide blooms, the bright rust patches, the bolted repair plates, the broken band on derelict and the moss two-tone — is booked by mirror class rather than by facet number, so the pattern keeps its shape and its symmetry at every count.',
  },
  plate: { type: 'color', default: '#8FD3B6', label: 'Vent pot', describe: 'albedo of the salvaged pot\'s painted sheet — faded mint, the asset\'s one big block of saturated colour' },
  brass: { type: 'color', default: '#E3B34A', label: 'Brass', describe: 'albedo of the hoop bands, the front seam strap and the bolted repair plates; the polished-metal accent, kept brighter and more chromatic than the pot itself' },
  oxide: { type: 'color', default: '#C2531F', label: 'Rust deep', describe: 'albedo of the deep rust blooms at the pot\'s seams and under the rim flare; warm orange oxide, never a brown-grey sludge' },
  rust:  { type: 'color', default: '#E88C3C', label: 'Rust bloom', describe: 'albedo of the bright second oxide tone, patched against the deep one so the rust reads as two ragged tones rather than one even wash' },
  dark:  { type: 'color', default: '#13284D', label: 'Throat', describe: 'albedo of the open throat inside the rim and of its floor — a real modelled opening the camera looks down into, never a painted line. This is the surface the animated vapour rises out of' },
  moss:  { type: 'color', default: '#5EA83A', label: 'Moss', describe: 'albedo of the lit top of the moss fillet where the pot meets the ground, and of the sapling\'s leaves' },
  leaf:  { type: 'color', default: '#3B7A2E', label: 'Blades', describe: 'albedo of the grass blades and the sapling stem, and of the moss in shade; always a deeper green than the moss so the cushion reads as two tones' },
};

export const rig = {};
export const detach = [];
export const night = {};

export const emitter = {
  node: 'steam-emit', shape: 'disc', axis: [0, 1, 0],
  describe: 'centre of the rim bore, in the plane of the rim face, pointing straight up out of the dark throat',
};

const R_FOOT    = 0.300;
const R_WAIST   = 0.190;
const R_STEP    = 0.250;
const R_BARREL  = 0.252;
const R_RIM     = 0.316;
const R_LIP     = 0.330;
const R_BORE    = 0.268;
const R_THROAT  = 0.235;
const Y_STEP    = 0.520;
const Y_FLARE   = 0.860;
const Y_LIP0    = 0.900;
const Y_FLOOR   = 0.500;
const COURSE_H  = 0.340;
const BAND_OUT  = 0.030;
const STRAP_OUT = 0.020;
const PLATE_IN  = 0.028;

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function roll(key) {
  const r = prng((Math.abs(Math.round(key)) * 40503) % 2147483647 + 1);
  r(); r(); return r();
}

function makeSink() {
  const buckets = new Map();
  const bucket = (hex) => { let a = buckets.get(hex); if (!a) buckets.set(hex, a = []); return a; };
  return {
    buckets,
    tri(hex, a, b, c) {
      bucket(hex).push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    },
    quad(hex, a, b, c, d) { this.tri(hex, a, b, c); this.tri(hex, a, c, d); },
  };
}

function meshFrom(sink, mat, name) {
  const geos = [];
  for (const [hex, pos] of sink.buckets) {
    if (!pos.length) continue;
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    const c = new THREE.Color(hex);
    const n = pos.length / 3;
    const col = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    geos.push(g);
  }

  const m0 = mergeGeometries(geos);
  const merged = m0.index ? m0.toNonIndexed() : m0;
  merged.computeVertexNormals();
  const m = new THREE.Mesh(merged, mat);
  m.name = name;
  return m;
}

const fkey = (j, N) => { const a = ((j % N) + N) % N; return Math.min(a, (N - a) % N); };

function revolve(sink, prof, N, colorFor, opt = {}) {
  const { skip } = opt;
  const step = TAU / N;
  const P = (r, y, j) => {
    const a = (j - 0.5) * step;
    return [r * Math.sin(a), y, r * Math.cos(a)];
  };
  for (let b = 0; b < prof.length - 1; b++) {
    const [r0, y0] = prof[b], [r1, y1] = prof[b + 1];
    if (r0 === 0 && r1 === 0) continue;
    for (let j = 0; j < N; j++) {
      if (skip && skip(b, j)) continue;
      const hex = colorFor(b, j);
      const A = P(r0, y0, j), B = P(r0, y0, j + 1), C = P(r1, y1, j + 1), D = P(r1, y1, j);
      if (r0 === 0) sink.tri(hex, [0, y0, 0], C, D);
      else if (r1 === 0) sink.tri(hex, A, B, [0, y1, 0]);
      else sink.quad(hex, A, B, C, D);
    }
  }
}

function blade(sink, hex, base, lean, h, w) {
  const ring = [];
  for (let k = 0; k < 3; k++) {
    const a = (k / 3) * TAU;
    ring.push([base[0] + Math.sin(a) * w, base[1], base[2] + Math.cos(a) * w]);
  }
  const tip = [base[0] + lean[0], base[1] + h, base[2] + lean[2]];
  for (let k = 0; k < 3; k++) sink.tri(hex, ring[k], ring[(k + 1) % 3], tip);
}

function facetPlate(sink, hex, j, N, y0, y1, rAt, out, halfSpan) {
  const step = TAU / N;
  const a0 = j * step - halfSpan, a1 = j * step + halfSpan;
  const pt = (a, y, o) => { const r = rAt(y) + o; return [r * Math.sin(a), y, r * Math.cos(a)]; };
  const o = [pt(a0, y0, out), pt(a1, y0, out), pt(a1, y1, out), pt(a0, y1, out)];
  const i = [pt(a0, y0, -PLATE_IN), pt(a1, y0, -PLATE_IN), pt(a1, y1, -PLATE_IN), pt(a0, y1, -PLATE_IN)];
  sink.quad(hex, o[0], o[1], o[2], o[3]);
  sink.quad(hex, i[0], i[1], o[1], o[0]);
  sink.quad(hex, i[2], i[3], o[3], o[2]);
  sink.quad(hex, i[3], i[0], o[0], o[3]);
  sink.quad(hex, i[1], i[2], o[2], o[1]);
}

export function createAsset(opts = {}) {
  const P = {
    colorway: params.colorway.default,
    wear: params.wear.default,
    courses: params.courses.default,
    facets: params.facets.default,
    ...opts,
  };

  const C = {};
  for (const z of ZONES) C[z] = params[z].default;
  const cw = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  for (const z of ZONES) if (cw[z]) C[z] = cw[z];
  for (const z of ZONES) if (opts[z] !== undefined) C[z] = opts[z];

  const wear = ['kept', 'weathered', 'derelict'].includes(P.wear) ? P.wear : 'weathered';
  const CO = Math.max(1, Math.min(3, Math.round(P.courses)));
  const N = Math.max(8, Math.min(12, Math.round(P.facets / 2) * 2));
  const nC = CO - 1;
  const dY = nC * COURSE_H;
  const Y_LIP = Y_LIP0 + dY;

  const sink = makeSink();

  const potProf = [
    [0.000, 0.000], [R_FOOT, 0.000], [0.292, 0.075], [R_WAIST, 0.300],
    [R_STEP, 0.440], [R_BARREL, Y_STEP],
  ];
  for (let i = 1; i <= nC; i++) potProf.push([R_BARREL, Y_STEP + i * COURSE_H]);
  potProf.push([R_RIM, Y_FLARE + dY], [R_LIP, Y_LIP], [R_BORE, Y_LIP - 0.016]);

  const yTaper = Y_LIP - 0.400;
  potProf.push([R_THROAT, yTaper]);
  if (yTaper - Y_FLOOR > 1e-9) potProf.push([R_THROAT, Y_FLOOR]);
  potProf.push([0.000, Y_FLOOR]);

  const B = { foot: 1, hour: 2, wout: 3, step: 4, course: 5, flare: 5 + nC, lip: 6 + nC };
  const B_DARK = 8 + nC;

  const WALL = potProf.slice(1, 8 + nC);
  function rPot(y) {
    const yy = Math.max(0, Math.min(Y_LIP, y));
    for (let i = 0; i < WALL.length - 1; i++) {
      const [r0, y0] = WALL[i], [r1, y1] = WALL[i + 1];
      if (yy >= y0 && yy <= y1) return y1 > y0 ? r0 + (r1 - r0) * ((yy - y0) / (y1 - y0)) : r0;
    }
    return WALL[WALL.length - 1][0];
  }

  const OXIDE = wear === 'kept' ? [] : [[B.foot, [2, 3]], [B.lip, [0, 1]], [B.flare, [2]]];
  const BLOOM = wear === 'kept' ? [] : [[B.foot, [1]], [B.lip, [4]], [B.step, [4]], [B.wout, [2]]];

  if (wear !== 'kept' && nC > 0) OXIDE.push([B.course + nC - 1, [3]]);
  const booked = (table, b, j) => table.some(([bb, ks]) => bb === b && ks.includes(fkey(j, N)));

  revolve(sink, potProf, N, (b, j) => {
    if (b >= B_DARK) return C.dark;
    if (booked(BLOOM, b, j)) return C.rust;
    if (booked(OXIDE, b, j)) return C.oxide;
    return C.plate;
  });

  const bandYs = [0.470];
  for (let i = 1; i <= nC; i++) bandYs.push(Y_STEP + i * COURSE_H);
  const gone = wear === 'derelict' ? [3] : [];
  bandYs.forEach((ym, bi) => {
    const bandProf = [
      [rPot(ym - 0.050) - 0.006, ym - 0.050], [rPot(ym) + BAND_OUT, ym],
      [rPot(ym + 0.050) - 0.006, ym + 0.050],
    ];
    const broken = bi === 0 ? gone : [];
    revolve(sink, bandProf, N, () => C.brass,
      { skip: (b, j) => broken.includes(fkey(j, N)) });
    for (let j = 0; j < N; j++) {
      if (!broken.includes(fkey(j, N))) continue;
      for (const e of [j - 0.5, j + 0.5]) {
        const a = e * (TAU / N);
        const q = bandProf.map(([r, y]) => [r * Math.sin(a), y, r * Math.cos(a)]);
        sink.tri(C.brass, q[0], q[1], q[2]);
      }
    }
  });

  if (wear !== 'derelict') facetPlate(sink, C.brass, 0, N, 0.070, Y_LIP - 0.045, rPot, STRAP_OUT, 0.082);

  if (wear !== 'kept') for (const j of [2, N - 2]) {
    facetPlate(sink, C.brass, j, N, Y_LIP - 0.340, Y_LIP - 0.140, rPot, 0.022, 0.230);
  }

  const g = wear === 'kept' ? 0.55 : wear === 'derelict' ? 1.45 : 1.0;
  const mR = 0.296 + 0.052 * g, mY = 0.030 + 0.042 * g;
  revolve(sink, [[0, 0.004], [mR, 0.004], [rPot(mY) - 0.014, mY]], N,
    (b, j) => (b === 0 ? C.leaf : ([1, 4].includes(fkey(j, N)) ? C.leaf : C.moss)));

  const nPair = wear === 'kept' ? 1 : wear === 'derelict' ? 3 : 2;
  const bR = Math.max(mR * 0.86, R_FOOT + 0.015);
  for (let p = 0; p < nPair; p++) {
    const a = 0.55 + p * 1.05;
    const h = 0.13 + roll(700 + p) * 0.11;
    for (const s of [1, -1]) {
      blade(sink, C.leaf, [s * Math.sin(a) * bR, 0.012, Math.cos(a) * bR],
        [s * Math.sin(a) * 0.05, 0, Math.cos(a) * 0.05], h, 0.022);
    }
  }
  if (wear === 'derelict') {
    const sz = -mR * 0.90;
    blade(sink, C.leaf, [0, 0.012, sz], [0, 0, -0.03], 0.40, 0.026);
    for (let i = 0; i < 3; i++) {
      const a = i === 0 ? Math.PI : (i === 1 ? 0.9 : -0.9);
      blade(sink, C.moss, [0, 0.20 + i * 0.07, sz], [Math.sin(a) * 0.15, 0.03, Math.cos(a) * 0.15], 0.05, 0.024);
    }
  }

  const group = new THREE.Group();
  group.name = 'steam-vent-pot';
  const mat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
  const mesh = meshFrom(sink, mat, 'pot');
  mesh.geometry.computeBoundingBox();
  const drop = -mesh.geometry.boundingBox.min.y;
  mesh.geometry.translate(0, drop, 0);
  group.add(mesh);

  const emit = new THREE.Object3D();
  emit.name = emitter.node;
  emit.position.set(0, Y_LIP - 0.016 + drop, 0);
  emit.userData.radius = R_BORE;
  group.add(emit);

  return group;
}

export default createAsset;
