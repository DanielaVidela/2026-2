`timescale 1ns / 1ps
module receptor (
    input logic clk,         // Reloj rápido (153.6 kHz)
    input logic Rx,          // Cable que recibe los datos
    output logic [7:0] data, // Los 8 bits ya ordenados
    output logic ready       // Bandera que avisa: "¡Llegó un dato!"
);

    logic [1:0] state = 0;   // 0: INICIO, 1: DATOS, 2: FIN
    logic [3:0] sample = 0;  // Contador de fotos (0 a 15)
    logic [2:0] bit_pos = 0; // Contador de bits (0 a 7)

    always_ff @(posedge clk) begin
        ready <= 0; // Se apaga la bandera por defecto
        
        case (state)
            // ESTADO 0: Esperando el bit de inicio (Start)
            0: begin 
                if (Rx == 0) sample <= sample + 1; // Si el cable baja a 0, empieza a contar
                else sample <= 0;                  // Si es falso, vuelve a cero
                
                if (sample == 15) begin // Si contó 15 seguidos, confirmó que es un inicio real
                    state <= 1;
                    bit_pos <= 0;
                    sample <= 0;
                end
            end
            
            // ESTADO 1: Leyendo los 8 bits de información
            1: begin 
                sample <= sample + 1;
                
                if (sample == 8) data[bit_pos] <= Rx; // Saca la "foto" justo al medio del bit
                
                if (sample == 15) begin // Terminó el tiempo de este bit
                    bit_pos <= bit_pos + 1; // Pasa al siguiente bit
                    if (bit_pos == 7) state <= 2; // Si ya leyó 8 bits, va al estado final
                end
            end
            
            // ESTADO 2: Bit de parada (Stop)
            2: begin 
                sample <= sample + 1;
                if (sample == 15) begin // Espera que pase el tiempo del bit de parada
                    state <= 0; // Vuelve al inicio para buscar otro paquete
                    ready <= 1; // ¡Levanta la bandera un instante para avisar que terminó!
                end
            end
        endcase
    end
endmodule
