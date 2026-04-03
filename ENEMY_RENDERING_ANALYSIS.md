# Análise das Funções de Renderização de Inimigos

## Visão Geral
O arquivo `index.html` contém 3 funções principais de desenho para inimigos, todas usando **desenho programático 2D com Canvas (ctx)**, sem uso de sprites PNG (exceto informações visuais).

---

## 1. `drawSlimes()` - Slimes/Zumbis
**Localização:** Linhas 8436-8900+

### Estrutura da Função
```javascript
function drawSlimes() {
    // Itera por slimes visíveis dentro da viewport
    for (var i = 0; i < slimes.length; i++) {
        var z = slimes[i];
        if (z.y < viewTop || z.y > viewBot) continue;  // Culling de viewport
        if (++_zombieDrawn > MAX_SLIMES_VISIBLE) break;  // Limite de renderização (8)
```

### Características de Renderização

#### **Tamanho e Escala**
- Base: `SLIME_SIZE = TILE * 1.05` (~113 pixels)
- Boss: multiplicado por `z.bossScale` (até 3x maior)
- Black Hole: reduzido por `z._bhScale` (0.05 a 1.0)

#### **Deformação (Squash & Stretch)**
```javascript
var speedY = Math.abs(z.vy || 0);
var speedX = Math.abs(z.vx || 0);
var squashX = 1 + speedY * 0.04 - speedX * 0.02;  // Compressão horizontal ao cair
var squashY = 1 - speedY * 0.03 + speedX * 0.02;  // Expansão vertical ao cair
```
- Cria efeito de "massa mole" deformável
- Valor wobble adicional: `Math.sin(t + i * 1.7) * 0.04`

#### **Corpo (Jelly Body)**
Desenhado em 2 etapas com **ellipses**:
```javascript
ctx.beginPath();
// Topo: meia elipse suave
ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 0, Math.PI, 0);
// Fundo: mais largo (apoiado no chão)
ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3, 0, 0, Math.PI);
ctx.closePath();
```

#### **Preenchimento (Gradient)**
```javascript
var grad = ctx.createRadialGradient(-w * 0.15, -h * 0.25, 0, 0, 0, w * 0.6);
grad.addColorStop(0, 'rgba(R+80, G+80, B+80, 0.5)');    // Luz no topo
grad.addColorStop(0.5, 'rgba(R, G, B, 0.35)');          // Centro
grad.addColorStop(1, 'rgba(R-40, G-40, B-40, 0.25)');   // Sombra na borda
```
- Cores em `JELLY_COLORS` array: arrays `{r, g, b}`
- Gradiente radial para efeito 3D

#### **Cor do Slime**
- Normal: rotação de cores em `JELLY_COLORS` (cíclica por índice)
- Boss: `z.bossColor` personalizada (ex: `{r: 255, g: 60, b: 60}` para vermelho)

#### **Destaques (Highlights)**
```javascript
// Shine superior-esquerdo
ctx.ellipse(-w * 0.12, -h * 0.3, w * 0.18, h * 0.12, -0.3, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(255,255,255,0.5)';

// Pequeno highlight secundário
ctx.arc(-w * 0.05, -h * 0.45, w * 0.06, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(255,255,255,0.35)';
```

#### **Olhos (Eyes)**
```javascript
var eyeY = -h * 0.15;
var eyeSpacing = w * 0.15;
var eyeR = z.isSlimeBoss ? 5 : 3;

// Branco
ctx.fillStyle = 'rgba(255,255,255,0.8)';
ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);

// Pupila (segue direção de movimento)
var pupilOff = (z.dir || 1) * eyeR * 0.3;
ctx.fillStyle = 'rgba(0,0,0,0.7)';
ctx.arc(-eyeSpacing + pupilOff, eyeY, eyeR * 0.5, 0, Math.PI * 2);
```
- Pupilas se movem baseadas em `z.dir` (direção)

