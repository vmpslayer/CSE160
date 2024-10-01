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

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface Flooding;

   uses interface NeighborDiscovery;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      call NeighborDiscovery.findNeighbor();
      call NeighborDiscovery.checkNeighbor();
      //call lineApp.start;
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
               return msg;
               break;
<<<<<<< HEAD
            case PROTOCOL_FLOODING:
               return msg;
               break;
            case PROTOCOL_NEIGHBOR:
=======
            // Flood protocol
            case 6:
               // dbg(FLOODING_CHANNEL, "Flood Packet Received.\n");
               dbg(FLOODING_CHANNEL, "Node %i has received the flood packet.\n", TOS_NODE_ID);
               // call Flooding.receiveCheck();
               // First direction destination
               if(myMsg->dest == TOS_NODE_ID){
                  dbg(FLOODING_CHANNEL, "The packet has reached its destination!\n");
                  if(myMsg->seq == 0){
                     dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
                     /*
                     myMsg->dest = myMsg->src;
                     myMsg->src = TOS_NODE_ID;
                     myMsg->seq = 1;
                     myMsg->TTL = 5;
                     */
                  
                     makePack(&sendPackage, myMsg->dest, myMsg->src, 5, myMsg->protocol, 1, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE); // Why does this work?
                     call Flooding.flood(sendPackage);
                     // call Flooding.receiveCheck();
                  }
                  else if(myMsg->seq == 1){
                     dbg(FLOODING_CHANNEL, "The flooding return packet has been received.\nStopping flooding...\n");
                     call Flooding.reset(); // Turns flooding to FALSE to stop the rest of the nodes from sending
                  }
               }
               // If the packet arrives and its not the desired destination, flood again.
               else{
                  
                  call Flooding.flood(*myMsg);
               }

               return msg;
               break;
            case 7:
               dbg(NEIGHBOR_CHANNEL, "Discovery Packet Received.\n");
>>>>>>> 30f99f7ead86e798141870a545dc2accf4601cdf
               // Upon reception of a neighbor discovery packet, receiving node must reply back
               if(myMsg->dest == AM_BROADCAST_ADDR){
                  makePack(&sendPackage, TOS_NODE_ID, myMsg->src, 1, PROTOCOL_NEIGHBOR, 0, "Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
                  call NeighborDiscovery.addNeighbor(myMsg->src);
                  call Sender.send(sendPackage, myMsg->src);
                  // if(call Sender.send(sendPackage, myMsg->src) == SUCCESS){
                  //    dbg(NEIGHBOR_CHANNEL, "Reply sent from Node  %d to Node %d\n", myMsg->src, myMsg->dest);
                  // }
                  // else{
                  //    dbg(NEIGHBOR_CHANNEL, "FAILED to reply to Node", myMsg->dest);
                  // }
               }
               else if(myMsg->dest == TOS_NODE_ID){
                  call NeighborDiscovery.addNeighbor(myMsg->src);
               }
               return msg;
               break;

            case 8:
               call NeighborDiscovery.removeNeighbor(myMsg->src);
               return msg;
               break;
         }
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

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   event void CommandHandler.flood(uint16_t destination, uint8_t *payload){
      dbg(FLOODING_CHANNEL, "FLOOD EVENT \n");
      // This is the initialization of the packet
      // It is given a TTL 5 with the flooding protocol of 6
      makePack(&sendPackage, TOS_NODE_ID, destination, 5, 6, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.flood(sendPackage);
   }

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
