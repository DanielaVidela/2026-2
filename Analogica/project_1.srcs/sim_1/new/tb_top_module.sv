`timescale 1ns / 1ps
`timescale 1ns / 1ps

module tb_top_module();
    logic clk;
    logic rx;
    logic sw;
    logic [6:0] seg;
    logic [3:0] an;
    logic dp;

    // Instancia del módulo principal
    top_module uut (
        .clk(clk),
        .rx(rx),
        .sw(sw),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    // Generación de reloj de 100MHz (Periodo = 10ns)
    always #5 clk = ~clk;

    // Tarea para emular el envío UART desde la ESP32 (a 9600 baudios)
    task send_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start bit
            #(10416 * 10); // Espera 1 ciclo de baudio (10416 ciclos de 10ns)
            
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i]; // Data bits (LSB primero)
                #(10416 * 10);
            end
            
            rx = 1; // Stop bit
            #(10416 * 10);
        end
    endtask

    initial begin
        // 1. Condiciones iniciales
        clk = 0;
        rx = 1; // Línea UART en reposo es HIGH
        sw = 0; // Mostrar datos acondicionados
        #100;

        // 2. Enviar trama completa
        send_byte(8'hFF); // Byte de inicio (255)
        send_byte(8'h01); // u_at (1)
        send_byte(8'h02); // d_at (2)
        send_byte(8'h03); // c_at (3)
        send_byte(8'h04); // u_real (4)
        send_byte(8'h05); // d_real (5)
        send_byte(8'h06); // c_real (6)

        // 3. Esperar y observar el multiplexado del display (sw=0)
        #5000000; 
        
        // 4. Cambiar el switch para observar el voltaje real (sw=1)
        sw = 1;
        #5000000;

        $finish; // Terminar simulación
    end
endmodule
