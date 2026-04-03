# Resumo Técnico: Funções de Desenho de Inimigos

## 📊 Comparação Rápida

```
SLIMES (Zumbis/Geleia)
├─ Forma: Ellipse duplo (topo esférico + fundo achatado)
├─ Olhos: BRANCOS com pupila preta
├─ Cores: Múltiplos (JELLY_COLORS) - cíclico por índice
├─ Gradiente: Radial 3-stops (claro → normal → escuro)
├─ HP Bar: Colorida (cor do slime)
├─ Boss: Aura + nome + ícone
├─ Limite: 8 simultâneos
└─ Tamanho: 113px base, 3.0x boss

BUBBLES (Morcegos/Bolhas)
├─ Forma: Círculo simples (ctx.arc)
├─ Olhos: Nenhum (sem olhos)
├─ Cores: 3 temas (azul, rosa, verde) por zona
├─ Gradiente: Fill + Stroke (sem radial)
├─ HP Bar: Amarela/Rosa/Azul conforme tipo
├─ Mother/Queen: Pulsação ativa
├─ Limite: 15 simultâneos
└─ Tamanho: 54px base, 3.0x rainha/mãe

SPIDERS (Aranhas)
├─ Forma: Ellipse duplo (similar ao slime)
├─ Olhos: VERMELHOS com pupila preta ⭐ DISTINTIVO
├─ Cores: Cinzento/Preto (cores sombrias)
├─ Gradiente: Radial 3-stops (muito escuro)
├─ HP Bar: Vermelha
├─ Boss: Sem indicador especial
├─ Limite: 8 simultâneos
└─ Tamanho: 103px base, 2.0x mãe
```

---

## 📍 Localização no Código

```javascript
// ARQUIVO: index.html

// FUNÇÃO PRINCIPAL
function draw() {
    // ... renderização do mapa ...
    
    drawSpiders();    // linha ~5941
    drawSlimes();     // linha ~5942
    drawBubbles();    // linha ~5972
    
    // ... renderização de UI ...
}

// FUNÇÕES DE DESENHO INDIVIDUAIS
drawSpiders()  // linhas 6676-7200 (524 linhas)
drawSlimes()   // linhas 8436-8900+ (500+ linhas)
drawBubbles()  // linhas 7201-7600 (399 linhas)
```

---

## 🎨 Técnicas de Renderização

### 1. ELLIPSE (Corpo dos Slimes/Spiders)
```javascript
// Desenha uma forma de "gota" (topo redondo, fundo achatado)
ctx.beginPath();
// Topo: meia elipse suave (arco superior 180°)
ctx.ellipse(0, offsetY, width/2, height/2, rotação, startAngle=π, endAngle=0);
// Fundo: mais largo (arco inferior 180°)
ctx.ellipse(0, offsetY, width/2*1.1, height/3, rotação, startAngle=0, endAngle=π);
ctx.closePath();
ctx.fill();
ctx.stroke();
```

### 2. CÍRCULO (Corpo das Bubbles)
```javascript
// Simples e eficaz
ctx.beginPath();
ctx.arc(0, wobbleY, raio, 0, Math.PI * 2);  // Círculo perfeito
ctx.fillStyle = 'rgba(...)';
ctx.fill();
ctx.strokeStyle = 'rgba(...)';
ctx.stroke();
```

### 3. GRADIENTE RADIAL (Iluminação 3D)
```javascript
// Cria efeito de esfera/profundidade
var grad = ctx.createRadialGradient(
    -w * 0.15,      // x1: ponto de luz (canto superior-esquerdo)
    -h * 0.25,      // y1
    0,              // r1: raio interno (ponto)
    0,              // x2: centro
    0,              // y2
    w * 0.6         // r2: raio externo (borda)
);

// 3 cores principais
grad.addColorStop(0, 'rgba(255, 255, 255, 0.5)');   // Luz
grad.addColorStop(0.5, 'rgba(128, 128, 128, 0.35)');  // Normal
grad.addColorStop(1, 'rgba(0, 0, 0, 0.25)');        // Sombra

ctx.fillStyle = grad;
ctx.fill();
```

