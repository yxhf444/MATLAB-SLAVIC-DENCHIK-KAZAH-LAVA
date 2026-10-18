clear; clc;

R_ldpc = 1/2;
N_ldpc = 64800;

K_bch = 32208;


MPEG_packet_len_bytes = 188;
MPEG_packet_len_bits = MPEG_packet_len_bytes * 8;
Data_field_len_bits = 1496;


Max_DFL = K_bch - 80; 
num_packets = floor(Max_DFL / 1504);
DFL = num_packets * 1504;

sync_byte = [0 1 0 0 0 1 1 1]; 

%mpeg-ts
mpeg_ts_packets = zeros(num_packets, MPEG_packet_len_bits);

for p = 1:num_packets
    mpeg_ts_packets(p, 1:8) = sync_byte;
    mpeg_ts_packets(p, 9:end) = randi([0 1], 1, Data_field_len_bits);
end


%crc-8
data_field = zeros(1, DFL);

for p = 1:num_packets
    packet_data = mpeg_ts_packets(p, 9:end);
    crc8_bits = calculate_dvbs2_crc8(packet_data);
    adapted_packet = [packet_data, crc8_bits];

    start_idx = (p-1)*1504 + 1;
    end_idx = p*1504;
    data_field(start_idx:end_idx) = adapted_packet;
end


function crc = calculate_dvbs2_crc8(data_bits)
    reg = zeros(1, 8);
    
    for k = 1:length(data_bits)
        u_k = data_bits(k);
        f = xor(u_k, reg(8));
       
        r1_new = f;
        r2_new = reg(1);
        r3_new = xor(reg(2), f);
        r4_new = reg(3);
        r5_new = xor(reg(4), f);
        r6_new = reg(5);
        r7_new = xor(reg(6), f);
        r8_new = xor(reg(7), f);
        
        reg = [r1_new, r2_new, r3_new, r4_new, r5_new, r6_new, r7_new, r8_new];
    end
    
    crc = reg;
end
