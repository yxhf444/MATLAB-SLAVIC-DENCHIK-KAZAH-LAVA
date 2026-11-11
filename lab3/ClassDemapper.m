classdef ClassDemapper < handle
    methods
        function llr = StepRx(obj, symbols, modType, N0)
            switch modType
                case 'QPSK'
                    llrI = 10 * real(symbols); 
                    llrQ = 10 * imag(symbols);
                    
                    llr = zeros(1, 2*numel(symbols));
                    llr(1:2:end) = llrI;
                    llr(2:2:end) = llrQ;
            end
        end
    end
end