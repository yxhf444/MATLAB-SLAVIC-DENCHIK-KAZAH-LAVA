classdef ClassEncoder < handle
    
    properties

    end
    
    methods
        function dataField = adaptPacketsAndCRC(obj, inBits)

            
            MPEG_packet_len_bits = 1504;
            num_packets = length(inBits) / MPEG_packet_len_bits;
            
            mpeg_ts_packets = reshape(inBits, MPEG_packet_len_bits, num_packets)';

            DFL = num_packets * 1504;
            dataField = zeros(1, DFL);
            
            for p = 1:num_packets
                packet_data = mpeg_ts_packets(p, 9:end);
                crc8_bits = obj.calculate_dvbs2_crc8(packet_data);
                adapted_packet = [packet_data, crc8_bits];

                start_idx = (p-1)*1504 + 1;
                end_idx = p*1504;
                dataField(start_idx:end_idx) = adapted_packet;
            end
        end
    end
    
    methods (Access = private)
        function crc = calculate_dvbs2_crc8(obj, data_bits)
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
