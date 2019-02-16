//
//  RDPLayer-Structs.h
//  Mesh Chat
//
//  Created by CoolStar on 2/15/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

#ifndef RDPLayer_Structs_h
#define RDPLayer_Structs_h

#define SYN_DATA_LEN 127
#define MTU 158

enum LINKLAYER_PROTOCOL_PACKET_TYPE {
    LINKLAYER_PROTOCOL_PACKET_TYPE_SYN,
    LINKLAYER_PROTOCOL_PACKET_TYPE_ACK
};

struct linklayer_protocol_syncompact {
    uint8_t packet_type;
    uuid_t uuid;
    uint32_t seq_num;
    uint8_t ttl;
    uint32_t start;
    uint8_t len; //if this is less than or equal to 127, this is the last packet
    uint32_t crc32;
} __attribute__((packed));

struct linklayer_protocol_syn {
    uint8_t packet_type;
    uuid_t uuid;
    uint32_t seq_num;
    uint8_t ttl;
    uint32_t start;
    uint8_t len; //if this is less than or equal to 127, this is the last packet
    uint32_t crc32;
    char data[SYN_DATA_LEN];
} __attribute__((packed));

struct linklayer_protocol_ack {
    uint8_t packet_type;
    uuid_t uuid;
    uint32_t ack_num;
    uint32_t len_received;
} __attribute__((packed));

#endif /* RDPLayer_Structs_h */
