`timescale 1ns / 1ps

module tb_uart_rx();

    // Parámetros
    parameter CLKS_PER_BIT = 10416;
    parameter BIT_PERIOD = 104160; // 10416 ciclos * 10ns de periodo

    // Señales
    logic clk = 0;
    logic rx = 1;
    logic rx_dv;
    logic [7:0] rx_byte;

    // Instancia del módulo a probar (DUT)
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .i_Clock(clk),
        .i_Rx_Serial(rx),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );

    // Generación de reloj (100 MHz -> periodo de 10 ns)
    always #5 clk = ~clk;

    // Tarea para emular el envío de un byte por UART
    task send_byte(input logic [7:0] data);
        integer i;
        begin
            // Start bit (0)
            rx = 0;
            #(BIT_PERIOD);
            
            // Data bits (LSB primero)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit (1)
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // Bloque principal de simulación
    initial begin
        // Tiempo de reposo inicial
        #1000;
        
        // Enviar byte de prueba 0xFF (Simula inicio de tu trama)
        send_byte(8'hFF);
        
        // Pausa entre bytes
        #500000;
        
        // Enviar byte de prueba 0x5A (Un dato cualquiera)
        send_byte(8'h5A);
        
        // Esperar para ver el resultado y finalizar
        #500000;
        $finish;
    end

endmodule