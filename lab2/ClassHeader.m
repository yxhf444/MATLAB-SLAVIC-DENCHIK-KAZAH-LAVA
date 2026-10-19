classdef ClassHeader < handle
    
    methods
        function bbFrame = createBBFrame(obj, dataField, K_bch)
            MATYPE_1 = 240; 
            MATYPE_2 = 0;  
            UPL = 1504;    
            SYNC = 71;    
            SYNCD = 0;     
            DFL = length(dataField);
            
            m1_bits = obj.dec2binArr(MATYPE_1, 8);
            m2_bits = obj.dec2binArr(MATYPE_2, 8);
            upl_bits = obj.dec2binArr(UPL, 16);
            dfl_bits = obj.dec2binArr(DFL, 16);
            sync_bits = obj.dec2binArr(SYNC, 8);
            syncd_bits = obj.dec2binArr(SYNCD, 16);
            
            bbHeader = [m1_bits, m2_bits, upl_bits, dfl_bits, sync_bits, syncd_bits];
            
            padding_len = K_bch - 80 - DFL;
            padding = zeros(1, padding_len);
            
            bbFrame = [bbHeader, dataField, padding];
        end
    end
    
    methods (Access = private)
        function bits = dec2binArr(~, val, numBits)
            bits = zeros(1, numBits);
            for i = 1:numBits
                bits(i) = bitget(val, numBits - i + 1);
            end
        end
    end
end