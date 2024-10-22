#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
#include "../../includes/flood.h"

module FloodingP{
    provides interface Flooding;

    uses interface Timer<TMilli> as floodTimer;
    uses interface SimpleSend as Sender;
}
implementation{
    /*
    Flooding - Each node floods a packet to all its neighbor nodes. These
    packets continue to flood until they reach their final destination.
    Must work as pings and ping replies. Only use information accessible
    from the packet and its headers
    */
    uint16_t sequence = 0;
    floodCache cache[20];
    int cacheIndex = 0;
    bool received = FALSE;

    pack sendPackage;

    void makePack(pack *Package, uint16_t floodSource, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length); 
    bool alreadyCached(floodCache msg);

    // Revised by Andre Limos on 10/19/2024
    command error_t Flooding.initFlood(pack msg){
        int i;
        dbg(FLOODING_CHANNEL, "Node %i is opening the floodgates!\n", TOS_NODE_ID);        

        // Make packet with flooding header
        makePack(&sendPackage, msg.src, msg.src, msg.dest, msg.TTL, msg.protocol, sequence++, (uint8_t*)(msg.payload), PACKET_MAX_PAYLOAD_SIZE);

        // cache packet
        cache[cacheIndex].seq = msg.seq;
        cache[cacheIndex].floodSource = msg.src;
        cacheIndex++;
        if(cacheIndex == 20){
            cacheIndex = 0;
        }
        // broadcast packet
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        // start timer
        received = FALSE;
        if(msg.dest != AM_BROADCAST_ADDR){
            call floodTimer.startOneShot(5000);
        }
    
        return SUCCESS;
    }

    command error_t Flooding.receiveHandler(pack msg){
        floodPack flood_pack;
        floodCache flood_cache;

        memcpy(&flood_pack, &msg.payload, sizeof(floodPack));

        flood_cache.seq = msg.seq;
        flood_cache.floodSource = flood_pack.floodSource;

        if(msg.TTL <= 1){ // If time to live expires
            return FAIL; // Drop
        }

        dbg(FLOODING_CHANNEL, "Node %i has recieved a flooding packet from Node %i\n", TOS_NODE_ID, msg.src);

        if(alreadyCached(flood_cache) == TRUE){ // Yes this is a duplicate packet
            dbg(FLOODING_CHANNEL, "Node %i has already received this packet, dropping. . .\n", TOS_NODE_ID);
            return FAIL; // Drop it
        }
        else{ // If not, cache packet
            cache[cacheIndex].seq = msg.seq;
            cache[cacheIndex].floodSource = flood_pack.floodSource;
            cacheIndex++;
            if(cacheIndex == 20){
                cacheIndex = 0;
            }
        }

        msg.TTL--;

        if(TOS_NODE_ID == msg.dest){ // Send a reply
            if(msg.protocol == PROTOCOL_FLOODINGREPLY){
                dbg(FLOODING_CHANNEL, "Acknowledgement received!\n");
                received = TRUE;
                return SUCCESS;
            }
            makePack(&sendPackage, TOS_NODE_ID, TOS_NODE_ID, flood_pack.floodSource, 20, PROTOCOL_FLOODINGREPLY, msg.seq, (uint8_t*)(flood_pack.payload), PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }
        else{ // If not, broadcast again
            makePack(&sendPackage, flood_pack.floodSource, TOS_NODE_ID, msg.dest, msg.TTL, msg.protocol, msg.seq, (uint8_t*)(flood_pack.payload), PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }
    }

    bool alreadyCached(floodCache msg){
        int i;
        for(i = 0; i < 20; i++){
            if(cache[i].seq == msg.seq && cache[i].floodSource == msg.floodSource){
                return TRUE;
            }
        }
        return FALSE;
    }

    event void floodTimer.fired(){
        // dbg(FLOODING_CHANNEL, "Firing my lazah!\n");
        if(received){
            dbg(FLOODING_CHANNEL, "Flood complete\n");
        }
        else{
            dbg(FLOODING_CHANNEL, "No acknowledgement, retrying flood. . .\n");
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            call floodTimer.startOneShot(5000);
        }
    }

    // New makePack that includes flooding header
    void makePack(pack *Package, uint16_t floodSource, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        int i;
        floodPack header;
        memcpy(&header.payload, payload, FLOODING_MAX_PAYLOAD_SIZE);
        header.floodSource = floodSource;
    
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, &header, length);
        // dbg(FLOODING_CHANNEL, "Flooding header successfully added!\n"); Debugging message found bug
   }
}