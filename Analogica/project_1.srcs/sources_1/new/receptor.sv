`timescale 1ns / 1ps
module uart_rx 
  #(parameter int CLKS_PER_BIT=10416)  // Parámetro para los ciclos de reloj por bit
  (
   input  logic        i_Clock,       // Reloj del sistema
   input  logic        i_Rx_Serial,   // Entrada serial
   output logic        o_Rx_DV,       // Señal de datos recibidos válidos
   output logic [7:0]  o_Rx_Byte      // Byte recibido
   );

  typedef enum logic [2:0] {
    s_IDLE,           // Estado de reposo
    s_RX_START_BIT,   // Recepción del bit de inicio
    s_RX_DATA_BITS,   // Recepción de bits de datos
    s_RX_STOP_BIT,    // Recepción del bit de parada
    s_CLEANUP         // Limpieza
  } state_t;
  
  state_t r_SM_Main = s_IDLE;

  // Registros internos
  logic           r_Rx_Data_R = 1'b1;  // Registro de entrada serial
  logic           r_Rx_Data   = 1'b1;  // Registro de datos recibidos
  logic [15:0]     r_Clock_Count = 0;   // Contador de ciclos
  logic [2:0]     r_Bit_Index   = 0;   // Índice de bits
  logic [7:0]     r_Rx_Byte     = 0;   // Byte recibido
  logic           r_Rx_DV       = 0;   // Señal de datos válidos

  // Sincronización de entrada serial
  always_ff @(posedge i_Clock) begin
    r_Rx_Data_R <= i_Rx_Serial;
    r_Rx_Data   <= r_Rx_Data_R;
  end

  // Máquina de estados
  always_ff @(posedge i_Clock) begin
    case (r_SM_Main)
      s_IDLE: begin
        r_Rx_DV       <= 1'b0;
        r_Clock_Count <= 0;
        r_Bit_Index   <= 0;

        if (r_Rx_Data == 1'b0)
          r_SM_Main <= s_RX_START_BIT;
        else
          r_SM_Main <= s_IDLE;
      end

      s_RX_START_BIT: begin
        if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
          if (r_Rx_Data == 1'b0) begin
            r_Clock_Count <= 0;
            r_SM_Main     <= s_RX_DATA_BITS;
          end else
            r_SM_Main <= s_IDLE;
        end else begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= s_RX_START_BIT;
        end
      end

      s_RX_DATA_BITS: begin
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= s_RX_DATA_BITS;
        end else begin
          r_Clock_Count <= 0;
          r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;

          if (r_Bit_Index < 7) begin
            r_Bit_Index <= r_Bit_Index + 1;
            r_SM_Main   <= s_RX_DATA_BITS;
          end else begin
            r_Bit_Index <= 0;
            r_SM_Main   <= s_RX_STOP_BIT;
          end
        end
      end

      s_RX_STOP_BIT: begin
        if (r_Clock_Count < CLKS_PER_BIT-1) begin
          r_Clock_Count <= r_Clock_Count + 1;
          r_SM_Main     <= s_RX_STOP_BIT;
        end else begin
          r_Rx_DV       <= 1'b1;
          r_Clock_Count <= 0;
          r_SM_Main     <= s_CLEANUP;
        end
      end

      s_CLEANUP: begin
        r_SM_Main <= s_IDLE;
        r_Rx_DV   <= 1'b0;
      end

      default: r_SM_Main <= s_IDLE;
    endcase
  end

  assign o_Rx_DV   = r_Rx_DV;
  assign o_Rx_Byte = r_Rx_Byte;

endmodule
				