`timescale 1ns / 1ps
module Exp1 (
    input logic clk,
    input logic Rx,
    input logic [15:0] sw,
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic dp
);

    // --- 1. CONEXIÓN DE LOS MÓDULOS (INSTANCIACIÓN) ---
    
    logic clk_153k; // Cable virtual que llevará el reloj rápido
    
    // Llamamos al divisor
    divisorclk reloj_uart (
        .freq_in(clk),
        .rst(1'b0),         // Lo dejamos siempre en 0 para no resetear
        .freq_div(clk_153k)
    );

    logic [7:0] dato_rx;    // Cable virtual para el byte recibido
    logic bandera_rx;       // Cable virtual que avisa cuando llega un byte
    
    // Llamamos al receptor
    receptor modulo_rx (
        .clk(clk_153k),
        .Rx(Rx),
        .data(dato_rx),
        .ready(bandera_rx)
    );

    // --- 2. DECODIFICACIÓN Y GUARDADO DE VOLTAJES ---
    
    // Memorias para los voltajes (Unidad, Décima, Centésima)
    logic [7:0] at_u, at_d, at_c;       
    logic [7:0] real_u, real_d, real_c; 
    
    logic [2:0] estado_paquete = 0; // Lleva la cuenta de qué byte estamos leyendo

    always_ff @(posedge clk) begin
        if (bandera_rx == 1) begin          // Si el receptor levantó la bandera...
            
            if (dato_rx == 8'hFF) begin     // ¿Es la bandera de inicio 0xFF?
                estado_paquete <= 1;        // Empezamos a guardar en el siguiente ciclo
            end 
            else begin                      // Si no es 0xFF, son datos de voltaje
                case (estado_paquete)
                    1: at_u   <= dato_rx;
                    2: at_d   <= dato_rx;
                    3: at_c   <= dato_rx;
                    4: real_u <= dato_rx;
                    5: real_d <= dato_rx;
                    6: real_c <= dato_rx;
                endcase
                
                // Avanzamos al siguiente espacio de memoria
                if (estado_paquete > 0 && estado_paquete < 7) begin
                    estado_paquete <= estado_paquete + 1;
                end
            end
        end
    end
// (Pega esto justo debajo del bloque always_ff del código anterior, antes de endmodule)

    // --- 3. SELECCIÓN CON SWITCH Y CONTROL DEL DISPLAY ---
    
    // Entradas y salidas nuevas que debes agregar al inicio de tu module Exp1:
    // input logic [15:0] sw,
    // output logic [6:0] seg,
    // output logic [3:0] an,
    // output logic dp

    logic [7:0] u_sel, d_sel, c_sel; // Variables que irán al display
    
    // Si el switch 0 está arriba, muestra el real. Si está abajo, el atenuado.
    always_comb begin
        if (sw[0] == 1) begin
            u_sel = real_u; d_sel = real_d; c_sel = real_c;
        end else begin
            u_sel = at_u; d_sel = at_d; c_sel = at_c;
        end
    end

    // Reloj rápido para engañar al ojo y ver todos los números encendidos
    logic [16:0] contador_refresh = 0;
    always_ff @(posedge clk) begin
        contador_refresh <= contador_refresh + 1;
    end
    
    logic [1:0] turno_display;
    assign turno_display = contador_refresh[16:15]; // Cambia cada ~3 ms
    
    logic [3:0] digito_a_traducir; // Número que pasará por el diccionario sietes.sv

    always_comb begin
        case(turno_display)
            2'b00: begin
                an = 4'b0111;                  // Enciende dígito 1 (Unidades)
                digito_a_traducir = u_sel[3:0]; 
                dp = 0;                        // Enciende el punto decimal (lógica invertida)
            end
            2'b01: begin
                an = 4'b1011;                  // Enciende dígito 2 (Décimas)
                digito_a_traducir = d_sel[3:0];
                dp = 1;                        // Apaga el punto
            end
            2'b10: begin
                an = 4'b1101;                  // Enciende dígito 3 (Centésimas)
                digito_a_traducir = c_sel[3:0];
                dp = 1;                        // Apaga el punto
            end
            2'b11: begin
                an = 4'b1110;                  // Enciende dígito 4
                digito_a_traducir = 4'b1111;   // Lo mandamos al "default" de sietes.sv para que se apague
                dp = 1;                        // Apaga el punto
            end
        endcase
    end

    // --- 4. TRADUCCIÓN A LUCES ---
    // Llamamos al diccionario que creamos antes
    sietes traductor_display (
        .numero(digito_a_traducir),
        .segmentos(seg)
    );
endmodule
