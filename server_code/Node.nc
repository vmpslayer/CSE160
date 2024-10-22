/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/neighbor.h"
#include "includes/flood.h"
#include "includes/linkstate.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface Flooding;

   uses interface NeighborDiscovery;

   uses interface LinkStateRouting;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      call NeighborDiscovery.initNeighborDisco();
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      // dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         // Checking what kind of packet received
         switch(myMsg->protocol){
            // Ping protocol
            case 0:
               dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
               break;
            // Link State protocol
            case 2:
               call LinkStateRouting.receiveHandler(*myMsg);
               break;
            // Flood protocol
            case 6:
               // dbg(FLOODING_CHANNEL, "Node %i has received the flood packet.\n", TOS_NODE_ID);
               call Flooding.receiveHandler(*myMsg);
               break;
            case 7:
               call NeighborDiscovery.receiveHandler(*myMsg);
               break;
            case 8:
               call NeighborDiscovery.removeNeighbor(myMsg->src);
               break;
            // Flood return
            case 9:
               call Flooding.receiveHandler(*myMsg);
               break;
         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }
   
   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(uint16_t destination, uint8_t *payload){
      makePack(&sendPackage, TOS_NODE_ID, destination, 1, PROTOCOL_LINKSTATE, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      if(call LinkStateRouting.initLinkState() == SUCCESS){
         dbg(ROUTING_CHANNEL, "SUCCESS: Link State Routing Activated\n");
      }
      call LinkStateRouting.listLinkStateTable();
   }

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   event void CommandHandler.flood(uint16_t destination, uint8_t *payload){
      dbg(FLOODING_CHANNEL, "FLOOD EVENT \n");
      // This is the initialization of the packet
      // It is given a TTL 20 with the flooding protocol of 6
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, 6, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      if(call Flooding.initFlood(sendPackage) == SUCCESS){
         dbg(FLOODING_CHANNEL, "FLOOD SUCCESSFUL\n");
      }
      else{
         dbg(FLOODING_CHANNEL, "FLOOD FAIL\n");
      }
   }

   event void CommandHandler.Dijkstra(){
      call LinkStateRouting.Dijkstra();
   }
   
   event void NeighborDiscovery.updateListener(Neighbor* table, uint8_t length){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
