/*
 * Roller Shutter
 * https://polyfork.dev/asset/roller-shutter-c58b4f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './roller-shutter-c58b4f.mjs';
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
 *   colorway      choice  'zinc-shutter' 'zinc-shutter' | 'machiya-cream' | 'matcha-green' | 'tokyo-blue' | 'shutter-r…
 *   frame         color   '#E4E2DC'      any hex or THREE.Color
 *   curtain       color   '#A9AFB4'      any hex or THREE.Color
 *   hood          color   '#8A9197'      any hex or THREE.Color
 *   lid           color   '#6B7278'      any hex or THREE.Color
 *   sill          color   '#2E3134'      any hex or THREE.Color
 *   lights        color   '#1B1D20'      any hex or THREE.Color
 *   slatPitch     range   0.115          0.09 to 0.22
 *   hoodHeight    range   0.52           0.42 to 0.72
 *   flutes        range   20             10 to 28
 *   visionLights  range   7              0 to 9
 *
 * Every option is described in full at https://polyfork.dev/cdn/roller-shutter-c58b4f-params.json
 *
 * SPECS  400 triangles, 1 material, 4 x 2.6 x 0.6 m (real-world scale).
 * PARTS  animate: curtain
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'zinc-shutter', label: 'Colorway',
    options: ['zinc-shutter', 'machiya-cream', 'matcha-green', 'tokyo-blue', 'shutter-red'],
    describe: 'curated kit-palette scheme; sets all six zone colours at once. zinc-shutter '
            + 'is the approved default: a mid grey painted-steel curtain in a pale cream '
            + 'surround, the hood one step darker. machiya-cream is the whole panel in warm '
            + 'timber-shop creams and browns for an older frontage. matcha-green, tokyo-blue '
            + 'and shutter-red repaint the curtain and hood in deep green, steel blue and '
            + 'rust red respectively and keep the cream surround, for a row of shops that '
            + 'reads varied from across the street. The floor bar stays near-black and the '
            + 'vision panes stay black glass in every scheme.',
  },
  frame: {
    type: 'color', default: '#E4E2DC', label: 'Frame',
    describe: 'albedo of the painted surround: both guide jambs, the hood top and bottom '
            + 'rails, the hood corner posts, the hood rim around the lid and the hood '
            + 'soffit. The lightest zone on the part — keep it a clear step above the '
            + 'curtain or the bay stops reading as metal set into paintwork.',
  },
  curtain: {
    type: 'color', default: '#A9AFB4', label: 'Curtain',
    describe: 'albedo of the corrugated laths and of the vision-band recess floor between '
            + 'the panes — the biggest zone on the part, about 40% of the front elevation. '
            + 'The laths are one flat tone: their light tops and dark grooves come from the '
            + 'scene lights hitting real geometry.',
  },
  hood: {
    type: 'color', default: '#8A9197', label: 'Hood fluting',
    describe: 'albedo of the vertically fluted band wrapping the roller housing front and '
            + 'both sides, plus the housing back and the mounting plate behind the curtain. '
            + 'Sits between the frame cream and the slate lid in value so the hood reads as '
            + 'three stacked bands from 10 m.',
  },
  lid: {
    type: 'color', default: '#6B7278', label: 'Hood lid',
    describe: 'albedo of the flat panel sunk inside the rim on TOP of the roller housing. '
            + 'Only visible from above and from the hero three-quarter; the darkest large '
            + 'zone, which is what makes the rim around it read as a raised frame.',
  },
  sill: {
    type: 'color', default: '#2E3134', label: 'Floor bar',
    describe: 'albedo of the rubber floor bar, the curtain bottom rail sitting on it and '
            + 'the lift handle. Near-black by design: it is the base band that grounds the '
            + 'panel, and the three parts always change together, so they are one zone.',
  },
  lights: {
    type: 'color', default: '#1B1D20', label: 'Vision panes',
    describe: 'albedo of the row of glazed panes sunk into the curtain near the top and of '
            + 'the shop void behind the curtain. Keep it near-black and distinct from the '
            + 'floor bar: this is the zone the night export lights, so anything sharing its '
            + 'hex would glow with it after dark.',
  },
  slatPitch: {
    type: 'range', default: 0.115, min: 0.09, max: 0.22, affects: 'geometry',
    label: 'Lath pitch',
    describe: 'height of one corrugation of the curtain, in metres. The curtain field is a '
            + 'fixed height, so this REBUILDS the lath run rather than stretching it: the '
            + 'count is round(field / pitch) and the triangle count moves with it. 0.09 '
            + 'gives about 21 fine laths and a finely ribbed sheet; 0.22 gives about 8 deep '
            + 'chunky laths that read as a stack of planks. Because the count is an integer '
            + 'the delivered pitch quantizes in steps of roughly 0.006-0.03 m.',
  },
  hoodHeight: {
    type: 'range', default: 0.52, min: 0.42, max: 0.72, affects: 'geometry',
    label: 'Hood height',
    describe: 'height of the boxed roller housing, in metres, measured down from the fixed '
            + '2.6 m top. Total height never changes, so a taller hood eats into the curtain '
            + 'and the lath run is REBUILT with fewer laths at the same pitch (the triangle '
            + 'count drops). 0.42 is a slim lintel hood over a tall shutter; 0.72 is a deep '
            + 'housing that owns the top quarter of the panel and carries a much taller '
            + 'fluted band.',
  },
  flutes: {
    type: 'range', default: 20, min: 10, max: 28, step: 1, affects: 'geometry',
    label: 'Hood flutes',
    describe: 'number of vertical grooves cut across the hood front panel between the corner '
            + 'posts. 10 gives broad 0.37 m ribs that read as coarse panelling; 28 gives fine '
            + '0.13 m fluting close to the reference. The grooves are 45 mm deep at every '
            + 'count so they still shade themselves, and the triangle count scales with it.',
  },
  visionLights: {
    type: 'range', default: 7, min: 0, max: 9, step: 1, affects: 'geometry',
    label: 'Vision panes',
    describe: 'number of glazed panes in the band near the top of the curtain, each sunk in '
            + 'its own pocket. 0 removes the band entirely and the laths run unbroken to the '
            + 'hood, for a blind security shutter; 9 gives a near-continuous row of narrow '
            + 'windows. Panes are always centred and evenly spaced across the middle 3.1 m, '
            + 'so any count stays symmetric.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'zinc-shutter':  { frame: '#E4E2DC', curtain: '#A9AFB4', hood: '#8A9197', lid: '#6B7278', sill: '#2E3134', lights: '#1B1D20' },
  'machiya-cream': { frame: '#F2EFE7', curtain: '#D8D2C4', hood: '#B9A88C', lid: '#8C7355', sill: '#42352A', lights: '#1B1D20' },
  'matcha-green':  { frame: '#E4E2DC', curtain: '#2F6B4F', hood: '#3F8A5E', lid: '#4E5459', sill: '#2E3134', lights: '#1B1D20' },
  'tokyo-blue':    { frame: '#C9DDE6', curtain: '#5B6E8C', hood: '#8FB4C9', lid: '#4E5459', sill: '#2E3134', lights: '#1B1D20' },
  'shutter-red':   { frame: '#E4E2DC', curtain: '#B5462F', hood: '#D6452F', lid: '#8E1F1B', sill: '#2E3134', lights: '#1B1D20' },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: {
      F: hex(p.frame), U: hex(p.curtain), H: hex(p.hood),
      L: hex(p.lid), S: hex(p.sill), G: hex(p.lights),
    },
    pitch: clamp(p.slatPitch, 0.09, 0.22),
    hoodH: clamp(p.hoodHeight, 0.42, 0.72),
    flutes: Math.round(clamp(p.flutes, 10, 28)),
    panes: Math.round(clamp(p.visionLights, 0, 9)),
  };
}

const W = 4.00, HW = W / 2;
const H = 2.60;
const ZB = -0.30, ZF = 0.30;
const MOUNT_T = 0.08;
const ZM = ZB + MOUNT_T;
const PL_H = 0.07, PL_Z = 0.12;
const JAMB_W = 0.34;
const JAMB_Z = 0.02;
const ZC = -0.12, ZCG = -0.155;
const ZR = -0.17, ZP = -0.19;
const CUR_HX = HW - JAMB_W + 0.02;
const RAIL_H = 0.13, RAIL_BED = 0.03;
const BAND_H = 0.19, BAND_GAP = 0.055;
const PANE_HX = 1.55, PANE_FILL = 0.62, PANE_MY = 0.030;
const POST = 0.15;
const FLUTE_D = 0.045;
const RAIL_B = 0.115, RAIL_T = 0.135;
const RIM = 0.10, LID_DROP = 0.055;
const CH = 0.03;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
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

function wall(out, p, q, x0, x1) {
  quad(out, [x0, p[1], p[0]], [x1, p[1], p[0]], [x1, q[1], q[0]], [x0, q[1], q[0]]);
}

function boxM(out, x0, x1, y0, y1, z0, z1, f) {
  if (f.includes('+z')) quad(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]);
  if (f.includes('-z')) quad(out, [x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0]);
  if (f.includes('+x')) quad(out, [x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1]);
  if (f.includes('-x')) quad(out, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0]);
  if (f.includes('+y')) quad(out, [x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0]);
  if (f.includes('-y')) quad(out, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1]);
}

function ring(out, oX, oZ, yO, iX, iZ, yI, flip) {
  const O = [[-oX, yO, oZ[1]], [oX, yO, oZ[1]], [oX, yO, oZ[0]], [-oX, yO, oZ[0]]];
  const I = [[-iX, yI, iZ[1]], [iX, yI, iZ[1]], [iX, yI, iZ[0]], [-iX, yI, iZ[0]]];
  for (let k = 0; k < 4; k++) {
    const a = O[k], b = O[(k + 1) % 4], c = I[(k + 1) % 4], d = I[k];
    if (flip) quad(out, d, c, b, a); else quad(out, a, b, c, d);
  }
}

function pocket(out, x0, x1, y0, y1, zOut, zIn) {
  quad(out, [x0, y0, zIn], [x1, y0, zIn], [x1, y1, zIn], [x0, y1, zIn]);
  quad(out, [x0, y0, zIn], [x0, y1, zIn], [x0, y1, zOut], [x0, y0, zOut]);
  quad(out, [x1, y0, zIn], [x1, y0, zOut], [x1, y1, zOut], [x1, y1, zIn]);
  quad(out, [x0, y0, zIn], [x0, y0, zOut], [x1, y0, zOut], [x1, y0, zIn]);
  quad(out, [x0, y1, zIn], [x1, y1, zIn], [x1, y1, zOut], [x0, y1, zOut]);
}

function finish(buf, material, name) {
  const merged = mergeGeometries(
    Object.entries(buf).filter(([, p]) => p.length)
      .map(([hex, p]) => prep(posGeo(p), Number(hex)))
  );
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, material);
  mesh.name = name;
  return mesh;
}

export function createAsset(userParams = {}) {
  const { C, pitch, hoodH, flutes, panes } = resolve(userParams);

  const yHood = H - hoodH;
  const yRail = PL_H + RAIL_H;
  const hasBand = panes > 0;
  const yBandTop = yHood - BAND_GAP;
  const yBandBot = yBandTop - BAND_H;
  const yLathTop = hasBand ? yBandBot : yHood;
  const nLath = Math.max(4, Math.round((yLathTop - yRail) / pitch));
  const p = (yLathTop - yRail) / nLath;

  const S = {}, K = {};
  const s = (hex) => (S[hex] ||= []);
  const k = (hex) => (K[hex] ||= []);

  boxM(s(C.S), -HW, HW, 0, PL_H - CH, ZB, PL_Z, '+z+x-x-z-y');
  boxM(s(C.S), -HW, HW, PL_H - CH, PL_H, ZB, PL_Z - CH, '+x-x');
  quad(s(C.S), [-HW, PL_H - CH, PL_Z], [HW, PL_H - CH, PL_Z],
               [HW, PL_H, PL_Z - CH], [-HW, PL_H, PL_Z - CH]);
  quad(s(C.S), [-HW, PL_H, PL_Z - CH], [HW, PL_H, PL_Z - CH],
               [HW, PL_H, ZB], [-HW, PL_H, ZB]);

  tri(s(C.S), [HW, PL_H - CH, PL_Z], [HW, PL_H - CH, PL_Z - CH], [HW, PL_H, PL_Z - CH]);
  tri(s(C.S), [-HW, PL_H - CH, PL_Z - CH], [-HW, PL_H - CH, PL_Z], [-HW, PL_H, PL_Z - CH]);

  boxM(s(C.H), -HW, HW, PL_H - 0.02, yHood + 0.01, ZB, ZM, '-z');
  quad(s(C.G), [-CUR_HX - 0.02, PL_H - 0.02, ZM], [CUR_HX + 0.02, PL_H - 0.02, ZM],
               [CUR_HX + 0.02, yHood + 0.01, ZM], [-CUR_HX - 0.02, yHood + 0.01, ZM]);

  for (const side of [1, -1]) {
    const xo = side * HW, xi = side * (HW - JAMB_W);
    const xc = xi + side * CH;
    const col = s(C.F), y0 = 0.03, y1 = yHood + 0.02;

    const [f0, f1] = side > 0 ? [xc, xo] : [xo, xc];
    quad(col, [f0, y0, JAMB_Z], [f1, y0, JAMB_Z], [f1, y1, JAMB_Z], [f0, y1, JAMB_Z]);

    const A = [xi, y0, JAMB_Z - CH], B = [xc, y0, JAMB_Z];
    const Ct = [xc, y1, JAMB_Z], Dt = [xi, y1, JAMB_Z - CH];
    if (side > 0) quad(col, A, B, Ct, Dt); else quad(col, B, A, Dt, Ct);

    boxM(col, xi, xi, y0, y1, ZM, JAMB_Z - CH, side > 0 ? '-x' : '+x');

    boxM(col, xo, xo, PL_H, y1, ZB, JAMB_Z, side > 0 ? '+x' : '-x');
  }

  {
    const yF0 = yHood + RAIL_B, yF1 = H - RAIL_T;
    const yTop = H - CH, yLip = yHood + CH;
    const col = s(C.F), fl = s(C.H);

    quad(col, [-HW + CH, yHood, ZB + CH], [HW - CH, yHood, ZB + CH],
              [HW - CH, yHood, ZF - CH], [-HW + CH, yHood, ZF - CH]);
    ring(col, HW, [ZB, ZF], yLip, HW - CH, [ZB + CH, ZF - CH], yHood, true);

    quad(col, [-HW, yLip, ZF], [HW, yLip, ZF], [HW, yF0, ZF], [-HW, yF0, ZF]);
    quad(col, [-HW, yF1, ZF], [HW, yF1, ZF], [HW, yTop, ZF], [-HW, yTop, ZF]);
    for (const side of [1, -1]) {
      const a = side * (HW - POST), b = side * HW;
      const [x0, x1] = side > 0 ? [a, b] : [b, a];
      quad(col, [x0, yF0, ZF], [x1, yF0, ZF], [x1, yF1, ZF], [x0, yF1, ZF]);
    }

    const fx = HW - POST, step = (2 * fx) / (2 * flutes);
    for (let i = 0; i < 2 * flutes; i++) {
      const x0 = -fx + i * step, x1 = (i === 2 * flutes - 1) ? fx : -fx + (i + 1) * step;
      const z0 = i % 2 === 0 ? ZF : ZF - FLUTE_D, z1 = i % 2 === 0 ? ZF - FLUTE_D : ZF;
      quad(fl, [x0, yF0, z0], [x1, yF0, z1], [x1, yF1, z1], [x0, yF1, z0]);
    }

    for (const side of [1, -1]) {
      const x = side * HW, f = side > 0 ? '+x' : '-x';
      boxM(col, x, x, yLip, yF0, ZB, ZF, f);
      boxM(fl, x, x, yF0, yF1, ZB, ZF, f);
      boxM(col, x, x, yF1, yTop, ZB, ZF, f);
    }
    boxM(fl, -HW, HW, yLip, yTop, ZB, ZF, '-z');

    ring(col, HW, [ZB, ZF], yTop, HW - CH, [ZB + CH, ZF - CH], H, false);
    ring(col, HW - CH, [ZB + CH, ZF - CH], H, HW - CH - RIM, [ZB + CH + RIM, ZF - CH - RIM], H, false);
    ring(col, HW - CH - RIM, [ZB + CH + RIM, ZF - CH - RIM], H,
         HW - CH - RIM, [ZB + CH + RIM, ZF - CH - RIM], H - LID_DROP, false);
    const lx = HW - CH - RIM, lz0 = ZB + CH + RIM, lz1 = ZF - CH - RIM;
    quad(s(C.L), [-lx, H - LID_DROP, lz1], [lx, H - LID_DROP, lz1],
                 [lx, H - LID_DROP, lz0], [-lx, H - LID_DROP, lz0]);
  }

  {
    const X = CUR_HX;

    boxM(k(C.S), -X, X, PL_H - RAIL_BED, yRail, ZC - 0.055, ZC + 0.035, '+z+y-y-z');

    boxM(k(C.S), -0.34, 0.34, yRail + 0.05, yRail + 0.15, ZCG - 0.005, ZC + 0.055,
         '+z+x-x+y-y');

    const prof = [[ZC, yRail]];
    for (let i = 0; i < nLath; i++) {
      const y0 = yRail + i * p;
      prof.push([ZC, y0 + 0.60 * p], [ZCG, y0 + 0.80 * p], [ZC, y0 + p]);
    }
    for (let i = 0; i + 1 < prof.length; i++) wall(k(C.U), prof[i], prof[i + 1], -X, X);

    if (hasBand) {

      wall(k(C.U), [ZC, yBandBot], [ZR, yBandBot], -X, X);
      wall(k(C.U), [ZR, yBandTop], [ZC, yBandTop], -X, X);
      wall(k(C.U), [ZC, yBandTop], [ZC, yHood], -X, X);

      const cw = (2 * PANE_HX) / panes, pw = PANE_FILL * cw;
      const floor = (x0, x1, y0, y1) => quad(k(C.U),
        [x0, y0, ZR], [x1, y0, ZR], [x1, y1, ZR], [x0, y1, ZR]);
      let xPrev = -X;
      for (let i = 0; i < panes; i++) {
        const cx = -PANE_HX + (i + 0.5) * cw, a = cx - pw / 2, b = cx + pw / 2;
        floor(xPrev, a, yBandBot, yBandTop);
        floor(a, b, yBandBot, yBandBot + PANE_MY);
        floor(a, b, yBandTop - PANE_MY, yBandTop);
        pocket(k(C.G), a, b, yBandBot + PANE_MY, yBandTop - PANE_MY, ZR, ZP);
        xPrev = b;
      }
      floor(xPrev, X, yBandBot, yBandTop);
    }
  }

  const material = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const g = new THREE.Group();
  g.name = 'roller-shutter';
  g.add(finish(S, material, 'shutter-frame'));

  const curtain = new THREE.Group();
  curtain.name = 'curtain';
  curtain.add(finish(K, material, 'shutter-curtain'));
  g.add(curtain);
  return g;
}

export const rig = { curtain: { axis: 'y', range: [0, 0.35], type: 'slide' } };

export const detach = [];

export const night = {
  lights: {
    color: '#F0C24B', intensity: 0.55,
    describe: 'shop lighting leaking out through the row of glazed vision panes near the '
            + 'top of the curtain, and out of the void behind the curtain when it is raised',
  },
};

export default createAsset;
