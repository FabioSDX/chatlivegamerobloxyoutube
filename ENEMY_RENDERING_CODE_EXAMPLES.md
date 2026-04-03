# Exemplos de Código: Funções de Desenho de Inimigos

## 1️⃣ drawSlimes() - Exemplo Completo Simplificado

```javascript
function drawSlimes() {
    var viewTop = camY - TILE * 2;
    var viewBot = camY + canvas.height + TILE * 2;
    var t = Date.now() * 0.004;  // Tempo para animação
    var _zombieDrawn = 0;
    
    for (var i = 0; i < slimes.length; i++) {
        var z = slimes[i];
        
        // === CULLING ===
        if (z.y < viewTop || z.y > viewBot) continue;
        if (++_zombieDrawn > MAX_SLIMES_VISIBLE) break;  // Max 8
        
        // === TAMANHO BASE ===
        var baseW = SLIME_SIZE * 0.9;   // ~102px
        var baseH = SLIME_SIZE * 0.8;   // ~90px
        
        // Bosses são maiores
        if (z.isSlimeBoss) {
            var _zbs = z.bossScale || SLIME_BOSS_SCALE;  // 2.0x
            baseW *= _zbs;
            baseH *= _zbs;
        }
        
        // === SQUASH & STRETCH ===
        var speedY = Math.abs(z.vy || 0);
        var speedX = Math.abs(z.vx || 0);
        var squashX = 1 + speedY * 0.04 - speedX * 0.02;
        var squashY = 1 - speedY * 0.03 + speedX * 0.02;
        squashX = Math.max(0.7, Math.min(1.3, squashX));
        squashY = Math.max(0.7, Math.min(1.3, squashY));
        
        // === WOBBLE ANIMADO ===
        var wobble = Math.sin(t + i * 1.7) * 0.04;
        squashX += wobble;
        squashY -= wobble;
        
        var w = baseW * squashX;
        var h = baseH * squashY;
        
        // === SELECIONAR COR ===
        var jc = JELLY_COLORS[i % JELLY_COLORS.length];
        if (z.isSlimeBoss) jc = z.bossColor || { r: 255, g: 60, b: 60 };
        
        // === SETUP CANVAS ===
        ctx.save();
        var dx = z.x, dy = z.y + SLIME_SIZE * 0.3;
        ctx.translate(dx, dy);
        
        // === APLICAR EFEITOS DE ESTADO ===
        if (z.state === 'hurt' && z.hurtTimer % 4 < 2) 
            ctx.globalAlpha = 0.6;  // Pisca quando ferido
            
        if (z.state === 'dead') 
            ctx.globalAlpha = Math.max(0, 1 - z.deadTimer / 120);  // Desaparece
        
        // === DESENHAR CORPO (Ellipse Duplo) ===
        ctx.beginPath();
        // Topo: meia elipse suave
        ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 0, Math.PI, 0);
        // Fundo: meia elipse mais larga (apoio no chão)
        ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3, 0, 0, Math.PI);
        ctx.closePath();
        
        // === PREENCHIMENTO COM GRADIENTE ===
        var grad = ctx.createRadialGradient(
            -w * 0.15, -h * 0.25, 0,    // Ponto de luz (superior-esquerdo)
            0, 0, w * 0.6                // Centro até raio externo
        );
        grad.addColorStop(0, 'rgba(' + Math.min(255, jc.r + 80) + ',' + 
                               Math.min(255, jc.g + 80) + ',' + 
                               Math.min(255, jc.b + 80) + ',0.5)');     // Luz
        grad.addColorStop(0.5, 'rgba(' + jc.r + ',' + jc.g + ',' + jc.b + ',0.35)');  // Normal
        grad.addColorStop(1, 'rgba(' + Math.max(0, jc.r - 40) + ',' + 
                              Math.max(0, jc.g - 40) + ',' + 
                              Math.max(0, jc.b - 40) + ',0.25)');      // Sombra
        ctx.fillStyle = grad;
        ctx.fill();
        
        // === OUTLINE ===
        ctx.strokeStyle = 'rgba(' + jc.r + ',' + jc.g + ',' + jc.b + ',0.5)';
        ctx.lineWidth = z.isSlimeBoss ? 3 : 1.5;
        ctx.stroke();
        
        // === DESTAQUES (HIGHLIGHTS) ===
        // Shine grande superior-esquerdo
        ctx.beginPath();
        ctx.ellipse(-w * 0.12, -h * 0.3, w * 0.18, h * 0.12, -0.3, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255,255,255,0.5)';
        ctx.fill();
        
        // Shine pequeno superior
        ctx.beginPath();
        ctx.arc(-w * 0.05, -h * 0.45, w * 0.06, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255,255,255,0.35)';
        ctx.fill();
        
        // === OLHOS ===
        var eyeY = -h * 0.15;
        var eyeSpacing = w * 0.15;
        var eyeR = z.isSlimeBoss ? 5 : 3;
        
        // Brancos dos olhos
        ctx.fillStyle = 'rgba(255,255,255,0.8)';
        ctx.beginPath();
        ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
        ctx.fill();
        
        // Pupila (segue direção do movimento)
        var pupilOff = (z.dir || 1) * eyeR * 0.3;  // Positivo ou negativo conforme direção
        ctx.fillStyle = 'rgba(0,0,0,0.7)';
        ctx.beginPath();
        ctx.arc(-eyeSpacing + pupilOff, eyeY, eyeR * 0.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(eyeSpacing + pupilOff, eyeY, eyeR * 0.5, 0, Math.PI * 2);
        ctx.fill();
        
        // === INDICADOR DE BOSS ===
        if (z.isSlimeBoss && z.state !== 'dead') {
            var _bc = z.bossColor || { r: 255, g: 60, b: 60 };
            
            // Aura ao redor do corpo
            ctx.fillStyle = 'rgba(' + _bc.r + ',' + _bc.g + ',' + _bc.b + ',0.08)';
            ctx.beginPath();
            ctx.ellipse(0, -h * 0.1, w / 2 + 4, h * 0.5 + 4, 0, 0, Math.PI * 2);
            ctx.fill();
            
            // Nome do boss
            if (z.bossTier) {
                ctx.globalAlpha = 0.9;
                ctx.font = 'bold 11px Arial';
                ctx.fillStyle = 'rgb(' + _bc.r + ',' + _bc.g + ',' + _bc.b + ')';
                ctx.textAlign = 'center';
                ctx.fillText(z.bossTier.icon + ' ' + z.bossTier.name, 0, -h / 2 - 16);
            }
        }
        
        // === INDICADOR DE SONO ===
        if (z.state === 'sleep') {
            ctx.globalAlpha = 0.5 + 0.3 * Math.sin((z.sleepZzz || 0) * 0.04);
            ctx.font = '14px monospace';
            ctx.fillStyle = '#aaddff';
            var zzOff = Math.sin((z.sleepZzz || 0) * 0.03) * 6;
            ctx.fillText('Z', 8, -h / 2 - 6 + zzOff);
            ctx.font = '11px monospace';
            ctx.fillText('z', 18, -h / 2 - 14 + zzOff * 0.7);
        }
        
        // === BARRA DE HP ===
        if (z.state !== 'dead' && z.hp < z.maxHp) {
            ctx.globalAlpha = 0.8;
            var barW = z.isSlimeBoss ? 80 : 35;
            var barH = z.isSlimeBoss ? 6 : 4;
            
            // Background (cinzento)
            ctx.fillStyle = '#333';
            ctx.fillRect(-barW / 2, -h / 2 - 10, barW, barH);
            
            // Preenchimento (proporcional à vida)
            ctx.fillStyle = 'rgba(' + jc.r + ',' + jc.g + ',' + jc.b + ',0.9)';
            ctx.fillRect(-barW / 2, -h / 2 - 10, barW * (z.hp / z.maxHp), barH);
            
            // === BARRA DE ESCUDO (se aplicável) ===
            if (z.hasShield && z.shieldMax > 0) {
                var sBarY = -h / 2 - 18;
                ctx.fillStyle = '#222';
                ctx.fillRect(-barW / 2, sBarY, barW, 3);
                ctx.fillStyle = '#00ddff';
                ctx.fillRect(-barW / 2, sBarY, barW * (z.shieldHp / z.shieldMax), 3);
            }
        }
        
        // === CLEANUP ===
        ctx.globalAlpha = 1;
        ctx.restore();
    }
}
```

