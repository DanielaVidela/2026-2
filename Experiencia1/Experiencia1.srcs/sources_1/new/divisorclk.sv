`timescale 1ns / 1ps

module divisorclk (
    input logic freq_in,     // Reloj de la Basys 3 100 MHz
    output logic freq_div    // Reloj de salida 9600 Hz para la comunicación UART
);
    
    // Factor de división para 100 MHz a 9600 Hz
    //
    parameter constNumber = 5208;  

    logic [31:0] count = 0;  // Contador de 32 bits, uno de 13 basta, pero se toman más por seguridad
    // esto es porque quiero

    always_ff @(posedge freq_in) begin //se activa cuando recibe una señal de 100MHz     
        if (count == constNumber - 1) begin // si es que el contador llega a 5207
            freq_div <= ~freq_div;  // Invierte la señal
            count <= 0;             //reinicia el contador
        end else begin
            count <= count + 1;    // mientras no sea el numero establecido sigue sumando
        end
    end
endmodule