#### **Indicador de Boss**
```javascript
if (z.isSlimeBoss && z.state !== 'dead') {
    // Aura semi-transparente ao redor
    ctx.fillStyle = 'rgba(R, G, B, 0.08)';
    ctx.ellipse(0, -h * 0.1, w / 2 + 4, h * 0.5 + 4, 0, 0, Math.PI * 2);
    
    // Nome do boss + ícone
    ctx.font = 'bold 11px Arial';
    ctx.fillText(z.bossTier.icon + ' ' + z.bossTier.name, 0, -h / 2 - 16);
}
```

#### **Indicador de Sono**
```javascript
if (z.state === 'sleep') {
    ctx.globalAlpha = 0.5 + 0.3 * Math.sin((z.sleepZzz || 0) * 0.04);
    ctx.fillText('Z', 8, -h / 2 - 6);
    ctx.fillText('z', 18, -h / 2 - 14);
}
```

#### **Barra de HP**
```javascript
if (z.state !== 'dead' && z.hp < z.maxHp) {
    var barW = z.isSlimeBoss ? 80 : 35;
    var barH = z.isSlimeBoss ? 6 : 4;
    ctx.fillStyle = '#333';
    ctx.fillRect(-barW / 2, -h / 2 - 10, barW, barH);
    // Preenchimento da vida
    ctx.fillStyle = 'rgba(R, G, B, 0.9)';
    ctx.fillRect(-barW / 2, -h / 2 - 10, barW * (z.hp / z.maxHp), barH);
}
```

#### **Barra de Escudo (Shield Bar)**
```javascript
if (z.hasShield && z.shieldMax > 0) {
    var sBarY = -h / 2 - 18;
    ctx.fillStyle = '#222';
    ctx.fillRect(-barW / 2, sBarY, barW, 3);
    ctx.fillStyle = '#00ddff';
    ctx.fillRect(-barW / 2, sBarY, barW * (z.shieldHp / z.shieldMax), 3);
}
```

#### **Efeitos Visuais de Estado**
```javascript
if (z.state === 'hurt' && z.hurtTimer % 4 < 2) 
    ctx.globalAlpha = 0.6;  // Pisca quando ferido

if (z.state === 'dead') 
    ctx.globalAlpha = Math.max(0, 1 - z.deadTimer / 120);  // Desaparece ao morrer
```

---

## 2. `drawBubbles()` - Bolhas/Morcegos
**Localização:** Linhas 7201-7600

### Estrutura da Função
```javascript
function drawBubbles() {
    // Itera por bubbles visíveis
    for (var i = 0; i < bubbles.length; i++) {
        var b = bubbles[i];
        if (b.y < viewTop || b.y > viewBot) continue;
        if (++_batDrawn > MAX_BUBBLES_VISIBLE) break;  // Limite: 15
```

### Características de Renderização

#### **Tamanho e Escala**
```javascript
var r = BUBBLE_SIZE * 0.45;  // Raio base (~54 pixels)
if (b.isQueen) r *= QUEEN_SCALE;        // 3.0x para Rainhas
else if (b.isMother) r *= MOTHER_SCALE;  // 3.0x para Mães
if (b._bhScale !== undefined) r *= Math.max(0.05, b._bhScale);  // Black Hole
```

#### **Corpo Principal (Main Bubble Body)**
```javascript
var wobble = Math.sin(t + i * 2.3) * r * 0.06;
ctx.beginPath();
ctx.arc(0, wobble, r, 0, Math.PI * 2);  // Círculo simples
ctx.fillStyle = bc.fill;  // ex: 'rgba(100,180,255,0.25)'
ctx.fill();
ctx.strokeStyle = bc.stroke;
ctx.lineWidth = b.isMother ? 2.5 : 1.5;
ctx.stroke();
```