---

## 2️⃣ drawBubbles() - Exemplo Completo Simplificado

```javascript
function drawBubbles() {
    var viewTop = camY - TILE * 2;
    var viewBot = camY + canvas.height + TILE * 2;
    var t = Date.now() * 0.003;  // Tempo para animação (mais lento que slimes)
    var _batDrawn = 0;
    
    for (var i = 0; i < bubbles.length; i++) {
        var b = bubbles[i];
        
        // === CULLING ===
        if (b.y < viewTop || b.y > viewBot) continue;
        if (++_batDrawn > MAX_BUBBLES_VISIBLE) break;  // Max 15
        
        // === TAMANHO ===
        var r = BUBBLE_SIZE * 0.45;  // ~54px de raio
        if (b.isQueen) r *= QUEEN_SCALE;           // 3.0x
        else if (b.isMother) r *= MOTHER_SCALE;   // 3.0x
        
        // Black hole shrink
        if (b._bhScale !== undefined && b._bhScale < 1) {
            r *= Math.max(0.05, b._bhScale);  // 0.05 a 1.0
        }
        
        // === APLICAR EFEITOS DE ESTADO ===
        if (b.state === 'hurt' && b.hurtTimer % 3 < 2) 
            ctx.globalAlpha = 0.5;  // Pisca quando ferido
            
        if (b.state === 'dead') {
            ctx.globalAlpha = Math.max(0, 1 - b.deadTimer / 90);  // Desaparece
            r *= Math.max(0.1, 1 - b.deadTimer / 90);  // Encolhe ("pop")
        }
        
        // === SELECIONAR CORES CONFORME ZONA ===
        var bc = BUBBLE_COLORS[b.zone % BUBBLE_COLORS.length];
        // bc = { fill, stroke, highlight }
        
        // === WOBBLE (OSCILAÇÃO LEVE) ===
        var wobble = Math.sin(t + i * 2.3) * r * 0.06;
        
        // === SETUP CANVAS ===
        ctx.save();
        ctx.translate(b.x, b.y);
        
        // Black hole spin
        if (b._bhScale !== undefined && b._bhScale < 1) {
            ctx.rotate(b._bhSpin || 0);
        }
        
        // === DESENHAR CORPO (CÍRCULO) ===
        ctx.beginPath();
        ctx.arc(0, wobble, r, 0, Math.PI * 2);  // Círculo simples
        ctx.fillStyle = bc.fill;                 // ex: 'rgba(100,180,255,0.25)'
        ctx.fill();
        
        ctx.strokeStyle = bc.stroke;             // ex: 'rgba(150,210,255,0.6)'
        ctx.lineWidth = b.isMother ? 2.5 : 1.5;
        ctx.stroke();
        
        // === DESTAQUES (HIGHLIGHTS) ===
        // Grande shine superior-esquerdo
        ctx.beginPath();
        ctx.arc(-r * 0.25, -r * 0.3 + wobble, r * 0.3, 0, Math.PI * 2);
        ctx.fillStyle = bc.highlight;
        ctx.globalAlpha = (ctx.globalAlpha || 1) * 0.5;
        ctx.fill();
        
        // Pequeno highlight adicional
        ctx.beginPath();
        ctx.arc(-r * 0.1, -r * 0.5 + wobble, r * 0.12, 0, Math.PI * 2);
        ctx.fillStyle = '#fff';
        ctx.globalAlpha = 0.4;
        ctx.fill();
        
        // === INDICADOR DE MÃE/RAINHA (PULSAÇÃO) ===
        if (b.isMother && b.state !== 'dead') {
            // Gera pulsação (onda)
            var mPulse = 0.3 + Math.sin(t * 2 + i) * 0.2;
            var mGrad = ctx.createRadialGradient(0, wobble, 0, 0, wobble, r);
            
            if (b.isQueen) {
                // Cor ouro para rainha
                mGrad.addColorStop(0, 'rgba(255,215,0,' + mPulse + ')');
                mGrad.addColorStop(1, 'rgba(255,215,0,0)');
            } else {
                // Cor rosa para mãe
                mGrad.addColorStop(0, 'rgba(255,100,200,' + mPulse + ')');
                mGrad.addColorStop(1, 'rgba(255,100,200,0)');
            }
            
            ctx.fillStyle = mGrad;
            ctx.beginPath();
            ctx.arc(0, wobble, r, 0, Math.PI * 2);
            ctx.fill();
        }
        
        // === BARRA DE HP ===
        if (b.state !== 'dead' && b.hp < b.maxHp) {
            ctx.globalAlpha = 0.7;
            var barW = b.isQueen ? 70 : (b.isMother ? 45 : 22);
            var barH = b.isQueen ? 6 : (b.isMother ? 4 : 3);
            
            // Background
            ctx.fillStyle = '#333';
            ctx.fillRect(-barW / 2, -r - 8, barW, barH);
            
            // Preenchimento com cor específica do tipo
            ctx.fillStyle = b.isQueen ? '#ffdd00' :  // Rainha (amarelo)
                           (b.isMother ? '#ff88cc' : '#88ccff');  // Mãe (rosa) ou normal (azul)
            ctx.fillRect(-barW / 2, -r - 8, barW * (b.hp / b.maxHp), barH);
        }
        
        // === CLEANUP ===
        ctx.globalAlpha = 1;
        ctx.restore();
    }
}
```

