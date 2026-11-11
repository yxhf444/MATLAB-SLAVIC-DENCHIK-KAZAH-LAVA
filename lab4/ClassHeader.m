classdef ClassHeader < handle
    methods
        function bbFrame = createBBFrame(obj, dataField, K_bch)
            MATYPE_1 = 240;
            MATYPE_2 = 0;
            UPL = 1504;
            SYNC = 71;
            SYNCD = 0;
            DFL = length(dataField);

            m1_bits    = obj.dec2binArr(MATYPE_1, 8);
            m2_bits    = obj.dec2binArr(MATYPE_2, 8);
            upl_bits   = obj.dec2binArr(UPL, 16);
            dfl_bits   = obj.dec2binArr(DFL, 16);
            sync_bits  = obj.dec2binArr(SYNC, 8);
            syncd_bits = obj.dec2binArr(SYNCD, 16);

            hdr72 = [m1_bits, m2_bits, upl_bits, dfl_bits, sync_bits, syncd_bits];

            crcUtil  = ClassCRC();
            crc8_hdr = crcUtil.dvbs2_crc8(hdr72);

            bbHeader = [hdr72, crc8_hdr];

            padding_len = K_bch - 80 - DFL;
            padding = zeros(1, padding_len);

            bbFrame = [bbHeader, dataField, padding];
        end

        function [bits, ok, nPackets, dataField] = parseBBFrame(obj, bbFrame)
            bits = [];
            ok = false;
            nPackets = 0;
            dataField = [];

            if length(bbFrame) < 80
                return
            end

            DFL   = obj.bin2decArr(bbFrame(33:48));
            SYNC  = obj.bin2decArr(bbFrame(49:56));

            if DFL == 0 || DFL > length(bbFrame) - 80
                return
            end

            pktDataLen  = 1496;
            pktTotalLen = 1504;

            if mod(DFL, pktTotalLen) ~= 0
                return
            end

            dataField = bbFrame(81 : 80 + DFL);

            nPackets = floor(DFL / pktTotalLen);
            bits = zeros(1, nPackets * (8 + pktDataLen));

            for p = 1:nPackets
                s = (p-1)*pktTotalLen + 1;
                pktData = dataField(s : s + pktDataLen - 1);
                bits((p-1)*(8+pktDataLen)+1 : p*(8+pktDataLen)) = ...
                    [obj.dec2binArr(SYNC, 8), pktData];
            end

            ok = true;
        end
    end

    methods (Access = private)
        function bits = dec2binArr(~, val, numBits)
            bits = zeros(1, numBits);
            for i = 1:numBits
                bits(i) = bitget(val, numBits - i + 1);
            end
        end

        function val = bin2decArr(~, bits)
            val = 0;
            for i = 1:length(bits)
                val = val * 2 + bits(i);
            end
        end
    end
end