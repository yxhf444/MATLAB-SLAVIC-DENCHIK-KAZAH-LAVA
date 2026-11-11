clear; clc; close all;

R_ldpc   = 1/2;
N_ldpc   = 64800;
K_bch    = 32208;
N_bch    = K_bch + 192;
MODCOD   = 4;
MOD_TYPE = 'QPSK';
HAS_PILOTS = true;
beta = 0.35;
span = 10;
sps  = 4;

num_pkts_in_frame = floor((K_bch - 80) / 1504);

rng(1);

src = ClassSource();
mpegBits = src.generateData();

enc = ClassEncoder();
dataField = enc.adaptPacketsAndCRC(mpegBits);

hdr = ClassHeader();
bbFrame = hdr.createBBFrame(dataField, K_bch);

scr = ClassScrambler();
scrambledFrame = scr.scrambleBB(bbFrame);

g_polys = [ ...
    1 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 1; 1 0 0 0 0 0 0 0 1 0 1 1 1 0 0 1 1;
    1 0 0 0 0 1 1 1 1 1 0 1 1 1 1 0 1; 1 0 1 0 1 1 0 1 0 0 1 0 1 0 1 0 1;
    1 0 0 0 1 1 1 1 1 0 0 1 0 1 1 1 1; 1 1 1 1 1 0 1 1 1 1 0 1 1 0 1 0 1;
    1 1 0 1 0 1 1 1 1 0 1 1 0 0 1 0 1; 1 0 1 1 1 0 0 1 1 0 1 1 0 1 1 1 1;
    1 0 0 0 0 1 1 1 0 1 0 1 0 0 0 0 1; 1 0 1 1 1 0 1 0 1 1 0 1 0 1 1 1 1;
    1 0 0 1 1 1 0 1 0 0 0 1 0 1 1 0 1; 1 0 0 0 1 1 0 1 0 1 1 1 0 0 0 1 1];

g_total = g_polys(1, :);
for i = 2:12
    g_total = gf2_conv_local(g_total, g_polys(i, :));
end

msg_padded = [double(scrambledFrame(:)).', zeros(1, 192)];
[~, parity] = gf2_div_local(msg_padded, g_total);

bbFrameBch = [double(scrambledFrame(:)).', double(parity(:).')];
if length(bbFrameBch) < N_bch
    bbFrameBch = [bbFrameBch, zeros(1, N_bch - length(bbFrameBch))];
else
    bbFrameBch = bbFrameBch(1:N_bch);
end

H = dvbs2ldpc(R_ldpc);
if exist('ldpcEncoderConfig', 'file') || exist('ldpcEncoderConfig', 'builtin')
    fecFrame = ldpcEncode(bbFrameBch(:), ldpcEncoderConfig(H)).';
else
    fecFrame = step(comm.LDPCEncoder(H), bbFrameBch(:)).';
end

il = ClassBitInterleaver();
interleavedBits = il.StepTx(fecFrame);

bitsI = interleavedBits(1:2:end);
bitsQ = interleavedBits(2:2:end);
symI  = (1 - 2*bitsI) / sqrt(2);
symQ  = (1 - 2*bitsQ) / sqrt(2);
xFecFrameSymbols = symI + 1j * symQ;

plh = ClassPLHeader();
plHeaderSym = plh.Step();

plf = ClassPLFramer();
[xFecPilots, pilotFlags] = plf.insertPilots(xFecFrameSymbols, HAS_PILOTS);
scrambledXFec = scr.scramblePL(xFecPilots);
plFrame = [plHeaderSym, scrambledXFec];

Es = mean(abs(plFrame).^2);

%% ===== ПУНКТ 1: без шума =====
N0_clean = Es / 1e4;
rx = ClassReceiver();
[recBits, isSuccess, info] = rx.process(plFrame, MODCOD, HAS_PILOTS, N_ldpc, K_bch, N0_clean);
fprintf('\n===== ПУНКТ 1: без шума =====\n');
fprintf('Пакетов: %d\n', info.numPackets);
fprintf('BCH OK: %d\n', info.bchOk);
fprintf('CRC-8 OK: %d / %d\n', sum(info.crcStatus), numel(info.crcStatus));
fprintf('Данные совпадают с исходными: %d\n', isequal(recBits, mpegBits));

%% ===== ПУНКТ 2: собственный приёмник при Es/N0 = 10 dB =====
EsN0dB = 10;
N0 = Es / (10^(EsN0dB/10));

noiseSym = sqrt(N0/2) * (randn(size(plFrame)) + 1j*randn(size(plFrame)));
rxFrameSym = plFrame + noiseSym;