---

## 3️⃣ drawSpiders() - Exemplo Completo Simplificado

```javascript
function drawSpiders() {
    var viewTop = camY - TILE * 2;
    var viewBot = camY + canvas.height + TILE * 2;
    var t = Date.now() * 0.004;  // Tempo para animação
    var _spiderDrawn = 0;
    
    for (var i = 0; i < spiders.length; i++) {
        var s = spiders[i];
        
        // === CULLING ===
        if (s.y < viewTop || s.y > viewBot) continue;
        if (++_spiderDrawn > MAX_SPIDERS_VISIBLE) break;  // Max 8
        
        // === TAMANHO BASE ===
        var baseW = SPIDER_SIZE * 0.5;   // ~54px
        var baseH = SPIDER_SIZE * 0.45;  // ~49px
        
        // Mães são maiores
        if (s.isMother) {
            baseW *= SPIDER_MOTHER_SCALE;  // 2.0x
            baseH *= SPIDER_MOTHER_SCALE;
        }
        
        // Black hole shrink
        if (s._bhScale !== undefined && s._bhScale < 1) {
            var ssc = Math.max(0.05, s._bhScale);
            baseW *= ssc;
            baseH *= ssc;
        }
        
        // === SQUASH & STRETCH ===
        var speedY = Math.abs(s.vy || 0);
        var speedX = Math.abs(s.vx || 0);
        var squashX = 1 + speedY * 0.05 - speedX * 0.02;
        var squashY = 1 - speedY * 0.04 + speedX * 0.02;
        squashX = Math.max(0.7, Math.min(1.3, squashX));
        squashY = Math.max(0.7, Math.min(1.3, squashY));
        
        // === WOBBLE ANIMADO ===
        var wobble = Math.sin(t + i * 2.1) * 0.03;
        squashX += wobble;
        squashY -= wobble;
        
        var w = baseW * squashX;
        var h = baseH * squashY;
        
        // === SETUP CANVAS ===
        ctx.save();
        ctx.translate(s.x, s.y + SPIDER_SIZE * 0.3);
        
        // Black hole spin
        if (s._bhScale !== undefined && s._bhScale < 1) {
            ctx.rotate(s._bhSpin || 0);
        }
        
        // === APLICAR EFEITOS DE ESTADO ===
        if (s.state === 'hurt' && s.hurtTimer % 4 < 2) 
            ctx.globalAlpha = 0.6;  // Pisca quando ferido
            
        if (s.state === 'dead') 
            ctx.globalAlpha = Math.max(0, 1 - s.deadTimer / 100);  // Desaparece
        
        // === DESENHAR CORPO (Ellipse Duplo - similar ao slime) ===
        ctx.beginPath();
        // Topo: meia elipse
        ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 0, Math.PI, 0);
        // Fundo: meia elipse
        ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3, 0, 0, Math.PI);
        ctx.closePath();
        
        // === PREENCHIMENTO COM GRADIENTE (CORES SOMBRIAS) ===
        var grad = ctx.createRadialGradient(-w * 0.15, -h * 0.25, 0, 0, 0, w * 0.6);
        grad.addColorStop(0, 'rgba(80,80,90,0.5)');      // Cinzento claro
        grad.addColorStop(0.5, 'rgba(30,30,40,0.4)');    // Cinzento escuro
        grad.addColorStop(1, 'rgba(10,10,15,0.3)');      // Quase preto
        ctx.fillStyle = grad;
        ctx.fill();
        
        // === OUTLINE ===
        ctx.strokeStyle = 'rgba(60,60,70,0.5)';
        ctx.lineWidth = s.isMother ? 2 : 1.2;
        ctx.stroke();
        
        // === DESTAQUES ===
        // Shine superior-esquerdo
        ctx.beginPath();
        ctx.ellipse(-w * 0.12, -h * 0.3, w * 0.16, h * 0.1, -0.3, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255,255,255,0.35)';
        ctx.fill();
        
        // Shine pequeno
        ctx.beginPath();
        ctx.arc(-w * 0.05, -h * 0.45, w * 0.05, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255,255,255,0.25)';
        ctx.fill();
        
        // === OLHOS - VERMELHOS ⭐ (DIFERENTE DOS SLIMES) ===
        var eyeY = -h * 0.15;
        var eyeSpacing = w * 0.14;
        var eyeR = s.isMother ? 4 : 2.5;
        
        // VERMELHOS (não brancos como slimes)
        ctx.fillStyle = 'rgba(255,100,100,0.8)';
        ctx.beginPath();
        ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
        ctx.fill();
        
        // Pupilas (seguem direção)
        var pupilOff = (s.dir || 1) * eyeR * 0.3;
        ctx.fillStyle = 'rgba(0,0,0,0.8)';
        ctx.beginPath();
        ctx.arc(-eyeSpacing + pupilOff, eyeY, eyeR * 0.45, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(eyeSpacing + pupilOff, eyeY, eyeR * 0.45, 0, Math.PI * 2);
        ctx.fill();
        
        // === BARRA DE HP ===
        if (s.state !== 'dead' && s.hp < s.maxHp) {
            ctx.globalAlpha = 0.7;
            var barW = s.isMother ? 40 : 20;
            var barH = s.isMother ? 4 : 3;
            
            // Background
            ctx.fillStyle = '#333';
            ctx.fillRect(-barW / 2, -h / 2 - 8, barW, barH);
            
            // Preenchimento VERMELHO (diferente dos slimes)
            ctx.fillStyle = 'rgba(150,50,50,0.9)';
            ctx.fillRect(-barW / 2, -h / 2 - 8, barW * (s.hp / s.maxHp), barH);
        }
        
        // === CLEANUP ===
        ctx.globalAlpha = 1;
        ctx.restore();
    }
}
```