#### **Cores por Zona (BUBBLE_COLORS)**
```javascript
// Array cíclico de 3 temas de cores:
var BUBBLE_COLORS = [
    { fill: 'rgba(100,180,255,0.25)', stroke: 'rgba(150,210,255,0.6)', 
      highlight: 'rgba(255,255,255,0.7)' },  // Azul (Bat)
    { fill: 'rgba(255,150,200,0.25)', stroke: 'rgba(255,180,220,0.6)',
      highlight: 'rgba(255,255,255,0.7)' },  // Rosa (Vesp)
    { fill: 'rgba(150,255,150,0.25)', stroke: 'rgba(180,255,180,0.6)',
      highlight: 'rgba(255,255,255,0.7)' }   // Verde (Marimbondo)
];
```

#### **Destaques (Highlights)**
```javascript
// Grande shine superior-esquerdo
ctx.arc(-r * 0.25, -r * 0.3 + wobble, r * 0.3, 0, Math.PI * 2);
ctx.fillStyle = bc.highlight;
ctx.globalAlpha = (ctx.globalAlpha || 1) * 0.5;
ctx.fill();

// Pequeno highlight adicional
ctx.arc(-r * 0.1, -r * 0.5 + wobble, r * 0.12, 0, Math.PI * 2);
ctx.fillStyle = '#fff';
ctx.globalAlpha = 0.4;
ctx.fill();
```

#### **Indicador de Mãe/Rainha (Mother/Queen Indicator)**
```javascript
if (b.isMother && b.state !== 'dead') {
    var mPulse = 0.3 + Math.sin(t * 2 + i) * 0.2;
    var mGrad = ctx.createRadialGradient(0, wobble, 0, 0, wobble, r);
    
    if (b.isQueen) {
        mGrad.addColorStop(0, 'rgba(255,215,0,' + mPulse + ')');  // Ouro
        mGrad.addColorStop(1, 'rgba(255,215,0,0)');
    } else {
        mGrad.addColorStop(0, 'rgba(255,100,200,' + mPulse + ')');  // Rosa
        mGrad.addColorStop(1, 'rgba(255,100,200,0)');
    }
    ctx.fillStyle = mGrad;
    ctx.arc(0, wobble, r, 0, Math.PI * 2);
    ctx.fill();
}
```
- Efeito de **pulsação** suave
- Cores diferentes: ouro (Rainha) vs rosa (Mãe)

#### **Barra de HP**
```javascript
if (b.state !== 'dead' && b.hp < b.maxHp) {
    var barW = b.isQueen ? 70 : (b.isMother ? 45 : 22);
    var barH = b.isQueen ? 6 : (b.isMother ? 4 : 3);
    ctx.fillStyle = '#333';
    ctx.fillRect(-barW / 2, -r - 8, barW, barH);
    
    // Preenchimento colorido
    ctx.fillStyle = b.isQueen ? '#ffdd00' : (b.isMother ? '#ff88cc' : '#88ccff');
    ctx.fillRect(-barW / 2, -r - 8, barW * (b.hp / b.maxHp), barH);
}
```

#### **Efeitos de Estado**
```javascript
if (b.state === 'hurt' && b.hurtTimer % 3 < 2) 
    ctx.globalAlpha = 0.5;  // Pisca quando ferido

if (b.state === 'dead') {
    ctx.globalAlpha = Math.max(0, 1 - b.deadTimer / 90);
    r *= Math.max(0.1, 1 - b.deadTimer / 90);  // Encolhe ("pop")
}
```

---

## 3. `drawSpiders()` - Aranhas
**Localização:** Linhas 6676-7200

### Estrutura da Função
```javascript
function drawSpiders() {
    var _spiderDrawn = 0;
    for (var i = 0; i < spiders.length; i++) {
        var s = spiders[i];
        if (s.y < viewTop || s.y > viewBot) continue;
        if (++_spiderDrawn > MAX_SPIDERS_VISIBLE) break;  // Limite: 8
```

### Características de Renderização

#### **Tamanho e Escala**
```javascript
var baseW = SPIDER_SIZE * 0.5;      // ~54 pixels (metade da altura)
var baseH = SPIDER_SIZE * 0.45;     // ~49 pixels
if (s.isMother) { baseW *= SPIDER_MOTHER_SCALE; baseH *= SPIDER_MOTHER_SCALE; }
if (s._bhScale !== undefined) {
    var ssc = Math.max(0.05, s._bhScale);
    baseW *= ssc;
    baseH *= ssc;
}
```

