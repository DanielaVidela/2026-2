`timescale 1ns / 1ps

module top_module (
    input  logic clk,          // Reloj principal de la Basys 3 (100 MHz)
    input  logic rx,           // Pin de recepción UART (conectado a TX de ESP32)
    input  logic sw,           // Switch para seleccionar qué voltaje mostrar
    output logic [6:0] seg,    // Segmentos A-G del display
    output logic [3:0] an,     // Ánodos (selección de qué dígito encender)
    output logic dp            // Punto decimal del display
);

    // 1. Señales de interconexión UART
    logic rx_dv;
    logic [7:0] rx_byte;

    // Instancia del UART RX con el parámetro de 9600 baudios (10416 ciclos)
    uart_rx #(.CLKS_PER_BIT(10416)) uart_inst (
        .i_Clock(clk),
        .i_Rx_Serial(rx),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );

    // 2. Registros para almacenar la trama de datos
    logic [3:0] u_at, d_at, c_at;
    logic [3:0] u_real, d_real, c_real;
    logic [2:0] byte_count = 0;

    // Máquina de estados para capturar la trama de 7 bytes
    always_ff @(posedge clk) begin
        if (rx_dv) begin
            if (rx_byte == 8'hFF) begin
                byte_count <= 1; // Detecta el byte de inicio (0xFF)
            end else if (byte_count > 0) begin
                case (byte_count)
                    3'd1: u_at   <= rx_byte[3:0];
                    3'd2: d_at   <= rx_byte[3:0];
                    3'd3: c_at   <= rx_byte[3:0];
                    3'd4: u_real <= rx_byte[3:0];
                    3'd5: d_real <= rx_byte[3:0];
                    3'd6: begin 
                       c_real <= rx_byte[3:0];
                       byte_count <= 0; // Finaliza la captura de la trama
                    end
                    default: ; // CORRECCIÓN: Agregado para evitar el aviso [Synth 8-155]
                endcase
                if (byte_count > 0 && byte_count < 6) byte_count <= byte_count + 1;
            end
        end
    end

    // 3. Lógica del Multiplexor del Display y Selector de Voltaje
    logic [19:0] refresh_counter = 0;
    logic [1:0] digit_select;
    logic [3:0] current_digit;

    // Contador para refrescar el display a alta velocidad (~190 Hz)
    always_ff @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    assign digit_select = refresh_counter[19:18]; 

    // Asignación de datos según la posición del switch
    logic [3:0] d_unidad, d_decima, d_centesima;
    assign d_unidad    = sw ? u_real : u_at;
    assign d_decima    = sw ? d_real : d_at;
    assign d_centesima = sw ? c_real : c_at;

    always_comb begin
        case (digit_select)
            2'b00: begin // Dígito de las centésimas (derecha)
                an = 4'b1110; 
                current_digit = d_centesima;
                dp = 1'b1;    // Apagado (lógica negativa)
            end
            2'b01: begin // Dígito de las décimas (medio)
                an = 4'b1101; 
                current_digit = d_decima;
                dp = 1'b1;
            end
            2'b10: begin // Dígito de las unidades (izquierda)
                an = 4'b1011; 
                current_digit = d_unidad;
                dp = 1'b0;    // Encendido para formar el X.XX
            end
            2'b11: begin // Cuarto dígito no utilizado
                an = 4'b1111; 
                current_digit = 4'b0000;
                dp = 1'b1;
            end
            // CORRECCIÓN: Eliminado el "default" innecesario para evitar el aviso [Synth 8-226]
        endcase
    end

    // 4. Instancia del decodificador de 7 segmentos
    sietes display_inst (
        .numero(current_digit),
        .segmentos(seg)
    );

endmodule