### 4. SQUASH & STRETCH (Deformação por Velocidade)
```javascript
// Cria efeito "físico" de massa mole
var speedY = Math.abs(velocidadeY);  // Queda = compressão
var speedX = Math.abs(velocidadeX);  // Movimento lateral = expansão

// Fórmula básica
var squashX = 1 + (speedY * 0.04) - (speedX * 0.02);
var squashY = 1 - (speedY * 0.03) + (speedX * 0.02);

// Limitar range (0.7 a 1.3)
squashX = Math.max(0.7, Math.min(1.3, squashX));
squashY = Math.max(0.7, Math.min(1.3, squashY));

// Aplicar ao desenho
var w = baseWidth * squashX;
var h = baseHeight * squashY;
ctx.ellipse(0, 0, w/2, h/2, ...);
```

### 5. WOBBLE (Oscilação Contínua)
```javascript
// Movimento sinusoidal leve e contínuo
var t = Date.now() * 0.004;  // Tempo em segundos, escalado
var wobble = Math.sin(t + i * 2.1) * amplitude;

// Aplicado ao Y para "flutuar"
ctx.translate(x, y + wobble);
```

### 6. OLHOS COM PUPILA DIRECIONADA
```javascript
// Brancos (Slimes)
ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
ctx.arc(-spacing, eyeY, eyeRadius, 0, Math.PI * 2);
ctx.fill();

// Pupila segue direção
var pupilOffsetX = (direction > 0 ? 1 : -1) * eyeRadius * 0.3;
ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
ctx.arc(-spacing + pupilOffsetX, eyeY, eyeRadius * 0.5, 0, Math.PI * 2);
ctx.fill();

// Resultado: olhos piscam na direção do movimento
```

### 7. BARRA DE VIDA (HP Bar)
```javascript
// Background (cinzento)
ctx.fillStyle = '#333';
ctx.fillRect(-barWidth/2, barY, barWidth, barHeight);

// Preenchimento (proporcional à vida)
ctx.fillStyle = 'rgba(R, G, B, 0.9)';
ctx.fillRect(-barWidth/2, barY, barWidth * (hp / maxHp), barHeight);

// Nota: Posição acima da cabeça (barY = -altura/2 - 10)
```

### 8. PISCAGEM (Feedback de Ferimento)
```javascript
// Efeito de dano/invisibilidade alternada
if (state === 'hurt' && hurtTimer % 4 < 2) {
    ctx.globalAlpha = 0.6;  // Renderiza a 60% de opacidade
}
// A cada 4 frames, fica 2 frames visível, 2 invisível
```

### 9. DESAPARECIMENTO (Morte)
```javascript
// Transição suave de desaparecimento
ctx.globalAlpha = Math.max(0, 1 - deadTimer / maxDeadDuration);

// Também diminui (opcional, para "pop" effect)
var radius = baseRadius * Math.max(0.1, 1 - deadTimer / duration);
```

---

## 💾 Arrays de Dados

### JELLY_COLORS (Cores de Slimes)
```javascript
var JELLY_COLORS = [
    { r: 100, g: 180, b: 255 },  // Azul
    { r: 255, g: 100, b: 100 },  // Vermelho
    { r: 100, g: 255, b: 100 },  // Verde
    { r: 255, g: 200, b: 100 },  // Laranja
    // ... mais cores ...
];
// Usado: JELLY_COLORS[i % JELLY_COLORS.length]
```

### BUBBLE_COLORS (Temas por Zona)
```javascript
var BUBBLE_COLORS = [
    {
        fill: 'rgba(100, 180, 255, 0.25)',    // Azul claro
        stroke: 'rgba(150, 210, 255, 0.6)',   // Azul más escuro
        highlight: 'rgba(255, 255, 255, 0.7)' // Branco shine
    },
    {
        fill: 'rgba(255, 150, 200, 0.25)',    // Rosa claro
        stroke: 'rgba(255, 180, 220, 0.6)',   // Rosa mais escuro
        highlight: 'rgba(255, 255, 255, 0.7)'
    },
    {
        fill: 'rgba(150, 255, 150, 0.25)',    // Verde claro
        stroke: 'rgba(180, 255, 180, 0.6)',   // Verde mais escuro
        highlight: 'rgba(255, 255, 255, 0.7)'
    }
];
// Usado: BUBBLE_COLORS[zone % BUBBLE_COLORS.length]
```

---

## 🔄 Loop de Renderização

