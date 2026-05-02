/* ==============================================================================
 * PROJETO OBSERVATÓRIO DO AR
 * Modelagem 3D - Mini Estações de Qualidade do Ar
 * 
 * Este arquivo contém a modelagem paramétrica do abrigo meteorológico modular, 
 * incluindo o encapsulamento de sensores (SHT30, PM2.5) e da câmera, para uso 
 * nas mini estações de monitoramento do projeto Observatório do Ar.
 *
 * LICENÇA: GNU General Public License v3.0 (GPLv3)
 * Este programa é um software livre; você pode redistribuí-lo e/ou modificá-lo 
 * sob os termos da Licença Pública Geral GNU (GNU GPL) conforme publicada pela 
 * Free Software Foundation; versão 3 da Licença, ou (a seu critério) qualquer 
 * versão posterior.
 * ============================================================================== */

// Resolução global para renderização de geometrias curvas (arcos, cilindros, esferas)
$fn = 100;

// -----------------------------------------------------
// PARÂMETROS DA PLACA DE CIRCUITO IMPRESSO (PCB DA CÂMERA)
// -----------------------------------------------------
pcb_largura = 42.1;        // Largura da PCB em mm
pcb_altura = 58.5;         // Altura da PCB em mm
pcb_espessura = 1.6;       // Espessura da placa de fibra de vidro em mm

deslocamento_interno_y = -15; // Deslocamento interno no eixo Y (uso legado/estrutural)
espessura_parede_reta = 1;    // Espessura de paredes retas genéricas

// -----------------------------------------------------
// PARÂMETROS DE FIXAÇÃO E HASTES
// -----------------------------------------------------
tipo_haste = 4; // Especificação do diâmetro da haste roscada (M4 = 4mm)
raio_furo_passante = (tipo_haste / 2) + 0.25; // Raio do furo com 0.5mm de folga diametral para passagem livre da haste
// Cálculo condicional para definir o raio do alojamento da porca (recesso fêmea) com base no tipo de haste escolhido
raio_recesso_femea = (tipo_haste == (5/16) * 25.4) ? 8 : (tipo_haste == 6) ? 7 : (tipo_haste == 4) ? 5 : (tipo_haste == 3) ? 4 : 7;

distancia_furo_haste = 41; // Distância radial do centro do abrigo até o centro geométrico dos furos de fixação

// -----------------------------------------------------
// PARÂMETROS DA CÚPULA DA CÂMERA (TOP MODULE)
// -----------------------------------------------------
folga = 0.6;                       // Folga de tolerância de impressão geral
wall_thickness = 1.4;              // Espessura da parede da cúpula da câmera
espaco_conector_traseiro = 25;     // Profundidade reservada para acomodar conectores e cabos na parte traseira da PCB
diametro_furo_camera = 17.3;       // Diâmetro da abertura frontal para a lente da câmera
folga_lente = 0.5;                 // Folga de segurança entre a lente e a parede interna da cúpula

ajuste_corte_frontal = 3 - 3.4;    // Calibração do plano de corte frontal da cúpula
extensao_saia_inferior = 0;        // Comprimento adicional para a base cilíndrica da cúpula

profundidade_guia_lateral = 6;     // Profundidade dos trilhos laterais que seguram a PCB
encaixe_lateral = 3.5 - 2.2;       // Medida de ajuste para o aperto lateral da PCB nos trilhos
folga_fenda = 0.15;                // Tolerância na espessura da fenda do trilho
folga_lateral = 0.2;               // Tolerância na largura do trilho

deslocamento_z_pcb = -4;           // Posição Z da PCB em relação à origem da cúpula
offset_z_camera_na_placa = 13.6;   // Posição Z do centro da lente em relação à base da PCB

deslocamento_y_cupula = -5;        // Deslocamento da cúpula no eixo Y para balancear o centro de gravidade

