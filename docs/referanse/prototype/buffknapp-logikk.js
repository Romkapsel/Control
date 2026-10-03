// Utdrag av logikken i BuffKnapp.dc.html (knappekomponent, 40 px), versjon 18 av designcanvaset.
// Dette er REFERANSEOPPFØRSEL, ikke kode som skal kjøres i spillet.
// Det er JavaScript for designverktøyet (klassen DCLogic, renderVals() gir verdier til malen,
// this.state/this.setState som i React). Les det for å se nøyaktig hvordan reglene i SPEC.md
// er tenkt: alvorlighet, telling, ringfarge, hva som dukker opp ved knappen, tekster i tooltip.
// Egenskaper (props) for tavla: {"kind":{"editor":"enum","options":["paw","thorn","food","elixir","flaske","potion","bandage","stone","star","shield"],"default":"thorn"},"st":{"editor":"enum","options":["aktiv","snart","gatt","ikke"],"default":"aktiv"},"tid":{"editor":"text","default":"9 min"},"rest":{"editor":"range","min":0,"max":100,"step":1,"unit":"%","default":90},"antall":{"editor":"text","default":""},"effekt":{"editor":"enum","options":["ingen","mus","trykket","dra"],"default":"ingen"},"stille":{"editor":"boolean","default":false},"gruppe":{"editor":"text","default":""},"kamp":{"editor":"boolean","default":false},"$preview":{"width":40,"height":40}}
class Component extends DCLogic {
  renderVals() {
    const kind = this.props.kind ?? 'thorn';
    const st = this.props.st ?? 'aktiv';
    const tid = this.props.tid ?? '9 min';
    const rest = Math.max(0, Math.min(100, Number(this.props.rest ?? 90)));
    const antall = this.props.antall == null ? '' : String(this.props.antall);
    const effekt = this.props.effekt ?? 'ingen';
    const stille = !!this.props.stille;
    const gruppe = this.props.gruppe == null ? '' : String(this.props.gruppe).replace(/[^01]/g, '');
    const hasGruppe = !!gruppe;
    const kamp = !!this.props.kamp;
    const gruppeMangler = gruppe.indexOf('0') !== -1;
    const BG = {
      paw: 'radial-gradient(circle at 35% 28%, #c993e6 0%, #6a2e8c 45%, #2a0f3a 100%)',
      thorn: 'radial-gradient(circle at 35% 28%, #b9d46a 0%, #5d7a22 45%, #1c2808 100%)',
      food: 'radial-gradient(circle at 35% 28%, #f2b066 0%, #a4521a 45%, #3a1606 100%)',
      elixir: 'radial-gradient(circle at 35% 28%, #8fe0a0 0%, #2f8a4a 45%, #0b2a14 100%)',
      flaske: 'radial-gradient(circle at 35% 28%, #f59a86 0%, #a8302a 45%, #300806 100%)',
      potion: 'radial-gradient(circle at 35% 28%, #8aa6ff 0%, #3048b8 45%, #0c1446 100%)',
      bandage: 'radial-gradient(circle at 35% 28%, #d8c49a 0%, #8a744a 45%, #2e2412 100%)',
      stone: 'radial-gradient(circle at 35% 28%, #d6d6e0 0%, #707486 45%, #1c1e28 100%)',
      star: 'radial-gradient(circle at 35% 28%, #a6c8ff 0%, #4a6fd0 45%, #121e52 100%)',
      shield: 'radial-gradient(circle at 35% 28%, #f3e6a8 0%, #b0902e 45%, #3a2a08 100%)'
    };
    const mangler = st === 'gatt' || st === 'ikke';
    const tom = antall === '0' || antall === '×0' || antall.indexOf('0/') === 0;
    const dra = effekt === 'dra';
    const ring = '0 0 0 1px #4d4535, inset 0 0 0 1px rgba(255,255,255,.14), inset 0 0 9px rgba(0,0,0,.55)';
    return {
      bg: BG[kind] || BG.thorn,
      ring: dra ? ring + ', 0 8px 16px rgba(0,0,0,.65)' : ring,
      tid: tid,
      drain: 100 - rest,
      hasDrain: !hasGruppe && !mangler && rest < 100,
      small: !hasGruppe && st === 'aktiv' && !!tid,
      big: !hasGruppe && st === 'snart' && !!tid,
      tag: !hasGruppe && mangler && !!tid,
      glow: (hasGruppe ? gruppeMangler : mangler) && !stille,
      glyphMt: hasGruppe ? -5 : st === 'snart' ? 0 : mangler ? -6 : -9,
      hasGruppe: hasGruppe,
      pips: gruppe.split('').map((c) => (c === '1' ? { bg: '#F6EBCB', ring: '0 0 0 1px #000' } : { bg: 'rgba(0,0,0,.5)', ring: 'inset 0 0 0 1px #FFE98A' })),
      pipOp: kamp ? 0.45 : 1,
      glyphFilter: tom ? 'grayscale(1) brightness(.7)' : 'none',
      antall: antall,
      hasAntall: !!antall,
      antallColor: tom ? '#A0A0A0' : '#FFFFFF',
      kPaw: kind === 'paw', kThorn: kind === 'thorn', kFood: kind === 'food', kElixir: kind === 'elixir',
      kFlaske: kind === 'flaske', kPotion: kind === 'potion', kBandage: kind === 'bandage', kStone: kind === 'stone',
      kStar: kind === 'star', kShield: kind === 'shield',
      scale: effekt === 'trykket' ? 0.93 : 1,
      op: dra ? 0.88 : 1,
      over: effekt === 'mus' ? 'rgba(255,255,255,.12)' : effekt === 'trykket' ? 'radial-gradient(circle, rgba(255,243,176,.75), rgba(255,209,0,0) 72%)' : 'transparent',
      overRing: effekt === 'mus' ? 'inset 0 0 0 1px rgba(255,236,170,.75)' : 'none'
    };
  }
}
