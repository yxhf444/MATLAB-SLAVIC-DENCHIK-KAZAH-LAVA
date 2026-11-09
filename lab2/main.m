clear; clc; close all;

R_ldpc = 1/2;
N_ldpc = 64800;
K_bch  = 32208;
N_bch  = K_bch + 192;

MODCOD     = 4;
MOD_TYPE   = 'QPSK';
HAS_PILOTS = true;
TYPE_VAL   = 1;

MPEG_packet_len_bits = 188 * 8;
Data_field_len_bits  = 1496;

Max_DFL     = K_bch - 80;
num_packets = floor(Max_DFL / MPEG_packet_len_bits);
DFL         = num_packets * MPEG_packet_len_bits;

fprintf('MPEG-TS packets: %d, DFL = %d bits\n', num_packets, DFL);

src = ClassSource();
mpegBits = src.generateData();
fprintf('Source bits: %d\n', length(mpegBits));

enc = ClassEncoder();
dataField = enc.adaptPacketsAndCRC(mpegBits);
fprintf('dataField after CRC: %d (expected %d)\n', length(dataField), DFL);

hdr = ClassHeader();
bbFrame = hdr.createBBFrame(dataField, K_bch);
fprintf('BBFRAME length: %d (expected %d)\n', length(bbFrame), K_bch);

scr = ClassScrambler();
scrambledFrame = scr.scrambleBB(bbFrame);
fprintf('BB scrambling done, length: %d\n', length(scrambledFrame));

g_polys = [
    1 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 1;
    1 0 0 0 0 0 0 0 1 0 1 1 1 0 0 1 1;
    1 0 0 0 0 1 1 1 1 1 0 1 1 1 1 0 1;
    1 0 1 0 1 1 0 1 0 0 1 0 1 0 1 0 1;
    1 0 0 0 1 1 1 1 1 0 0 1 0 1 1 1 1;
    1 1 1 1 1 0 1 1 1 1 0 1 1 0 1 0 1;
    1 1 0 1 0 1 1 1 1 0 1 1 0 0 1 0 1;
    1 0 1 1 1 0 0 1 1 0 1 1 0 1 1 1 1;
    1 0 0 0 0 1 1 1 0 1 0 1 0 0 0 0 1;
    1 0 1 1 1 0 1 0 1 1 0 1 0 1 1 1 1;
    1 0 0 1 1 1 0 1 0 0 0 1 0 1 1 0 1;
    1 0 0 0 1 1 0 1 0 1 1 1 0 0 0 1 1;
];

g_total = g_polys(1, :);
for i = 2:12
    g_total = gf2_conv(g_total, g_polys(i, :));
end
fprintf('DEBUG: g_total length = %d (expected 193)\n', length(g_total));

msg_padded = [double(scrambledFrame(:)).', zeros(1, 192)];
[~, parity] = gf2_div(msg_padded, g_total);
fprintf('DEBUG: parity length = %d (expected 192)\n', length(parity));

bbFrameBch = [double(scrambledFrame(:)).', double(parity(:).')];

if length(bbFrameBch) < N_bch
    bbFrameBch = [bbFrameBch, zeros(1, N_bch - length(bbFrameBch))];
elseif length(bbFrameBch) > N_bch
    bbFrameBch = bbFrameBch(1:N_bch);
end
fprintf('DEBUG: bbFrameBch length = %d (expected %d)\n', length(bbFrameBch), N_bch);
assert(length(bbFrameBch) == N_bch, sprintf('BCH: wrong length (%d, expected %d)', length(bbFrameBch), N_bch));
fprintf('After BCH: %d bits (expected %d)\n', length(bbFrameBch), N_bch);

H = dvbs2ldpc(R_ldpc);
if exist('ldpcEncoderConfig', 'file') || exist('ldpcEncoderConfig', 'builtin')
    cfg = ldpcEncoderConfig(H);
    fecFrame = ldpcEncode(bbFrameBch(:), cfg).';
else
    ldpcEnc = comm.LDPCEncoder(H);
    fecFrame = step(ldpcEnc, bbFrameBch(:)).';
end
assert(length(fecFrame) == N_ldpc, 'LDPC: wrong length');
fprintf('FECFRAME (real) length: %d (expected %d)\n', length(fecFrame), N_ldpc);

il = ClassBitInterleaver();
interleavedBits = il.StepTx(fecFrame);
fprintf('Interleaving (QPSK transparent), length: %d\n', length(interleavedBits));

bitsI = interleavedBits(1:2:end);
bitsQ = interleavedBits(2:2:end);
symI  = (1 - 2*bitsI) / sqrt(2);
symQ  = (1 - 2*bitsQ) / sqrt(2);
xFecFrameSymbols = symI + 1j * symQ;

fprintf('QPSK symbols in XFECFRAME: %d\n', length(xFecFrameSymbols));
fprintf('Slots of 90 symbols: %d\n', floor(length(xFecFrameSymbols)/90));

plh = ClassPLHeader();
plHeaderSym = plh.Step();
fprintf('PLHEADER length: %d symbols\n', length(plHeaderSym));

plf = ClassPLFramer();
[xFecPilots, pilotFlags, numSlots] = plf.insertPilots(xFecFrameSymbols, HAS_PILOTS);
fprintf('XFECFRAME with pilots: %d symbols (pilots: %d)\n', ...
        length(xFecPilots), sum(pilotFlags));