---

## 📊 Comparação: Desenho do Corpo

### SLIMES & SPIDERS (Ellipse Duplo)
```javascript
// Topo: arc superior de uma elipse
ctx.ellipse(0, -h * 0.1, w / 2, h * 0.5, 
            0,              // rotação (0 = sem girar)
            Math.PI,        // start angle (180° = direita)
            0);             // end angle (0° = volta ao início)

// Fundo: arc inferior de outra elipse (mais larga)
ctx.ellipse(0, -h * 0.1, w / 2 * 1.1, h * 0.3,
            0,
            0,              // start angle (0° = cima)
            Math.PI);       // end angle (180° = direita)
```
**Resultado:** Forma de gota (topo redondo + fundo achatado)

### BUBBLES (Círculo Simples)
```javascript
// Um simples arco de 0° a 360°
ctx.arc(0, wobbleY, raio, 0, Math.PI * 2);
```
**Resultado:** Círculo/esfera perfeita

---

## 🎨 Comparação: Cores

### GRADIENTE SLIME (Colorido)
```javascript
var grad = ctx.createRadialGradient(-w * 0.15, -h * 0.25, 0, 0, 0, w * 0.6);
grad.addColorStop(0, 'rgba(' + (jc.r + 80) + ',' + (jc.g + 80) + ',' + (jc.b + 80) + ',0.5)');
grad.addColorStop(0.5, 'rgba(' + jc.r + ',' + jc.g + ',' + jc.b + ',0.35)');
grad.addColorStop(1, 'rgba(' + (jc.r - 40) + ',' + (jc.g - 40) + ',' + (jc.b - 40) + ',0.25)');
```
→ Cores originais do JELLY_COLORS (azul, vermelho, verde, etc)

