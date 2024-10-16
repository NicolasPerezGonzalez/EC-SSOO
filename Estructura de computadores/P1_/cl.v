module  cl(output wire out, input wire a, b, input wire [1:0] S);

    wire sa,so,sx,sn;

    and pa(sa,a,b);
    or  po(so,a,b);
    xor px(sx,a,b);
    not pn(sn,a,b);
    mux4_1 pm(out,pa,po,px,pn,S);

endmodule