scrambledXFec = scr.scramblePL(xFecPilots, 0, 0);
fprintf('PL scrambling done, length: %d\n', length(scrambledXFec));

plFrame = [plHeaderSym, scrambledXFec];
fprintf('PLFRAME total: %d symbols\n', length(plFrame));

beta = 0.35;
span = 10;
sps  = 4;
rrc  = rcosdesign(beta, span, sps, 'sqrt');
waveform = upfirdn(plFrame, rrc, sps, 1);
fprintf('RRC output: %d samples\n', length(waveform));

figure('Name', 'PLFRAME: constellation', 'Position', [100 100 900 900]);
hData  = plot(real(plFrame), imag(plFrame), 'b.', ...
    'MarkerSize', 10, 'Color', [0.3 0.5 1 0.35]);
hold on;
hHdr   = plot(real(plHeaderSym), imag(plHeaderSym), 'o', ...
    'MarkerSize', 9, 'LineWidth', 1.5, ...
    'MarkerEdgeColor', [0.85 0 0], 'MarkerFaceColor', 'none');
hPilot = plot(real(scrambledXFec(pilotFlags==1)), ...
              imag(scrambledXFec(pilotFlags==1)), '+', ...
    'MarkerSize', 11, 'LineWidth', 1.8, 'Color', [0 0.7 0]);
hold off;
grid on; box on; pbaspect([1 1 1]);
xlim([-1.25 1.25]); ylim([-1.25 1.25]);
set(gca, 'XTick', [-1 -0.7071 0 0.7071 1], ...
         'XTickLabel', {'-1','-0.707','0','0.707','1'}, ...
         'YTick', [-1 -0.7071 0 0.7071 1], ...
         'YTickLabel', {'-1','-0.707','0','0.707','1'});
xlabel('I'); ylabel('Q');
title('PLFRAME constellation (no noise)');
legend([hData, hHdr, hPilot], ...
    {'XFECFRAME data', 'PLHEADER (pi/2-BPSK)', 'Pilots'}, ...
    'Location', 'southeastoutside');
text( 0.707,  0.707, ' 00', 'FontSize', 10, 'Color', 'k');
text( 0.707, -0.707, ' 01', 'FontSize', 10, 'Color', 'k');
text(-0.707, -0.707, ' 11', 'FontSize', 10, 'Color', 'k');
text(-0.707,  0.707, ' 10', 'FontSize', 10, 'Color', 'k');

figure('Name', 'PLFRAME: zoom on vertex 00', 'Position', [150 150 700 700]);
tol = 0.2;
maskData  = abs(real(plFrame) - 0.707) < tol & abs(imag(plFrame) - 0.707) < tol;
maskHdr   = abs(real(plHeaderSym) - 0.707) < tol & abs(imag(plHeaderSym) - 0.707) < tol;
maskPilot = pilotFlags == 1;
tmpPilot  = scrambledXFec(maskPilot);
maskPilot = abs(real(tmpPilot) - 0.707) < tol & abs(imag(tmpPilot) - 0.707) < tol;
jit = 0.015;
plot(real(plFrame(maskData)) + jit*randn(sum(maskData),1), ...
     imag(plFrame(maskData)) + jit*randn(sum(maskData),1), ...
     'b.', 'MarkerSize', 12);
hold on;
plot(real(plHeaderSym(maskHdr)) + jit*randn(sum(maskHdr),1), ...
     imag(plHeaderSym(maskHdr)) + jit*randn(sum(maskHdr),1), ...
     'ro', 'MarkerSize', 10, 'LineWidth', 1.5);
tmpP = tmpPilot(maskPilot);
plot(real(tmpP) + jit*randn(sum(maskPilot),1), ...
     imag(tmpP) + jit*randn(sum(maskPilot),1), ...
     'g+', 'MarkerSize', 12, 'LineWidth', 1.8);
hold off;
grid on; box on; pbaspect([1 1 1]);
xlim([0.707-3*tol, 0.707+3*tol]);
ylim([0.707-3*tol, 0.707+3*tol]);
xlabel('I'); ylabel('Q');
title(sprintf('Zoom vertex 00: %d data, %d PLHEADER, %d pilots', ...
    sum(maskData), sum(maskHdr), sum(maskPilot)));
legend({'Data', 'PLHEADER', 'Pilots'}, 'Location', 'best');

figure('Name', 'RRC output spectrum');
Nfft = 4096;
S = fftshift(fft(waveform, Nfft));
f = (-Nfft/2 : Nfft/2-1) * (sps / Nfft);
plot(f, 10*log10(abs(S).^2 / max(abs(S).^2) + eps));
grid on; xlim([-2 2]); ylim([-80 5]);
xlabel('f / (1/T)'); ylabel('Normalized PSD, dB');
title(sprintf('PLFRAME spectrum after RRC, beta = %.2f', beta));

function c = gf2_conv(a, b)
    a = double(a); b = double(b);
    c = zeros(1, length(a)+length(b)-1);
    for i = 1:length(a)
        if a(i)
            c(i:i+length(b)-1) = xor(c(i:i+length(b)-1), b);
        end
    end
end

function [q, r] = gf2_div(a, b)
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