### GRADIENTE SPIDER (Cinzento/Preto)
```javascript
var grad = ctx.createRadialGradient(-w * 0.15, -h * 0.25, 0, 0, 0, w * 0.6);
grad.addColorStop(0, 'rgba(80, 80, 90, 0.5)');   // Cinzento
grad.addColorStop(0.5, 'rgba(30, 30, 40, 0.4)'); // Cinzento escuro
grad.addColorStop(1, 'rgba(10, 10, 15, 0.3)');   // Preto
```
→ Sempre as mesmas cores sombrias (nenhuma cor do JELLY_COLORS)

### FILL BUBBLE (Simples)
```javascript
ctx.fillStyle = bc.fill;    // ex: 'rgba(100,180,255,0.25)' - azul claro
ctx.fill();
ctx.strokeStyle = bc.stroke; // ex: 'rgba(150,210,255,0.6)' - azul mais escuro
ctx.stroke();
```
→ Sem gradiente radial, apenas preenchimento simples + contorno

---

## 👁️ Comparação: Olhos

### SLIMES (Brancos)
```javascript
ctx.fillStyle = 'rgba(255,255,255,0.8)';  // BRANCO
ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
ctx.fill();
```

### SPIDERS (VERMELHOS) ⭐
```javascript
ctx.fillStyle = 'rgba(255,100,100,0.8)';  // VERMELHO
ctx.arc(-eyeSpacing, eyeY, eyeR, 0, Math.PI * 2);
ctx.fill();
```