// Cálculos dinâmicos para a geometria externa da cúpula
dome_radius = (pcb_altura/2) + folga + wall_thickness + 2; 
comprimento_saia_cilindrica = (pcb_altura/2) - deslocamento_z_pcb + folga + extensao_saia_inferior;

// Cálculos de limites frontais e traseiros para determinar a assimetria e o offset de centralização
front_face_abs_y = -(pcb_espessura/2 + 22.5 + folga_lente) - ajuste_corte_frontal;
avanco_frontal_total_y = pcb_espessura/2 + 22.5 + 2.3;
avanco_traseiro_total_y = pcb_espessura/2 + espaco_conector_traseiro;
offset_y = (avanco_traseiro_total_y - avanco_frontal_total_y) / 2; // Desvio Y para acomodar a PCB de forma assimétrica

// -----------------------------------------------------
// PARÂMETROS DO PARAFUSO FRANCÊS (LEGADO)
// -----------------------------------------------------
d_cabeca = 18;
d_haste = 7.9375;
comp_haste = 177.8;
h_cabeca = 4.5;
l_quadrado = 8.1;
h_quadrado = 4.5;

r_esfera = (pow(h_cabeca, 2) + pow(d_cabeca/2, 2)) / (2 * h_cabeca); // Raio da calota esférica da cabeça
z_offset = r_esfera - h_cabeca; // Diferença para alinhar a base da cabeça em Z=0

// -----------------------------------------------------
// PARÂMETROS DOS ANÉIS DO ABRIGO METEOROLÓGICO (ALETAS)
// -----------------------------------------------------
d_ext_aleta = 120; // Diâmetro externo total do disco do abrigo
d_int_aleta = 96;  // Diâmetro interno (área útil oca para fluxo de ar)
wall_aleta = 2;    // Espessura da parede sólida da aleta
angulo_aleta = 50; // Ângulo de inclinação da aleta para barrar luz solar e permitir ventilação
// Cálculo trigonométrico da altura da aleta baseada na largura da aba e no ângulo
h_aleta = ((d_ext_aleta - d_int_aleta) / 2) * tan(angulo_aleta); 

// Passo de translação no eixo Z utilizado para gerar a matriz de empilhamento
distancia_empilhamento = h_aleta - 2; 

// -----------------------------------------------------
// MÓDULOS DE COMPONENTES VISUAIS (HARDWARE)
// -----------------------------------------------------

// Gera a representação geométrica da haste roscada M4 para visualização
module haste_m4() {
    color("silver")
    translate([0, 0, -15])
        cylinder(h=150, d=4, $fn=50);
}

// Gera a representação de uma porca sextavada M4 com chanfros superiores e inferiores
module porca_sextavada() {
    Waf = 12.6; // Distância entre as faces planas (Dimensão customizada/escalada da peça anterior)
    Height = 6.75;
    Hole_Dia = 8.5;
    Vertex_Radius = Waf / sqrt(3);
    Chamfer_Factor = 0.92;
    color("silver")
    difference() {
        difference() {
            linear_extrude(height = Height, center = true)
                circle(r = Vertex_Radius, $fn = 6);
            cylinder(h = Height + 1, d = Hole_Dia, center = true);
        }
        translate([0, 0, Height / 2])
            rotate_extrude()
                translate([Vertex_Radius * Chamfer_Factor, 0, 0])
                    intersection() {
                        square(size = [Height, Height], center = false);
                        circle(r = Height);
                    }
        translate([0, 0, -Height / 2])
            mirror([0, 0, 1])
            rotate_extrude()
                translate([Vertex_Radius * Chamfer_Factor, 0, 0])
                    intersection() {
                        square(size = [Height, Height], center = false);
                        circle(r = Height);
                    }
    }
}