[myBits, mySuccess, myInfo] = rx.process(rxFrameSym, MODCOD, HAS_PILOTS, N_ldpc, K_bch, N0);

fprintf('\n===== ПУНКТ 2: Es/N0 = %.1f dB =====\n', EsN0dB);
fprintf('Собственный приёмник: CRC OK %d / %d, данные == исходные: %d\n', ...
    sum(myInfo.crcStatus), numel(myInfo.crcStatus), isequal(myBits, mpegBits));

%% ===== ПУНКТ 3: PER(Es/N0) =====
EsN0_dB_vec = 0.7:0.15:1.3;
PER = zeros(size(EsN0_dB_vec));
nFrames = 30;

tic;
for k = 1:numel(EsN0_dB_vec)
    N0k = Es / (10^(EsN0_dB_vec(k)/10));
    nErr = 0;
    totPkt = 0;
    for t = 1:nFrames
        n = sqrt(N0k/2) * (randn(size(plFrame)) + 1j*randn(size(plFrame)));
        rxF = plFrame + n;
        [~, ~, infk] = rx.process(rxF, MODCOD, HAS_PILOTS, N_ldpc, K_bch, N0k);
        if ~isempty(infk.crcStatus)
            nErr = nErr + sum(~infk.crcStatus);
            totPkt = totPkt + numel(infk.crcStatus);
        else
            nErr   = nErr   + num_pkts_in_frame;
            totPkt = totPkt + num_pkts_in_frame;
        end
    end
    PER(k) = nErr / max(totPkt,1);
    fprintf('Es/N0 = %.2f dB  -> PER = %.3e\n', EsN0_dB_vec(k), PER(k));
end
fprintf('ПУНКТ 3 занял %.1f с\n', toc);

ref_EsN0 = [0.6 0.8 0.9 0.95 1.0 1.05 1.1];
ref_PER  = [1e-1 1e-2 1e-3 1e-4 1e-5 1e-6 1e-7];

figure('Name','PER(Es/N0): QPSK R=1/2');
semilogy(EsN0_dB_vec, max(PER,1e-7), 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
semilogy(ref_EsN0, ref_PER, 'r--', 'LineWidth', 2);
grid on; box on;
xlabel('Es/N0, dB'); ylabel('PER');
title('PER(Es/N0): QPSK, R=1/2, normal FECFRAME, pilots on');
legend('Собственный приёмник','DVB-S2 reference','Location','southwest');
ylim([1e-7 1e-1]); xlim([0.4 1.6]);

%% ===== Доп. графики =====
rrc = rcosdesign(beta, span, sps, 'sqrt');
waveformClean = upfirdn(plFrame(:), rrc, sps, 1);

figure('Name','PLFRAME: constellation', 'Position',[100 100 800 800]);
plot(real(plFrame), imag(plFrame), 'b.', 'MarkerSize', 10, ...
    'Color', [0.3 0.5 1 0.35]); hold on;
plot(real(plHeaderSym), imag(plHeaderSym), 'ro', ...
    'MarkerSize', 9, 'LineWidth', 1.5);
plot(real(scrambledXFec(pilotFlags==1)), ...
     imag(scrambledXFec(pilotFlags==1)), 'g+', ...
    'MarkerSize', 11, 'LineWidth', 1.8);
hold off; grid on; box on; pbaspect([1 1 1]);
xlim([-1.25 1.25]); ylim([-1.25 1.25]);
xlabel('I'); ylabel('Q');
title('PLFRAME constellation (no noise)');
legend({'XFECFRAME data','PLHEADER (\pi/2-BPSK)','Pilots'}, ...
    'Location','southeastoutside');

figure('Name','RRC output spectrum');
Nfft = 4096;
S = fftshift(fft(waveformClean, Nfft));
f = (-Nfft/2 : Nfft/2-1) * (sps / Nfft);
plot(f, 10*log10(abs(S).^2 / max(abs(S).^2) + eps));
grid on; xlim([-2 2]); ylim([-80 5]);
xlabel('f / (1/T)'); ylabel('Normalized PSD, dB');
title(sprintf('PLFRAME spectrum after RRC, beta = %.2f', beta));

function c = gf2_conv_local(a, b)
    a = double(a); b = double(b);
    c = zeros(1, length(a)+length(b)-1);
    for i = 1:length(a)
        if a(i)
            c(i:i+length(b)-1) = xor(c(i:i+length(b)-1), b);
        end
    end
end

function [q, r] = gf2_div_local(a, b)
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