#### **Deformação (Squash & Stretch)**
```javascript
var speedY = Math.abs(s.vy || 0);
var speedX = Math.abs(s.vx || 0);
var squashX = 1 + speedY * 0.05 - speedX * 0.02;
var squashY = 1 - speedY * 0.04 + speedX * 0.02;

// Wobble animado
var wobble = Math.sin(t + i * 2.1) * 0.03;
squashX += wobble;
squashY -= wobble;
```

#### **Corpo (Dark Slime Body)**
Desenho em 2 etapas com **ellipses**:
```javascript
ctx.beginPath();
ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 0, Math.PI, 0);       // Topo
ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3, 0, 0, Math.PI);  // Fundo
ctx.closePath();
```

#### **Preenchimento (Gradiente Nervoso)**
```javascript
var grad = ctx.createRadialGradient(-w * 0.15, -h * 0.25, 0, 0, 0, w * 0.6);
grad.addColorStop(0, 'rgba(80,80,90,0.5)');      // Cinzento claro
grad.addColorStop(0.5, 'rgba(30,30,40,0.4)');   // Cinzento escuro
grad.addColorStop(1, 'rgba(10,10,15,0.3)');     // Quase preto
ctx.fillStyle = grad;
ctx.fill();
ctx.strokeStyle = 'rgba(60,60,70,0.5)';
ctx.lineWidth = s.isMother ? 2 : 1.2;
ctx.stroke();
```
- Cores muito escuras (cinzento/preto)
- Outline para separação visual

#### **Destaques (Highlights)**
```javascript
// Shine superior-esquerdo
ctx.ellipse(-w * 0.12, -h * 0.3, w * 0.16, h * 0.1, -0.3, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(255,255,255,0.35)';
ctx.fill();

// Pequeno highlight
ctx.arc(-w * 0.05, -h * 0.45, w * 0.05, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(255,255,255,0.25)';
ctx.fill();
```

#### **Olhos - VERMELHOS (Dark Slime Eyes)**
```javascript
var eyeY = -h * 0.15;
var eyeSpacing = w * 0.14;
var eyeR = s.isMother ? 4 : 2.5;

// Vermelvos (diferente dos slimes normais que têm branco)
ctx.fillStyle = 'rgba(255,100,100,0.8)';  // VERMELHO
ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
ctx.arc(eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);

// Pupilas pretas
var pupilOff = (s.dir || 1) * eyeR * 0.3;
ctx.fillStyle = 'rgba(0,0,0,0.8)';
ctx.arc(-eyeSpacing + pupilOff, eyeY, eyeR * 0.45, 0, Math.PI * 2);
ctx.arc(eyeSpacing + pupilOff, eyeY, eyeR * 0.45, 0, Math.PI * 2);
```
- **Característica distintiva: olhos VERMELHOS** (vs brancos dos slimes)

#### **Barra de HP**
```javascript
if (s.state !== 'dead' && s.hp < s.maxHp) {
    ctx.globalAlpha = 0.7;
    var barW = s.isMother ? 40 : 20;
    var barH = s.isMother ? 4 : 3;
    ctx.fillStyle = '#333';
    ctx.fillRect(-barW / 2, -h / 2 - 8, barW, barH);
    ctx.fillStyle = 'rgba(150,50,50,0.9)';  // Avermelhado
    ctx.fillRect(-barW / 2, -h / 2 - 8, barW * (s.hp / s.maxHp), barH);
}
```

#### **Efeitos de Estado**
```javascript
if (s.state === 'hurt' && s.hurtTimer % 4 < 2) 
    ctx.globalAlpha = 0.6;  // Pisca ao ser ferido

if (s.state === 'dead') 
    ctx.globalAlpha = Math.max(0, 1 - s.deadTimer / 100);  // Desaparece
```