// Gera a representação de mock-up da PCB, da lente cilíndrica frontal e do espaço traseiro reservado
module pcb() {
    rotate([90, 0, 0])
    color("red")
    cube([pcb_largura, pcb_altura, pcb_espessura], center = true);
    translate([0, -(pcb_espessura/2 + 22.5-3.7), offset_z_camera_na_placa])
    rotate([90, 0, 0])
    cylinder(h=2.3, d=7, center= true);
    color("blue", 0.5)
    translate([0, (pcb_espessura/2) + (espaco_conector_traseiro/2), -10])
    cube([pcb_largura - 10, espaco_conector_traseiro, 15], center = true);
}

// -----------------------------------------------------
// MÓDULOS GEOMÉTRICOS AUXILIARES (2D)
// -----------------------------------------------------

// Retorna um perfil elíptico através de escalonamento em X e Y
module elipse(rx, ry) {
    scale([rx, ry, 1])
        circle(r = 1);
}

// Retorna uma figura com bordas arredondadas e área central plana (capsule)
module oblongo(distancia_centros, raio) {
    hull() {
        translate([-distancia_centros/2, 0, 0])
            circle(r=raio, $fn=50);
        translate([distancia_centros/2, 0, 0])
            circle(r=raio, $fn=50);
    }
}

// -----------------------------------------------------
// MÓDULOS DE CONSTRUÇÃO (PEÇAS IMPRESSAS 3D)
// -----------------------------------------------------

// Gera o corpo principal do alojamento da câmera (casco superior esférico com saia cilíndrica)
module cupula_enclosure() {
    rel_front_face_y = front_face_abs_y - offset_y;
    rel_front_face_y_inner = rel_front_face_y + wall_thickness;
    rel_camera_hole_y = -(pcb_espessura/2 + 22.5) - offset_y;
    z_furo_camera = offset_z_camera_na_placa + deslocamento_z_pcb;
    c_size = dome_radius * 4;
    
    // Submódulo: cria a matriz externa sólida (esfera unida a cilindro) cortada no plano Z
    module perfil_solido(raio, vazamento_inferior = 0) {
        union() {
            difference() {
                sphere(r=raio, $fn=100);
                translate([0, 0, -raio]) cube([raio*3, raio*3, raio*2], center=true);
            }
            overlap = 0.1;
            translate([0, 0, -comprimento_saia_cilindrica - vazamento_inferior])
                cylinder(r=raio, h=comprimento_saia_cilindrica + vazamento_inferior + overlap, $fn=100);
        }
    }
    
    // Submódulo: cria o negativo interno para subtrair e formar as paredes da cúpula
    module volume_interno() {
        difference() {
            perfil_solido(dome_radius - wall_thickness, 1);
            translate([0, rel_front_face_y_inner - c_size/2, 0])
                cube([c_size, c_size, c_size], center=true);
        }
    }
    
    union() {
        difference() {
            difference() {
                perfil_solido(dome_radius, 0);
                translate([0, rel_front_face_y - c_size/2, 0])
                    cube([c_size, c_size, c_size], center=true);
            }
            volume_interno();
            translate([0, rel_camera_hole_y+5, z_furo_camera])
                rotate([90, 0, 0])
                cylinder(h=wall_thickness +20, d=diametro_furo_camera, center=true);
        }
        // Gera os trilhos internos no eixo Z para o encaixe por deslizamento da PCB
        intersection() {
            guia_z_topo = deslocamento_z_pcb + (pcb_altura / 2);
            guia_z_base = -comprimento_saia_cilindrica;
            altura_guia_dinamica = guia_z_topo - guia_z_base;
            guias_z_center = guia_z_base + (altura_guia_dinamica / 2);
            bloco_x = dome_radius;
            pos_x = (pcb_largura / 2) + (bloco_x / 2) - encaixe_lateral;
            translate([0, -offset_y, guias_z_center]) {
                difference() {
                    union() {
                        translate([pos_x, 0, 0]) cube([bloco_x, profundidade_guia_lateral, altura_guia_dinamica], center=true);
                        translate([-pos_x, 0, 0]) cube([bloco_x, profundidade_guia_lateral, altura_guia_dinamica], center=true);
                    }
                    cube([pcb_largura + (folga_lateral * 2), pcb_espessura + folga_fenda, altura_guia_dinamica + 2], center=true);
                    translate([0, 0, -(altura_guia_dinamica/2)])
                        rotate([45, 0, 0])
                        cube([pcb_largura + (folga_lateral * 2), 8, 8], center=true);
                }
            }
            volume_interno();
        }
    }
}

