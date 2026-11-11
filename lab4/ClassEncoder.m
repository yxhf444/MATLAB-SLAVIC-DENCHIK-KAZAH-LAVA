classdef ClassEncoder < handle
    methods
        function dataField = adaptPacketsAndCRC(obj, inBits)
            MPEG_packet_len_bits = 1504;
            num_packets = length(inBits) / MPEG_packet_len_bits;

            mpeg_ts_packets = reshape(inBits, MPEG_packet_len_bits, num_packets)';

            DFL = num_packets * 1504;
            dataField = zeros(1, DFL);

            crcUtil = ClassCRC();

            for p = 1:num_packets
                packet_data = mpeg_ts_packets(p, 9:end);
                crc8_bits = crcUtil.dvbs2_crc8(packet_data);
                adapted_packet = [packet_data, crc8_bits];

                start_idx = (p-1)*1504 + 1;
                end_idx   = p*1504;
                dataField(start_idx:end_idx) = adapted_packet;
            end
        end

        function [bbFrame, ok] = decodeBCH(obj, fecBits, K_bch)
            bbFrame = fecBits(1:K_bch);
            g_polys = [
                1 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 1; 1 0 0 0 0 0 0 0 1 0 1 1 1 0 0 1 1;
                1 0 0 0 0 1 1 1 1 1 0 1 1 1 1 0 1; 1 0 1 0 1 1 0 1 0 0 1 0 1 0 1 0 1;
                1 0 0 0 1 1 1 1 1 0 0 1 0 1 1 1 1; 1 1 1 1 1 0 1 1 1 1 0 1 1 0 1 0 1;
                1 1 0 1 0 1 1 1 1 0 1 1 0 0 1 0 1; 1 0 1 1 1 0 0 1 1 0 1 1 0 1 1 1 1;
                1 0 0 0 0 1 1 1 0 1 0 1 0 0 0 0 1; 1 0 1 1 1 0 1 0 1 1 0 1 0 1 1 1 1;
                1 0 0 1 1 1 0 1 0 0 0 1 0 1 1 0 1; 1 0 0 0 1 1 0 1 0 1 1 1 0 0 0 1 1];
            g_total = g_polys(1,:);
            for i = 2:12
                g_total = obj.gf2_conv(g_total, g_polys(i,:));
            end
            msg_padded = [double(bbFrame), zeros(1,192)];
            [~, parityCalc] = obj.gf2_div(msg_padded, g_total);
            parityRx = fecBits(K_bch+1 : K_bch+192);
            ok = isequal(double(parityCalc(:).'), double(parityRx(:).'));
        end
    end

    methods (Access = private)
        function c = gf2_conv(~, a, b)
            a = double(a); b = double(b);
            c = zeros(1, length(a)+length(b)-1);
            for i = 1:length(a)
                if a(i)
                    c(i:i+length(b)-1) = xor(c(i:i+length(b)-1), b);
                end
            end
        end

        function [q, r] = gf2_div(~, a, b)
            a = double(a); b = double(b);
            r = a;
            q = zeros(1, length(a)-length(b)+1);
            for i = 1:length(q)
                if r(i) == 1
                    q(i) = 1;
                    r(i:i+length(b)-1) = xor(r(i:i+length(b)-1), b);
                end
            end
            r = r(end-length(b)+2:end);
        end
    end
end