---

## Resumo Comparativo

| Aspecto | Slimes | Bubbles | Spiders |
|---------|--------|---------|---------|
| **Forma Base** | Ellipse (dupla - topo/fundo) | Círculo simples | Ellipse (dupla) |
| **Cor** | Múltiplas cores vibrantes (JELLY_COLORS) | 3 temas por zona | Cinzento/Preto escuro |
| **Olhos** | Brancos com pupila preta | N/A (sem olhos) | VERMELHOS com pupila preta |
| **Gradiente** | Radial com 3 stops (luz→normal→sombra) | Simples fill + stroke | Radial com 3 stops (cinza) |
| **Barra HP** | Colorida (jelly color) | Amarela/Rosa/Azul | Vermelha |
| **Limite Renderização** | 8 simultâneos | 15 simultâneos | 8 simultâneos |
| **Tamanho Boss** | 3.0x (SLIME_BOSS_SCALE) | 3.0x (QUEEN_SCALE) | Varia (SPIDER_MOTHER_SCALE) |
| **Efeito especial** | Indicador nome boss | Pulsação de Mãe/Rainha | Nenhum especial |
| **Sprites PNG** | ❌ Desenho programático | ❌ Desenho programático | ❌ Desenho programático |

---

## Loops de Iteração

### Localização das Chamadas
```javascript
// Dentro de draw() - função principal de renderização:
drawSpiders();      // linha ~5941
drawSlimes();       // linha ~5942
drawBubbles();      // linha ~5972
```

### Culling (Otimização)
Todas as 3 funções usam:
```javascript
var viewTop = camY - TILE * 2;
var viewBot = camY + canvas.height + TILE * 2;

// Pula inimigos fora da viewport
if (z.y < viewTop || z.y > viewBot) continue;

// Limite de renderização para performance
if (++_drawn > MAX_VISIBLE) break;
```

---

## Técnicas de Renderização

### 1. **Gradientes Radiais** (Efeito 3D)
```javascript
ctx.createRadialGradient(x1, y1, r1, x2, y2, r2)
```
- Cria profundidade visual
- Luz principal no topo-esquerdo

### 2. **Deformação Dinâmica (Squash & Stretch)**
```javascript
var squash = 1 + velocidade * fator;
// Aplicado ao width/height para efeito "físico"
```

### 3. **Wobble Sinusoidal**
```javascript
var wobble = Math.sin(t + i * fator) * amplitude;
// Movimento oscilatório contínuo suave
```

### 4. **Piscagem (Blink) para Feedback**
```javascript
if (state === 'hurt' && timer % N < N/2) 
    globalAlpha = 0.5;
// Renderiza transparente a cada N frames
```

### 5. **Transição de Morte**
```javascript
// Desaparece gradualmente
globalAlpha = Math.max(0, 1 - deadTimer / duration);
```

---

## Constantes Importantes

```javascript
var SLIME_SIZE = TILE * 1.05;        // ~113px
var SPIDER_SIZE = TILE * 0.95;       // ~103px
var BUBBLE_SIZE = TILE * 1.05;       // ~113px
var TILE = 108;

var MAX_SLIMES_VISIBLE = 8;
var MAX_SPIDERS_VISIBLE = 8;
var MAX_BUBBLES_VISIBLE = 15;

var SLIME_BOSS_SCALE = 2.0;          // Bosses 2x normal
var SPIDER_MOTHER_SCALE = 2.0;
var MOTHER_SCALE = 3.0;              // Mães burbujas 3x
var QUEEN_SCALE = 3.0;               // Rainhas 3x
```

---

## Conclusão

Todos os inimigos são **renderizados programaticamente** sem sprites PNG:
- ✅ Formas geométricas (círculos, ellipses)
- ✅ Gradientes e sombras
- ✅ Animação por deformação (não quadros-chave)
- ✅ Dinâmica de estado (hurt, dead, sleep)
- ✅ Otimizações de culling e limite de renderização