// Gera o corpo de ancoragem e blindagem interna para o sensor PM2.5
module bottom_cy(diam_anel, raio_limpeza){
    // Caixa inferior contendo entradas de exaustão e sensor ótico
    difference(){
        cube([50,39,7], center=true);
        translate([-12.5,7.0,0]) cylinder(9, d= 20.5, center=true);
        translate([12.9, 7.50, 0]) cube([14, 9.4, 9], center = true);
    }
    // Caixa principal vazada centralizada nas hastes de interseção em X e Y
    translate([0,0,-3])
        difference(){
            union() {
                cube([50,39,12], center=true);
                cube([diam_anel, 17, 8], center=true);
                cube([17, diam_anel, 8], center=true);
            }
            cube([48.5,36.9,13], center=true);
            // Limpa as matrizes de hastes nos quatro polos para evitar conflito com os furos do anel
            for (angulo = [0, 90, 180, 270]) {
                rotate([0, 0, angulo]) {
                    translate([0, distancia_furo_haste, 0])
                        cylinder(h=20, r=raio_limpeza, center=true, $fn=50);
                }
            }
        }
}

// Gera o suporte e duto de acomodação para o sensor de temperatura SHT30
module suporte_sht30(diam_anel, raio_limpeza) {
    difference() {
        union() {
            cylinder(h=4, d=30, center=true, $fn=100);
            rotate([0, 0, 180]) cube([diam_anel, 17, 4], center=true);
            rotate([0, 0, -90]) cube([diam_anel, 17, 4], center=true);
        }
        cylinder(h=6, d=13, center=true, $fn=100);
        translate([0, 0, -2]) cylinder(h=4, d=18, center=true, $fn=50);
        for (angulo = [0, 90, 180, 270]) {
            rotate([0, 0, angulo]) {
                translate([0, distancia_furo_haste, 0])
                    cylinder(h=20, r=raio_limpeza, center=true, $fn=50);
            }
        }
    }
}

// Gera o perfil em revolução (360 graus) da aleta meteorológica cônica a partir de um polígono 2D
module aleta(d_ext, d_int, wall, h) {
    rotate_extrude($fn=100) {
        polygon([
            [d_ext/2, 0],
            [(d_ext/2) - wall, 0],
            [(d_int/2) - wall, h],
            [d_int/2, h]
        ]);
    }
}

// Gera os 4 blocos conectores para os anéis padrão (com pinos de fixação embaixo e recessos em cima)
module bases_fixacao(d_ext, d_int, h, raio_furo, raio_femea) {
    altura_pino = 2;
    folga_impressao = 0.3;
    raio_pino_macho = raio_femea - folga_impressao;
    largura_bloco = (raio_femea * 2)+1;
    comprimento_bloco = 26;
    offset_y_bloco = 5;
    altura_bloco = 12;
    
