classdef ClassCRC < handle
    methods
        function crc = dvbs2_crc8(~, data_bits)
            reg = zeros(1, 8);
            for k = 1:length(data_bits)
                u_k = data_bits(k);
                f = xor(u_k, reg(8));

                r1_new = f;
                r2_new = reg(1);
                r3_new = xor(reg(2), f);
                r4_new = reg(3);
                r5_new = xor(reg(4), f);
                r6_new = reg(5);
                r7_new = xor(reg(6), f);
                r8_new = xor(reg(7), f);

                reg = [r1_new, r2_new, r3_new, r4_new, r5_new, r6_new, r7_new, r8_new];
            end
            crc = reg;    
        end
    end
end