classdef ClassPLFramer < handle
    
    properties
        SOF_SEQ
        PLS_SCRAMBLING
    end
    
    methods
        function obj = ClassPLFramer()
            obj.SOF_SEQ = obj.hexToBin(18, 'D2E82', 26);
            obj.PLS_SCRAMBLING = [0 1 1 1 0 0 0 1 1 0 0 1 1 1 0 1 1 0 0 0 0 0 1 1 1 1 0 0 1 0 0 1 0 1 0 1 0 0 1 1 0 1 0 0 0 0 1 0 0 0 1 0 1 1 0 1 1 1 1 1 1 0 1 0];
        end

        function plHeaderSym = createPLHeader(obj, modcod)
            type_val = 1; 

            inputBits = [obj.dec2binArr(modcod, 5), obj.dec2binArr(type_val, 2)];
            
            plsCode = obj.encodePLS(inputBits);
            
            plsScrambled = xor(plsCode, obj.PLS_SCRAMBLING);

            plHeaderBits = [obj.SOF_SEQ, plsScrambled];
   
            plHeaderSym = (1/sqrt(2)) * (1 - 2 * plHeaderBits) .* exp(1j * (pi/4) * (0:89));
        end
        
        function [outSymbols, pilotFlags] = insertPilots(obj, xFecFrameSymbols)
            pilotBlock = (1/sqrt(2)) + 1j * (1/sqrt(2)) * ones(1, 36); 
            pilotBlock = pilotBlock / abs(pilotBlock(1)); 
            
            symbolsPerSlot = 90;
            slotsPerPilot = 16;
            symbolsPerBlock = symbolsPerSlot * slotsPerPilot; 
            
            numBlocks = floor(length(xFecFrameSymbols) / symbolsPerBlock);
            outSymbols = [];
            pilotFlags = [];
            
            for b = 1:numBlocks
                startIdx = (b-1) * symbolsPerBlock + 1;
                endIdx = b * symbolsPerBlock;
                
                outSymbols = [outSymbols, xFecFrameSymbols(startIdx:endIdx), pilotBlock];
                pilotFlags = [pilotFlags, zeros(1, symbolsPerBlock), ones(1, 36)];
            end
            
            remIdx = numBlocks * symbolsPerBlock + 1;
            if remIdx <= length(xFecFrameSymbols)
                outSymbols = [outSymbols, xFecFrameSymbols(remIdx:end)];
                pilotFlags = [pilotFlags, zeros(1, length(xFecFrameSymbols) - remIdx + 1)];
            end
        end
    end
    
    methods (Access = private)
        
        function bits = dec2binArr(~, val, numBits)
            bits = zeros(1, numBits);
            for i = 1:numBits
                bits(i) = bitget(val, numBits - i + 1);
            end
        end
        
                function outBits = encodePLS(obj, inBits)
            b1_6 = inBits(1:6);
            b7 = inBits(7);
            
            G = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1;
                 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1;
                 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1;
                 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1;
                 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
                 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]; 
            
            y = mod(b1_6 * G, 2);
            outBits = zeros(1, 64);
            
            for i = 1:32
                if b7 == 0
                    outBits(2*i - 1) = y(i);
                    outBits(2*i) = y(i);
                else
                    outBits(2*i - 1) = y(i);
                    outBits(2*i) = ~y(i);
                end
            end
        end
        
        function bin = hexToBin(~, hex1, hex2, len)
            decVal = hex2dec([dec2hex(hex1), hex2]);
            binStr = dec2bin(decVal, len);
            bin = binStr - '0';
        end
    end
end