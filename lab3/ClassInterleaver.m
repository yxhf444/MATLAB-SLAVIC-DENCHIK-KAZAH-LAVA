classdef ClassInterleaver < handle
    
    methods
        function outBits = interleave(obj, inBits, modType, nLdpc)
            
            if strcmp(modType, 'QPSK')
                outBits = inBits;
                return;
            end
            
            switch modType
                case '8PSK'
                    if nLdpc == 64800
                        rows = 21600; cols = 3;
                    else
                        rows = 5400; cols = 3;
                    end
                case '16APSK'
                    if nLdpc == 64800
                        rows = 16200; cols = 4;
                    else
                        rows = 4050; cols = 4;
                    end
                case '32APSK'
                    if nLdpc == 64800
                        rows = 12960; cols = 5;
                    else
                        rows = 3240; cols = 5;
                    end
            end

            interleaverMatrix = reshape(inBits, rows, cols);

            outBits = reshape(interleaverMatrix', 1, []);
        end
    end
end