    difference() {
        // Geometria de adição (Matrizes + Pinos)
        union() {
            // Blocos retangulares confinados pelo diâmetro do anel exterior
            intersection() {
                union() {
                    for (angulo = [0, 90, 180, 270]) {
                        rotate([0, 0, angulo])
                            translate([0, distancia_furo_haste + offset_y_bloco, h - (altura_bloco/2)])
                                cube([largura_bloco, comprimento_bloco, altura_bloco], center=true);
                    }
                }
                rotate_extrude($fn=100) {
                    polygon([[0, 0], [d_ext/2, 0], [d_int/2, h], [0, h]]);
                }
            }
            // Pinos macho projetando-se da face inferior, com corte reto externo ("D")
            for (angulo = [0, 90, 180, 270]) {
                rotate([0, 0, angulo]) {
                    difference() {
                        translate([0, distancia_furo_haste, h - altura_bloco - altura_pino])
                            cylinder(h=altura_pino, r=raio_pino_macho, $fn=50);
                        translate([0, distancia_furo_haste + raio_pino_macho, h - altura_bloco - altura_pino + 1])
                            cube([raio_pino_macho * 3, raio_pino_macho, altura_pino + 2], center=true);
                    }
                }
            }
        }
        // Subtração furos passantes e recessos de encaixe fêmea no topo
        for (angulo = [0, 90, 180, 270]) {
            rotate([0, 0, angulo]) {
                translate([0, distancia_furo_haste, h - altura_bloco - altura_pino - 1])
                    cylinder(h=altura_bloco + altura_pino + 2, r=raio_furo, $fn=50);
                translate([0, distancia_furo_haste, h - altura_pino-2.5])
                    cylinder(h=altura_pino + 3, r=raio_femea, $fn=50);
            }
        }
    }
}

// Gera os 4 blocos conectores EXCLUSIVOS do anel base (sem pinos inferiores, mas com fenda para suporte metálico)
module bases_fixacao_anel_base(d_ext, d_int, h, raio_furo, raio_femea) {
    largura_bloco = (raio_femea * 2)+8;
    comprimento_bloco = 26;
    offset_y_bloco = 5;
    altura_bloco = 15;
    difference() {
        // Matriz sólida restrita à circunferência externa
        intersection() {
            union() {
                for (angulo = [0, 90, 180, 270]) {
                    rotate([0, 0, angulo])
                        translate([0, distancia_furo_haste + offset_y_bloco, h - (altura_bloco/2)])
                            cube([largura_bloco, comprimento_bloco, altura_bloco], center=true);
                }
            }
            rotate_extrude($fn=100) {
                polygon([[0, 0], [d_ext/2, 0], [d_int/2, h], [0, h]]);
            }
        }
        // Subtrações estruturais de fixação
        for (angulo = [0, 90, 180, 270]) {
            rotate([0, 0, angulo]) {
                // Alojamento fêmea no topo para encaixe do anel superior
                translate([0, distancia_furo_haste, h - 2 - 2.5])
                    cylinder(h=5, r=raio_femea, $fn=50);
                
                // Furo passante para a haste M4
                translate([0, distancia_furo_haste, h - altura_bloco - 1])
                    cylinder(h=altura_bloco + 2, r=raio_furo, $fn=50);
                
                // Fenda retangular de 2.1mm na base para intersecção com a chapa do suporte
                translate([0, distancia_furo_haste + 3.5, h - 13])
                    cube([largura_bloco + 5, 2.1, 13], center=true);
            }
        }
    }
}

// Combina a aleta externa padrão com blocos de fixação machos/fêmeas
module anel_padrao(d_ext, d_int, h) {
    aleta(d_ext, d_int, wall_aleta, h);
    bases_fixacao(d_ext, d_int, h, raio_furo_passante, raio_recesso_femea);
}

// Combina a aleta externa com as bases modificadas para atuar como ancoragem inicial do suporte de metal
module anel_base(d_ext, d_int, h) {
    aleta(d_ext, d_int, wall_aleta, h);
    bases_fixacao_anel_base(d_ext, d_int, h, raio_furo_passante, raio_recesso_femea);
}

// Anel padrão modificado com o acoplamento do suporte interno para sensor SHT30
module anel_sht30(d_ext, d_int, h, wall) {
    anel_padrao(d_ext, d_int, h);
    intersection() {
        translate([0, 0, h - 2]) suporte_sht30(d_ext, raio_recesso_femea);
        rotate_extrude($fn=100) {
            polygon([[0, 0], [(d_ext/2) - wall, 0], [(d_int/2) - wall, h], [0, h]]);
        }
    }
}

