classdef ClassReceiver < handle
    properties
        Beta = 0.35;
        Span = 10;
        Sps  = 4;
    end

    methods
        function [recoveredBits, isSuccess, info] = process(obj, plFrameIn, MODCOD, hasPilots, N_ldpc, K_bch, N0)
            recoveredBits = []; isSuccess = false; info = struct();
            info.numPackets = 0;
            info.crcStatus  = [];
            info.bchOk      = false;

            if nargin < 7 || isempty(N0) || N0 <= 0
                error('ClassReceiver: N0 must be positive and provided.');
            end

            rxSym = plFrameIn;

            hdr = ClassPLHeader();
            ref_plh = hdr.Step();

            best_shift = 1;
            best_metric = -inf;
            for shift = 1:6
                if shift + 89 > length(rxSym), break; end
                test_sym = rxSym(shift : shift+89);
                metric = abs(sum(test_sym .* conj(ref_plh)));
                if metric > best_metric
                    best_metric = metric;
                    best_shift = shift;
                end
            end
            rxSym = rxSym(best_shift : end);

            [modcodRx, typeRx] = hdr.decode(rxSym(1:90));
            info.modcodRx = modcodRx;
            info.typeRx   = typeRx;

            scr = ClassScrambler();
            xFec = scr.descramblePL(rxSym(91:end));

            plf = ClassPLFramer();
            xFec = plf.extractPilots(xFec, hasPilots);
            if length(xFec) > N_ldpc/2
                xFec = xFec(1 : N_ldpc/2);
            end

            dem = ClassDemapper();
            llr = dem.StepRx(xFec, 'QPSK', N0);

            il = ClassBitInterleaver();
            llr = il.StepRx(llr);

            H = dvbs2ldpc(1/2);
            if exist('ldpcDecoderConfig', 'file') || exist('ldpcDecoderConfig', 'builtin')
                cfg = ldpcDecoderConfig(H);
                [fecBits, iter] = ldpcDecode(llr(:), cfg, 50);
                fecBits = fecBits(:).';
            else
                ldpcDec = comm.LDPCDecoder(H, 'MaximumIterationCount', 50);
                fecBits = step(ldpcDec, llr(:)).';
                iter = 50;
            end
            info.ldpcIters = iter;

            enc = ClassEncoder();
            [bbFrameScr, bchOk] = enc.decodeBCH(fecBits, K_bch);
            info.bchOk = bchOk;

            bbFrame = scr.scrambleBB(bbFrameScr);

            h = ClassHeader();
            [recoveredBits, parseOk, nPkt, dataField] = h.parseBBFrame(bbFrame);

            if ~parseOk
                recoveredBits = [];
                isSuccess = false;
                return
            end

            info.numPackets = nPkt;

            crcUtil = ClassCRC();
            crcStatus = false(1, nPkt);
            pktDataLen = 1496;
            for p = 1:nPkt
                s = (p-1)*1504 + 1;
                d = dataField(s : s + pktDataLen - 1);
                c = dataField(s + pktDataLen : s + pktDataLen + 7);
                crcStatus(p) = isequal(crcUtil.dvbs2_crc8(d), c);
            end
            info.crcStatus = crcStatus;
            isSuccess = all(crcStatus) && bchOk;
        end
    end
end