`timescale 1ns / 1ps
module sietes(
    input logic [3:0] numero,
    output logic [6:0] segmentos
);

always_comb begin
    // Orden de los bits: {CA, CB, CC, CD, CE, CF, CG}
    case(numero)
        4'b0000: segmentos = 7'b0000001; // 0
        4'b0001: segmentos = 7'b1001111; // 1
        4'b0010: segmentos = 7'b0010010; // 2
        4'b0011: segmentos = 7'b0000110; // 3
        4'b0100: segmentos = 7'b1001100; // 4
        4'b0101: segmentos = 7'b0100100; // 5
        4'b0110: segmentos = 7'b0100000; // 6
        4'b0111: segmentos = 7'b0001111; // 7
        4'b1000: segmentos = 7'b0000000; // 8
        4'b1001: segmentos = 7'b0000100; // 9
        default: segmentos = 7'b1111111; // Apagado por defecto
    endcase
end
endmodule
