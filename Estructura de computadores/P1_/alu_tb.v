// Testbench para modulo alu
`timescale 1 ns / 10 ps //Directiva que fija la unidad de tiempo de simulación y la precision de la unidad
module alu_tb;
//declaracion de señales
reg [2:0] t_Op;
reg t_cin;
reg [3:0] t_A, t_B; 
wire [3:0] t_R;
wire t_z, t_c, t_s;
integer errores;

// error de cualquier tipo, de resultado, de linea zero, de signo y carry
reg error, error_R, error_z, error_s, error_c; 

//instancia del modulo a testear
alu mat(t_R, t_z, t_c, t_s, t_A, t_B, t_cin, t_Op);


initial
begin
	$dumpfile("alu.vcd");
	$dumpvars;

	errores = 0;
	
	t_Op = 3'b000;
	repeat(8)
	begin
		t_cin = 1'b0;
		repeat(2)
		begin
			t_A = 4'b0;
			repeat(16) 
			begin
				t_B = 4'b0;
				repeat(16) 
				begin
					#0.01 check;
					#9.99;
					t_B = t_B + 1;
				end
				t_A = t_A + 1;
			end
			t_cin = t_cin + 1;
		end
		t_Op = t_Op + 1;
	end
	$display("Encontradas %d operaciones erroneas", errores);
  	//fin simulacion
  	$finish;
end

// Tarea para hacer la comprobación automática de resultados
task check;
reg [4:0] expected_R;
reg expected_z, expected_c, expected_s;

begin
	$write("tiempo=%0d A=%b B=%b c_in=%b OP=%b R=%b, Z=%b, C=%b, S=%b.", $time, t_A, t_B, t_cin, t_Op, t_R, t_z, t_c, t_s);
	case (t_Op)	
		3'b000: expected_R = t_A + t_cin;
		3'b001: expected_R = (t_A ^4'b1111) + 4'b0001 + t_cin;
		3'b010: expected_R = t_A + t_B + t_cin;
		3'b011: expected_R = t_A + 1 + t_cin;
		3'b100: expected_R = t_A & t_B;
		3'b101: expected_R = t_A | t_B;
		3'b110: expected_R = t_A ^ t_B;
		3'b111: expected_R[3:0] = ~t_A;
		default: $display("ERROR. Valor no esperado para t_Op: %b", t_Op);
	endcase
	if (t_Op[2]) // Si la operación es lógica
	begin
		expected_c = 1'b0;
		expected_s = expected_R[3];
		error_s = 0;
	 	error_c = 0;
	end
	else
	begin
		expected_c = expected_R[4];
		expected_s = expected_R[3];
		error_s = (expected_s !== t_s);
	 	error_c = (expected_c !== t_c);
	end

	expected_z = ~| expected_R[3:0];
	// generacion señales error generales para toda la ALU
	error_R = (expected_R[3:0] !== t_R); 
	error_z = (expected_z !== t_z);
	error = error_R | error_z | error_s | error_c;
	if (error)
	begin
		errores = errores + 1;
		$display(" ---- ERROR");
		if (error_R)
			$display("\tResultado esperado %b, obtenido %b", expected_R[3:0], t_R);
		if (error_z)
			$display("\tFlag de cero esperado %b, obtenido %b", expected_z, t_z);
		if (error_s)
			$display("\tFlag de signo esperado %b, obtenido %b", expected_s, t_s);
		if (error_c)
			$display("\tFlag de acarreo esperado %b, obtenido %b", expected_c, t_c);
	end
	else
		$display(" ---- OK");
end
endtask
endmodule