### BUBBLES (Sem olhos)
```javascript
// Nenhum desenho de olho - apenas círculo + brilho
```

---

## 🔢 Comparação: Escalas e Limites

```javascript
// DIMENSÕES BASE
SLIME_SIZE = TILE * 1.05;     // 113px
SPIDER_SIZE = TILE * 0.95;    // 103px
BUBBLE_SIZE = TILE * 1.05;    // 113px

// RAIOS/METADES USADAS NO DESENHO
baseW slime = SLIME_SIZE * 0.9;      // 102px  → desenhado como 51px metade
baseH slime = SLIME_SIZE * 0.8;      // 90px   → desenhado como 45px metade

baseW spider = SPIDER_SIZE * 0.5;    // 52px
baseH spider = SPIDER_SIZE * 0.45;   // 47px

r bubble = BUBBLE_SIZE * 0.45;       // 51px de RAIO

// ESCALAS DE BOSS
SLIME_BOSS_SCALE = 2.0;       // 2x normal
SPIDER_MOTHER_SCALE = 2.0;    // 2x normal
MOTHER_SCALE (bubble) = 3.0;  // 3x normal
QUEEN_SCALE (bubble) = 3.0;   // 3x normal

// LIMITES DE RENDERIZAÇÃO
MAX_SLIMES_VISIBLE = 8;      // Max simultâneos renderizados
MAX_SPIDERS_VISIBLE = 8;
MAX_BUBBLES_VISIBLE = 15;    // Mais porque são maiores e flutuam
```

---

## 🔄 Comparação: Loops Culling

```javascript
// TODOS SEGUEM PADRÃO IDÊNTICO:

var viewTop = camY - TILE * 2;           // Um tile acima da câmera
var viewBot = camY + canvas.height + TILE * 2;  // Um tile abaixo da câmera

for (var i = 0; i < collection.length; i++) {
    var enemy = collection[i];
    
    // 1. Pula se Y está MUITO longe (otimização)
    if (enemy.y < viewTop || enemy.y > viewBot) continue;
    
    // 2. Pula se LIMITE DE RENDERIZAÇÃO foi atingido (mais otimização)
    if (++_drawn > MAX_VISIBLE) break;
    
    // ... renderização ...
}
```

**Benefício:** Garante performance mesmo com centenas de inimigos no mapa

---

## 📋 Checklist de Desenho

### Cada função segue este padrão:

- [ ] Culling de viewport
- [ ] Limite de renderização
- [ ] Cálculo de tamanho base
- [ ] Aplicação de squash/stretch
- [ ] Aplicação de wobble
- [ ] ctx.save() para isolamento
- [ ] ctx.translate() para posição
- [ ] Desenho do corpo (forma geométrica)
- [ ] Preenchimento com gradiente
- [ ] Outline/stroke
- [ ] Destaques (shines)
- [ ] Olhos (se aplicável)
- [ ] Indicadores especiais (se aplicável)
- [ ] Barra de HP
- [ ] Efeitos de estado (hurt, dead)
- [ ] ctx.restore() para cleanup

---

**Arquivo Gerado:** 2025-04-02
**Fonte:** index.html (linhas 6676-8900+)
**Tipo:** Exemplos de Código Simplificados