```javascript
function drawSpiders() {
    var viewTop = camY - TILE * 2;           // Culling: acima
    var viewBot = camY + canvas.height + TILE * 2;  // Culling: abaixo
    var t = Date.now() * 0.004;              // Tempo animação
    var _spiderDrawn = 0;
    
    for (var i = 0; i < spiders.length; i++) {
        var s = spiders[i];
        
        // CULLING: Pula se fora da viewport
        if (s.y < viewTop || s.y > viewBot) continue;
        
        // LIMITE DE RENDERIZAÇÃO: Máximo 8 visíveis
        if (++_spiderDrawn > MAX_SPIDERS_VISIBLE) break;
        
        // === CÁLCULOS DE TAMANHO ===
        var baseW = SPIDER_SIZE * 0.5;
        var baseH = SPIDER_SIZE * 0.45;
        
        // === DEFORMAÇÃO ===
        var speedY = Math.abs(s.vy || 0);
        var speedX = Math.abs(s.vx || 0);
        var squashX = 1 + speedY * 0.05 - speedX * 0.02;
        // ... cálculos ...
        
        // === SETUP CANVAS ===
        ctx.save();
        ctx.translate(s.x, s.y + SPIDER_SIZE * 0.3);
        
        // === RENDERIZAÇÃO ===
        // 1. Corpo (ellipse)
        ctx.beginPath();
        ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 0, Math.PI, 0);
        ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3, 0, 0, Math.PI);
        ctx.closePath();
        ctx.fillStyle = gradiente;
        ctx.fill();
        ctx.stroke();
        
        // 2. Destaques
        // ... shine ...
        
        // 3. Olhos VERMELHOS ⭐
        // ... desenho dos olhos ...
        
        // 4. HP Bar
        // ... barra de vida ...
        
        // === CLEANUP ===
        ctx.globalAlpha = 1;
        ctx.restore();
    }
}
```

---

## 🎯 Estados Visuais

| Estado | Aparência | Duração |
|--------|-----------|---------|
| `idle` | Normal, opacidade 100% | Indefinida |
| `hurt` | Pisca 50% opacidade | ~12 frames |
| `sleep` | Texto "Z" flutuando | Até despertar |
| `dead` | Desaparece gradual | ~120 frames |
| `black_hole` | Encolhe (scale 0.05-1.0) + rotação | Até liberação |

---

## ⚡ Otimizações

### 1. **Viewport Culling**
```javascript
if (y < viewTop || y > viewBot) continue;  // Pula renderização
```
→ Economiza processamento de inimigos fora da tela

### 2. **Limite de Renderização**
```javascript
if (++_drawn > MAX_VISIBLE) break;
```
→ Garante FPS mínimo mesmo com muitos inimigos

### 3. **Context State Save/Restore**
```javascript
ctx.save();   // Salva transformações (translate, rotate, etc)
// ... desenha ...
ctx.restore();  // Restaura estado anterior
```
→ Evita interferência entre inimigos

### 4. **Condicionais de Renderização**
```javascript
if (z.state !== 'dead' && z.hp < z.maxHp) {
    // Renderiza barra de HP apenas se necessário
}
```
→ Pula elementos desnecessários

---

## 📝 Dicas de Desenvolvimento

1. **Todos usam DESENHO PROGRAMÁTICO** (sem sprites PNG para o corpo)
2. **Gradientes radiais criam efeito 3D** sem texturas
3. **Deformação por velocidade** torna animação mais viva
4. **Olhos diferentes** (brancos vs vermelhos) ajudam na identificação rápida
5. **HP bars coloridas** fornecem feedback visual imediato
6. **Culling + limite = performance** mesmo em movimento rápido
7. **Estados visuais (hurt, dead)** comunicam eventos ao jogador

---

## 🔗 Referências de Constantes

```javascript
TILE = 108;                    // Tamanho base de tile
SLIME_SIZE = TILE * 1.05;      // 113px
SPIDER_SIZE = TILE * 0.95;     // 103px
BUBBLE_SIZE = TILE * 1.05;     // 113px

MAX_SLIMES_VISIBLE = 8;        // Limite simultâneo
MAX_SPIDERS_VISIBLE = 8;
MAX_BUBBLES_VISIBLE = 15;

SLIME_BOSS_SCALE = 2.0;        // 2x normal
SPIDER_MOTHER_SCALE = 2.0;
MOTHER_SCALE = 3.0;            // Mães 3x
QUEEN_SCALE = 3.0;             // Rainhas 3x
```

---

**Gerado:** 2025-04-02
**Fonte:** index.html (linhas 6676-8900+)
**Tipo:** Análise Técnica de Renderização
