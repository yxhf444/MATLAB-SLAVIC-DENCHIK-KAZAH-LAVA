classdef ClassSource < handle
    
    properties

    end
    
    methods
        function outBits = generateData(obj)
            K_bch = 32208;
            Max_DFL = K_bch - 80;
            
            MPEG_packet_len_bits = 1504;
            Data_field_len_bits = 1496;

            num_packets = floor(Max_DFL / MPEG_packet_len_bits);
            
            sync_byte = [0 1 0 0 0 1 1 1]; 
            
            mpeg_ts_packets = zeros(num_packets, MPEG_packet_len_bits);
            
            for p = 1:num_packets
                mpeg_ts_packets(p, 1:8) = sync_byte;
                mpeg_ts_packets(p, 9:end) = randi([0 1], 1, Data_field_len_bits);
            end

            outBits = mpeg_ts_packets'; 
            outBits = outBits(:)';
        end
    end
end