// Anel padrão modificado com o acoplamento do invólucro do sensor de partículas PM2.5
module anel_pm25(d_ext, d_int, h, wall) {
    anel_padrao(d_ext, d_int, h);
    intersection() {
        translate([0, 0, h - 1]) rotate([0,0,0]) bottom_cy(d_ext, raio_recesso_femea);
        rotate_extrude($fn=100) {
            polygon([[0, 0], [(d_ext/2) - wall, 0], [(d_int/2) - wall, h], [0, h]]);
        }
    }
}

// Gera o piso circular contínuo que fecha a câmara do abrigo e sustenta a cúpula da câmera no eixo superior
module base_cupula(espessura_base, d_int) {
    rel_front_face_y = front_face_abs_y - offset_y;
    rel_front_face_y_inner = rel_front_face_y + wall_thickness;
    c_size = dome_radius * 4;
    difference() {
        cylinder(d=d_int+1, h=espessura_base, $fn=100);
        // Gera furos passantes na placa contínua para passagem das hastes
        for (angulo = [0, 90, 180, 270]) {
            rotate([0, 0, angulo]) {
                translate([0, distancia_furo_haste, -1])
                    cylinder(h=espessura_base + 2, r=raio_furo_passante, $fn=50);
            }
        }
        // Subtração retangular profunda correspondente ao deslocamento de encaixe do módulo da câmera
        translate([0, offset_y + deslocamento_y_cupula, -1]) {
            difference() {
                cylinder(r=dome_radius - wall_thickness, h=espessura_base + 2, $fn=100);
                translate([0, rel_front_face_y_inner - c_size/2, 0])
                    cube([c_size, c_size, espessura_base * 4], center=true);
            }
        }
    }
}

// Agrupamento hierárquico das partes do andar superior do abrigo (Base + Cúpula + Placa)
module modulo_topo_camera(d_int) {
    espessura_base = 2;
    translate([0, 0, 0])
        base_cupula(espessura_base, d_int);
    translate([0, offset_y + deslocamento_y_cupula, espessura_base + comprimento_saia_cilindrica])
        cupula_enclosure();
    // A PCB está desativada no momento via '//', caso necessária, remover o comentário das duas linhas abaixo:
    //translate([0, deslocamento_y_cupula, espessura_base + comprimento_saia_cilindrica + deslocamento_z_pcb])
      //  pcb();
}

// -----------------------------------------------------
// MATRIZ DE EMPILHAMENTO GLOBAL DO MODELO (VISUALIZAÇÃO)
// -----------------------------------------------------

// Nível 0: Base conectada ao suporte
// translate([0, 0, 0])
    anel_base(d_ext_aleta, d_int_aleta, h_aleta);

// Nível 1: Módulo do sensor SHT30
// translate([0, 0, distancia_empilhamento * 1])
//    anel_sht30(d_ext_aleta, d_int_aleta, h_aleta, wall_aleta);

// Nível 2 a 3: Espaçadores
// translate([0, 0, distancia_empilhamento * 2])
//    anel_padrao(d_ext_aleta, d_int_aleta, h_aleta);
// translate([0, 0, distancia_empilhamento * 3])
//    anel_padrao(d_ext_aleta, d_int_aleta, h_aleta);

// Nível 4: Módulo de particulados
// translate([0, 0, distancia_empilhamento * 4])
//    anel_pm25(d_ext_aleta, d_int_aleta, h_aleta, wall_aleta);

// Nível 5: Espaçador
// translate([0, 0, distancia_empilhamento * 5])
//    anel_padrao(d_ext_aleta, d_int_aleta, h_aleta);

// Nível 6: Módulo do teto da câmera
// translate([0, 0, distancia_empilhamento * 6])
//    modulo_topo_camera(d_int_aleta);